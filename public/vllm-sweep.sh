#!/usr/bin/env bash
# =============================================================================
# vllm-sweep.sh — autonomous vLLM coding-model tuning sweep (single OR dual GPU)
# -----------------------------------------------------------------------------
# Finds the optimal single-user *coding* serving config for vLLM models on orion
# (RTX 3090 x2) by launching the vllm/vllm-openai container across a coordinate-
# descent parameter sweep, validating + benchmarking each config, probing each
# model's maximum usable context, capturing logs/metrics, and producing a ranked
# RESULTS.md.
#
# Single-card (default): --tp 1 --gpu 1. Dual-card (TP=2, 48 GiB): --tp 2
# --gpus-list 0,1 — uses both cards, autodetects NVLink (adds
# --disable-custom-all-reduce + NCCL_P2P_DISABLE=1 when absent), and free-checks
# every target GPU before starting.
#
# REPORT-ONLY: never touches the Portainer stack. Runs the sweep only if every
# target GPU is already free (or, with --wait-for-free, once they become free).
#
# Objective: single-user coding latency — low TTFT, high decode tok/s at
# concurrency 1 — and the largest usable context per model (S6 ceiling probe).
#
# Swept params: --gpu-memory-utilization, --language-model-only (mm models),
#               --max-model-len, --max-num-seqs, --max-num-batched-tokens.
# Stages: S0 anchor, S1 batched, S2 seqs, S3 len, S4 util, S5 lm-only (mm),
#         S6 context-ceiling climb. Tier `quick` runs S0 + 2 light points + S6.
#
# Requires on the host: docker (nvidia runtime), nvidia-smi, curl, jq, awk.
# `vllm bench serve` is run *inside* the launched container.
#
# Usage:
#   ./vllm-sweep.sh --dry-run                       # print the full schedule, launch nothing
#   ./vllm-sweep.sh --smoke                         # one short config end-to-end
#   ./vllm-sweep.sh --tp 2 --gpus-list 0,1          # full dual-GPU sweep (default roster)
#   ./vllm-sweep.sh --tp 2 --gpus-list 0,1 --prepull  # pre-download weights, then exit
#   ./vllm-sweep.sh --models "qwen3-coder-30b"      # subset of models
#   ./vllm-sweep.sh --wait-for-free 120             # poll up to 120 min for GPUs to free
#   ./vllm-sweep.sh --max-hours 999                 # effectively no wall-clock cap
#   ./vllm-sweep.sh --config 0.95:32768:1:8192:off  # run explicit config(s) only
#
# --config UTIL:LEN:SEQS:BATCHED:LMONLY (repeatable) bypasses the coordinate-
# descent sweep and runs only the given tuple(s) through the same
# launch->validate->benchmark->teardown path, for every model in --models.
# LMONLY is on|off|na. Results land in the same run dir and are aggregated into
# RESULTS.md, so it composes with --run-dir to extend an existing run.
#
# Env (or via .env next to this script):
#   HUGGING_FACE_HUB_TOKEN   HF token for gated/large model downloads
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Defaults / constants
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GPU="${GPU:-1}"                          # default GPU index (single-card path)
GPUS_LIST="${GPUS_LIST:-}"               # comma list e.g. "0,1"; empty => use $GPU
TP="${TP:-1}"                            # tensor-parallel-size (1 single, 2 dual)
HOST_PORT="${HOST_PORT:-8009}"           # host port -> container :8000
CTR_NAME="${CTR_NAME:-vllm-bench}"       # container name (single, reused)
IMAGE="${IMAGE:-vllm/vllm-openai:latest}"
NETWORK="${NETWORK:-ai-inference}"
FREE_THRESHOLD_MIB="${FREE_THRESHOLD_MIB:-1024}"   # GPU counts as free below this
READY_TIMEOUT="${READY_TIMEOUT:-300}"    # max seconds to wait for server ready
FREE_TIMEOUT="${FREE_TIMEOUT:-180}"      # max seconds to wait for VRAM to drain
MAX_HOURS="${MAX_HOURS:-9}"              # overall wall-clock budget
PROMPTS_FILE="${PROMPTS_FILE:-$SCRIPT_DIR/prompts/coding_prompts.json}"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="${RUN_DIR:-/mnt/nas-01/vllm-sweep/$RUN_TS}"
TTFT_BUDGET_MS="${TTFT_BUDGET_MS:-2500}" # max acceptable median TTFT for "winner"

DRY_RUN=0
SMOKE=0
PREPULL=0               # 1 = only pre-download model weights, then exit
WAIT_FOR_FREE=0          # minutes; 0 = don't wait
MODELS_ARG=""
declare -a EXPLICIT_CONFIGS=()   # --config UTIL:LEN:SEQS:BATCHED:LMONLY (repeatable)

START_EPOCH="$(date +%s)"

# GPU id list (populated after arg parsing): the physical cards to use/free-check.
declare -a GPU_IDS=()
NVLINK_PRESENT=""        # "1"/"0", set by detect_nvlink (dual only)
declare -a TOPO_ENV=()   # extra -e flags forced by topology (e.g. NCCL_P2P_DISABLE)
TOPO_ARGS=""             # extra engine args forced by topology (e.g. --disable-custom-all-reduce)

# -----------------------------------------------------------------------------
# Model registry
#   Base:   key | repo | served-name | is_multimodal(1/0) | extra fixed args
#   Options (per-model overrides, all optional, sane defaults):
#     M_ENV[key]     extra `-e VAR=val` docker env flags (space-separated)
#     M_TP[key]      tensor-parallel-size override (default: global $TP)
#     M_IMAGE[key]   container image override       (default: global $IMAGE)
#     M_NOTHINK[key] 1 => send enable_thinking=false in validation (reasoning models)
#     M_CEIL[key]    native context cap for the S6 ladder (default 262144)
#     M_TIER[key]    full|quick  (full = S0-S6 coord descent; quick = S0 + S6)
#     M_AB[key]      A/B partner key (for the quant-comparison report section)
# -----------------------------------------------------------------------------
declare -A M_REPO M_SERVED M_MM M_EXTRA M_ENV M_TP M_IMAGE M_NOTHINK M_CEIL M_TIER M_AB
register_model() { M_REPO[$1]="$2"; M_SERVED[$1]="$3"; M_MM[$1]="$4"; M_EXTRA[$1]="$5"; }
# model_opt <assoc-name> <key> <default> -> echoes the override or the default
model_opt() { local -n _a="$1"; local v="${_a[$2]:-}"; [[ -n "$v" ]] && echo "$v" || echo "$3"; }

# GLM FlashInfer-MoE env (from the dual-3090 GLM-4.7-Flash reference gist).
GLM_ENV="VLLM_USE_FLASHINFER_MOE_FP16=1 VLLM_FLASHINFER_MOE_BACKEND=throughput"

# === Tier-1 — full coordinate-descent + S6 context-ceiling probe (TP=2) =======
register_model qwen3-coder-next-80b \
  "cyankiwi/Qwen3-Coder-Next-AWQ-4bit" "bench-qwen3-coder-next-80b" 0 \
  "--tool-call-parser qwen3_coder"
M_TIER[qwen3-coder-next-80b]=full; M_CEIL[qwen3-coder-next-80b]=262144
M_AB[qwen3-coder-next-80b]=qwen3-coder-next-60b-ream

register_model qwen3-coder-30b \
  "cyankiwi/Qwen3-Coder-30B-A3B-Instruct-AWQ-4bit" "bench-qwen3-coder-30b" 0 \
  "--tool-call-parser qwen3_coder"
M_TIER[qwen3-coder-30b]=full; M_CEIL[qwen3-coder-30b]=262144

register_model qwen36-35b-a3b \
  "cyankiwi/Qwen3.6-35B-A3B-AWQ-4bit" "bench-qwen36-35b-a3b" 1 \
  "--reasoning-parser qwen3 --tool-call-parser qwen3_coder"
M_TIER[qwen36-35b-a3b]=full; M_CEIL[qwen36-35b-a3b]=131072; M_NOTHINK[qwen36-35b-a3b]=1

# GLM's grouped-attention fp8-KV kernel demands fp8e4nv, unsupported on the 3090
# (sm_86) — engine init dies under the fixed `--kv-cache-dtype fp8`. The trailing
# `--kv-cache-dtype auto` here lands after FIXED_ARGS in build_cmd and wins
# (argparse last-occurrence), forcing fp16 KV so the model loads on Ampere.
register_model glm47-flash \
  "cyankiwi/GLM-4.7-Flash-REAP-23B-A3B-AWQ-4bit" "bench-glm47-flash" 0 \
  "--tool-call-parser glm47 --reasoning-parser glm45 --enable-expert-parallel --trust-remote-code --kv-cache-dtype auto"
M_TIER[glm47-flash]=full; M_CEIL[glm47-flash]=131072; M_NOTHINK[glm47-flash]=1
M_ENV[glm47-flash]="$GLM_ENV"

# === Tier-2 — quick (S0 anchor + S6 ceiling ladder), other families ===========
register_model devstral-24b-gptq \
  "btbtyler09/Devstral-Small-2-24B-Instruct-INT4-INT8-Mixed-GPTQ" "bench-devstral-24b-gptq" 0 \
  "--tool-call-parser mistral --quantization compressed-tensors"
M_TIER[devstral-24b-gptq]=quick; M_CEIL[devstral-24b-gptq]=131072
M_AB[devstral-24b-gptq]=devstral-24b-fp8

# gpt-oss-20b hits TWO Ampere (sm_86) blockers under the fixed args, both needed:
#   1. torch.compile/Inductor autotune of its MXFP4 MoE kernel fails
#      (InductorError) -> --enforce-eager skips torch.compile + CUDA graphs.
#   2. its TRITON_ATTN reshape_and_cache_kernel_flash demands fp8e4nv for the fp8
#      KV cache (unsupported on sm_86) -> --kv-cache-dtype auto lands after
#      FIXED_ARGS and wins (argparse last-occurrence), forcing fp16 KV.
# Decode numbers carry the eager caveat (no CUDA graphs).
register_model gpt-oss-20b \
  "openai/gpt-oss-20b" "bench-gpt-oss-20b" 0 \
  "--tool-call-parser openai --enforce-eager --kv-cache-dtype auto"
M_TIER[gpt-oss-20b]=quick; M_CEIL[gpt-oss-20b]=131072

# Sweep-D variant: newer vLLM image to test whether Ampere MXFP4/fp8 blockers
# are fixed upstream. Drops --enforce-eager; if torch.compile still fails at
# startup the result.json will say so and we revert to the eager baseline above.
register_model gpt-oss-20b-nightly \
  "openai/gpt-oss-20b" "bench-gpt-oss-20b-nightly" 0 \
  "--tool-call-parser openai --kv-cache-dtype auto"
M_TIER[gpt-oss-20b-nightly]=quick; M_CEIL[gpt-oss-20b-nightly]=131072
M_IMAGE[gpt-oss-20b-nightly]="vllm/vllm-openai:latest"

# === Quant A/B siblings (matched config vs their baseline above) ==============
register_model qwen3-coder-next-60b-ream \
  "cyankiwi/Qwen3-Coder-Next-REAM-AWQ-4bit" "bench-qwen3-coder-next-60b-ream" 0 \
  "--tool-call-parser qwen3_coder"
M_TIER[qwen3-coder-next-60b-ream]=quick; M_CEIL[qwen3-coder-next-60b-ream]=262144

register_model devstral-24b-fp8 \
  "stelterlab/Devstral-Small-2507-FP8" "bench-devstral-24b-fp8" 0 \
  "--tool-call-parser mistral"
M_TIER[devstral-24b-fp8]=quick; M_CEIL[devstral-24b-fp8]=131072

# === Legacy single-card models (kept for the TP=1 path / reproducibility) =====
register_model qwen36-27b \
  "cyankiwi/Qwen3.6-27B-AWQ-INT4" "bench-qwen36-27b" 1 \
  "--reasoning-parser qwen3 --tool-call-parser qwen3_coder"
M_TIER[qwen36-27b]=full; M_CEIL[qwen36-27b]=90944; M_NOTHINK[qwen36-27b]=1

# Default roster: the dual-GPU broad+tiered run (Tier-1 first, then Tier-2 + A/B).
DEFAULT_MODELS="qwen3-coder-next-80b qwen3-coder-30b qwen36-35b-a3b glm47-flash devstral-24b-gptq gpt-oss-20b qwen3-coder-next-60b-ream devstral-24b-fp8"

# Fixed engine args applied to every benchmarked config.
# NOTE: --tensor-parallel-size is injected per-model in build_cmd (global $TP or
# the model's M_TP override), and topology args (--disable-custom-all-reduce when
# no NVLink) are appended via $TOPO_ARGS — neither belongs in this static string.
FIXED_ARGS="--kv-cache-dtype fp8 --enable-chunked-prefill --enable-prefix-caching --enable-auto-tool-choice"

# Fixed container env.
declare -a FIXED_ENV=(
  -e "PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
  -e "VLLM_USE_FLASHINFER_SAMPLER=1"
  -e "VLLM_ATTENTION_BACKEND=FLASHINFER"
  -e "VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0"
)

# Sweep candidate values (anchor listed first in each).
# NOTE on util: these 4-bit 27-35B models have ~17-19 GiB of weights, so on a
# single 24 GiB 3090 they are weight-bound — the binding limit is KV-cache room
# for one full max_model_len sequence (vLLM >=0.23 hard-enforces this). KV room
# therefore grows with util, so the anchor sits HIGH (0.95) and the GPU-1-only
# sweep can safely push to 0.97 (the card is dedicated during the run). Lower
# util only ever shrinks the usable context here.
BATCHED_VALUES=(8192 4096 2048 16384)
SEQS_VALUES=(1 2 4)
LEN_VALUES=(32768 16384 65536 90944)
UTIL_VALUES=(0.95 0.92 0.97)

# S6 context-ceiling ladder (ascending). Walked until kv-too-small to find each
# model's max usable context; filtered to <= M_CEIL and skips lens already run.
# On dual cards (48 GiB, TP=2) the KV pool is ~2x a single card, so this climbs
# well past the single-card ~98K ceiling toward the models' native 256K.
CEIL_LADDER=(32768 65536 131072 196608 262144)

# Dual-GPU (TP>=2) overrides applied after arg-parsing: anchor util lower (more
# headroom for NCCL/all-reduce buffers across two cards, per club-3090 dual.yml),
# and start the tuning len ladder higher since there is far more KV room.
DUAL_UTIL_VALUES=(0.90 0.92 0.95)
DUAL_LEN_VALUES=(32768 65536 131072 196608)

# Tracking
declare -a FAILED_OOM=()     # "util:len:seqs" entries known to OOM
STOP_REQUESTED=0

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------
log()  { printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
warn() { log "WARN: $*" >&2; }
die()  { log "FATAL: $*" >&2; exit 1; }

usage() { sed -n '2,47p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --smoke) SMOKE=1; shift;;
    --prepull) PREPULL=1; shift;;
    --models) MODELS_ARG="$2"; shift 2;;
    --config) EXPLICIT_CONFIGS+=("$2"); shift 2;;
    --run-dir) RUN_DIR="$2"; shift 2;;
    --gpu) GPU="$2"; shift 2;;
    --gpus-list) GPUS_LIST="$2"; shift 2;;
    --tp) TP="$2"; shift 2;;
    --port) HOST_PORT="$2"; shift 2;;
    --wait-for-free) WAIT_FOR_FREE="$2"; shift 2;;
    --max-hours) MAX_HOURS="$2"; shift 2;;
    -h|--help) usage;;
    *) die "unknown argument: $1 (try --help)";;
  esac
done

MODELS="${MODELS_ARG:-$DEFAULT_MODELS}"

# --- Resolve the physical GPU list ------------------------------------------
# --gpus-list "0,1" wins; else fall back to the single --gpu index. GPU_IDS is
# what the preflight free-checks and what NVIDIA_VISIBLE_DEVICES pins.
if [[ -n "$GPUS_LIST" ]]; then
  IFS=',' read -r -a GPU_IDS <<<"$GPUS_LIST"
else
  GPU_IDS=("$GPU")
  GPUS_LIST="$GPU"
fi

# --- Dual-card (TP>=2) tuning overrides -------------------------------------
if (( TP >= 2 )); then
  UTIL_VALUES=("${DUAL_UTIL_VALUES[@]}")
  LEN_VALUES=("${DUAL_LEN_VALUES[@]}")
fi

# -----------------------------------------------------------------------------
# Preconditions
# -----------------------------------------------------------------------------
for bin in docker nvidia-smi curl jq awk; do
  command -v "$bin" >/dev/null || die "required tool not found: $bin"
done

# Source .env (HF token) if present.
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi
HF_TOKEN_VAL="${HUGGING_FACE_HUB_TOKEN:-${HF_TOKEN:-}}"
[[ -n "$HF_TOKEN_VAL" ]] || warn "no HUGGING_FACE_HUB_TOKEN set — gated/large downloads may fail"

# -----------------------------------------------------------------------------
# GPU helpers
# -----------------------------------------------------------------------------
gpu_used_mib() {
  # Used MiB for one GPU index ($1, defaults to the first in GPU_IDS).
  local idx="${1:-${GPU_IDS[0]}}"
  nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits -i "$idx" 2>/dev/null | tr -d ' '
}

gpus_used_summary() {
  # "0=123 1=456" — per-card used MiB across the run's GPU_IDS, for logs/reports.
  local idx out=""
  for idx in "${GPU_IDS[@]}"; do out+="${idx}=$(gpu_used_mib "$idx") "; done
  echo "${out% }"
}

gpu_is_free() {
  # True only if EVERY card in GPU_IDS is below the free threshold.
  local idx used
  for idx in "${GPU_IDS[@]}"; do
    used="$(gpu_used_mib "$idx" || echo 999999)"
    [[ -n "$used" && "$used" -lt "$FREE_THRESHOLD_MIB" ]] || return 1
  done
  return 0
}

wait_gpu_free() {
  # Wait for VRAM to drain on all cards after a teardown (bounded).
  local deadline=$((SECONDS + FREE_TIMEOUT))
  while ! gpu_is_free; do
    (( SECONDS < deadline )) || { warn "GPU(s) [${GPUS_LIST}] did not drain within ${FREE_TIMEOUT}s (used: $(gpus_used_summary) MiB)"; return 1; }
    sleep 5
  done
  return 0
}

# Detect an NVLink bridge between the two cards (dual only). vLLM's *custom*
# all-reduce kernel crashes on these 3090s (custom_all_reduce.cuh:455 'invalid
# argument'), so --disable-custom-all-reduce is applied on BOTH paths. NVLink
# still accelerates the fallback NCCL all-reduce, so NCCL_P2P_DISABLE=1 is forced
# only when NVLink is absent (PCIe path). Sets NVLINK_PRESENT / TOPO_ARGS /
# TOPO_ENV. See results/ notes + orion-nvlink-present memory.
detect_nvlink() {
  NVLINK_PRESENT=""; TOPO_ARGS=""; TOPO_ENV=()
  (( TP >= 2 )) || { NVLINK_PRESENT="n/a"; return 0; }
  TOPO_ARGS="--disable-custom-all-reduce"
  local topo; topo="$(nvidia-smi topo -m 2>/dev/null || true)"
  if grep -qE 'NV[0-9]+' <<<"$topo"; then
    NVLINK_PRESENT="1"
    log "NVLink detected — custom all-reduce disabled (crashes on 3090); NCCL all-reduce over NVLink"
  else
    NVLINK_PRESENT="0"
    TOPO_ENV=(-e "NCCL_P2P_DISABLE=1")
    log "No NVLink — --disable-custom-all-reduce + NCCL_P2P_DISABLE=1 (PCIe path)"
  fi
}

# -----------------------------------------------------------------------------
# Container lifecycle
# -----------------------------------------------------------------------------
teardown() {
  docker rm -f "$CTR_NAME" >/dev/null 2>&1 || true
}
trap 'teardown' EXIT

build_cmd() {
  # $1 repo $2 served $3 util $4 len $5 seqs $6 batched $7 lmonly(on/off/na) $8 extra $9 tp
  local repo="$1" served="$2" util="$3" len="$4" seqs="$5" batched="$6" lmonly="$7" extra="$8" tp="${9:-$TP}"
  local lm=""
  [[ "$lmonly" == "on" ]] && lm="--language-model-only"
  printf '%s --port 8000 --served-model-name %s --tensor-parallel-size %s %s %s %s --max-model-len %s --gpu-memory-utilization %s --max-num-batched-tokens %s --max-num-seqs %s %s' \
    "$repo" "$served" "$tp" "$FIXED_ARGS" "$TOPO_ARGS" "$extra" "$len" "$util" "$batched" "$seqs" "$lm"
}

launch_server() {
  # $1 full vllm command string (model + args)
  # $2 image (per-model override; default $IMAGE)
  # $3 model env string ("VAR=val VAR2=val2"; converted to -e flags)
  local cmd="$1" image="${2:-$IMAGE}" model_env="${3:-}"
  teardown
  local -a menv=()
  local kv
  for kv in $model_env; do menv+=(-e "$kv"); done
  # shellcheck disable=SC2086
  docker run -d --init --name "$CTR_NAME" \
    --runtime=nvidia -e "NVIDIA_VISIBLE_DEVICES=${GPUS_LIST}" \
    --ipc=host --shm-size=32g \
    -p "${HOST_PORT}:8000" \
    --network "$NETWORK" \
    -v hf-cache:/root/.cache/huggingface \
    -v vllm-cache:/root/.cache/vllm \
    -e "HUGGING_FACE_HUB_TOKEN=${HF_TOKEN_VAL}" \
    "${FIXED_ENV[@]}" "${TOPO_ENV[@]}" "${menv[@]}" \
    "$image" $cmd >/dev/null 2>&1 || warn "docker run returned non-zero (wait_ready will catch it)"
  return 0   # never abort the sweep on a launch failure; wait_ready reports it
}

# Readiness gate: returns 0 ready, 1 failed (writes reason to global READY_REASON).
READY_REASON=""
wait_ready() {
  local deadline=$((SECONDS + READY_TIMEOUT))
  READY_REASON=""
  while (( SECONDS < deadline )); do
    if ! docker ps --format '{{.Names}}' | grep -qx "$CTR_NAME"; then
      # Container died during init — classify from its logs so the sweep can
      # react correctly (KV-too-small wants higher util/shorter ctx, not lower).
      local _logs; _logs="$(docker logs "$CTR_NAME" 2>&1 || true)"
      if grep -qiE 'available KV cache memory|estimated maximum model length|No available memory for the cache' <<<"$_logs"; then
        READY_REASON="kv-too-small"
      elif grep -qiE 'CUDA out of memory|out of memory' <<<"$_logs"; then
        READY_REASON="oom"
      else
        READY_REASON="container-exited"
      fi
      return 1
    fi
    if curl -fsS "http://localhost:${HOST_PORT}/health" >/dev/null 2>&1; then
      return 0
    fi
    # Scan logs for hard failures so we don't wait the full timeout on a crash.
    if docker logs "$CTR_NAME" 2>&1 | grep -qiE \
        'CUDA out of memory|No available memory for the cache|EngineCore failed|is larger than the maximum number of tokens|ValueError|Engine core initialization failed'; then
      if docker logs "$CTR_NAME" 2>&1 | grep -qiE 'out of memory|No available memory for the cache|larger than the maximum number of tokens'; then
        READY_REASON="oom"
      else
        READY_REASON="engine-error"
      fi
      return 1
    fi
    sleep 5
  done
  READY_REASON="timeout"
  return 1
}

# -----------------------------------------------------------------------------
# Validation calls
# -----------------------------------------------------------------------------
api() { curl -fsS -m "${1:-60}" -H 'Content-Type: application/json' "${@:2}"; }

validate_config() {
  # $1 served  $2 maxlen  $3 out_dir  $4 nothink(1/0)  -> 0 pass / 1 fail; writes validation.json
  local served="$1" maxlen="$2" dir="$3" nothink_flag="${4:-0}"
  local base="http://localhost:${HOST_PORT}/v1"
  local vfile="$dir/validation.json"
  local ok_models=0 ok_coding=0 ok_tool=0 ok_long=0

  # Reasoning models (Qwen3.6, GLM) spend the whole token budget in an (un-parsed)
  # chain-of-thought and emit no code, so for those the functional gate disables
  # thinking (chat_template_kwargs.enable_thinking=false). Non-reasoning models
  # (coder-Instruct, Devstral, gpt-oss) reject that kwarg in their chat template,
  # so it is sent ONLY when the model's M_NOTHINK override is set. The throughput
  # benchmark uses random tokens and is unaffected either way.
  local nothink='{}'
  [[ "$nothink_flag" == "1" ]] && nothink='{"chat_template_kwargs":{"enable_thinking":false}}'

  # Each response is written to its own file and sanitised to valid JSON, so the
  # final encode can never fail (the previous --argjson form could lose all data).
  local _sane='if . == null then {} else . end'
  _save() { jq -c "$_sane" >"$1" 2>/dev/null || echo '{}' >"$1"; }

  # 1. model list
  if api 30 "$base/models" 2>/dev/null | jq -e --arg m "$served" '.data[]?.id==$m' >/dev/null 2>&1; then
    ok_models=1
  fi

  # 2. coding task
  local coding_req
  coding_req="$(jq -c --arg m "$served" --argjson nt "$nothink" '.coding + {model:$m} + $nt' "$PROMPTS_FILE")"
  api 180 "$base/chat/completions" -d "$coding_req" 2>/dev/null | _save "$dir/resp_coding.json"
  if jq -e '.choices[0].message.content | test("def |class |```")' "$dir/resp_coding.json" >/dev/null 2>&1; then
    ok_coding=1
  fi

  # 3. tool-call probe
  local tool_req
  tool_req="$(jq -c --arg m "$served" --argjson nt "$nothink" '.tool_call + {model:$m} + $nt' "$PROMPTS_FILE")"
  api 120 "$base/chat/completions" -d "$tool_req" 2>/dev/null | _save "$dir/resp_tool.json"
  # Pass if the request returns a well-formed choice without a server error
  # (tool_calls present is ideal but model may answer directly).
  if jq -e '.choices[0].message and (.error|not)' "$dir/resp_tool.json" >/dev/null 2>&1; then
    ok_tool=1
  fi

  # 4. long-context probe (capped to keep iterations fast)
  echo '{}' >"$dir/resp_long.json"
  local target=$(( maxlen - 2048 ))
  (( target > 28000 )) && target=28000
  (( target < 2048 )) && target=2048
  if (( SMOKE == 0 )); then
    local needle question filler tmpc units i
    needle="$(jq -r '.long_context.needle' "$PROMPTS_FILE")"
    question="$(jq -r '.long_context.question' "$PROMPTS_FILE")"
    filler="$(jq -r '.long_context.filler_unit' "$PROMPTS_FILE")"
    units=$(( target / 8 ))            # ~8 tokens per filler unit
    tmpc="$(mktemp)"
    printf '%s\n\n' "$needle" >"$tmpc"
    for (( i=0; i<units; i++ )); do printf "$filler" "$i" "$i" >>"$tmpc"; done
    local long_req
    long_req="$(jq -Rs --arg m "$served" --arg q "$question" --argjson nt "$nothink" \
      '({model:$m, messages:[{role:"user", content:(. + "\n\n" + $q)}], max_tokens:128, temperature:0, stream:false} + $nt)' \
      <"$tmpc")"
    api 240 "$base/chat/completions" -d "$long_req" 2>/dev/null | _save "$dir/resp_long.json"
    rm -f "$tmpc"
    if jq -e '.choices[0].message.content and (.error|not)' "$dir/resp_long.json" >/dev/null 2>&1; then
      ok_long=1
    fi
  else
    ok_long=1   # skip in smoke mode
  fi

  jq -n \
    --argjson models "$ok_models" --argjson coding "$ok_coding" \
    --argjson tool "$ok_tool" --argjson long "$ok_long" \
    --slurpfile coding_resp "$dir/resp_coding.json" \
    --slurpfile tool_resp "$dir/resp_tool.json" \
    --slurpfile long_resp "$dir/resp_long.json" \
    '{models_ok:($models==1), coding_ok:($coding==1), tool_ok:($tool==1), long_ctx_ok:($long==1),
      responses:{coding:($coding_resp[0]//{}), tool_call:($tool_resp[0]//{}), long_context:($long_resp[0]//{})}}' \
    >"$vfile" 2>/dev/null || echo '{"error":"validation-encode-failed"}' >"$vfile"

  # Require at least model-list + coding to pass.
  [[ $ok_models -eq 1 && $ok_coding -eq 1 ]]
}

# -----------------------------------------------------------------------------
# Benchmark (vllm bench serve, inside the container)
# -----------------------------------------------------------------------------
run_bench() {
  # $1 served  $2 repo(tokenizer)  $3 out_dir
  local served="$1" repo="$2" dir="$3"
  local inproc="http://localhost:8000"
  local np_c1=24 np_long=8 np_c2=24 np_c4=32
  if (( SMOKE == 1 )); then np_c1=4; np_long=0; np_c2=0; np_c4=0; fi

  _bench() {
    # $1 label  $2 in_len  $3 out_len  $4 num_prompts  $5 max_conc
    local label="$1" ilen="$2" olen="$3" np="$4" conc="$5"
    (( np > 0 )) || return 0
    log "    bench[$label]: in=$ilen out=$olen n=$np conc=$conc"
    docker exec "$CTR_NAME" vllm bench serve \
        --backend openai-chat --base-url "$inproc" \
        --endpoint /v1/chat/completions \
        --model "$served" --tokenizer "$repo" \
        --dataset-name random --random-input-len "$ilen" --random-output-len "$olen" \
        --num-prompts "$np" --max-concurrency "$conc" --request-rate inf \
        --save-result --result-filename "/tmp/${label}.json" \
        >"$dir/bench_${label}.log" 2>&1 || { warn "bench[$label] failed (see bench_${label}.log)"; return 0; }
    docker cp "$CTR_NAME:/tmp/${label}.json" "$dir/bench_${label}.json" >/dev/null 2>&1 || true
  }

  _bench c1   4096 512  "$np_c1"   1
  _bench long 16384 1024 "$np_long" 1
  _bench c2   4096 512  "$np_c2"   2
  _bench c4   4096 512  "$np_c4"   4
}

# -----------------------------------------------------------------------------
# Result parsing
# -----------------------------------------------------------------------------
write_result() {
  # $1 dir  $2 model_key  $3 config_id  $4 status  $5 reason  + config fields env
  local dir="$1" model="$2" cid="$3" status="$4" reason="$5"
  local kv_tokens="" max_conc=""
  if [[ -f "$dir/server.log" ]]; then
    kv_tokens="$(grep -oiE 'GPU KV cache size: [0-9,]+ tokens' "$dir/server.log" | tail -1 | grep -oE '[0-9,]+' | tr -d ',' || true)"
    max_conc="$(grep -oiE 'Maximum concurrency for [0-9,]+ tokens per request: [0-9.]+x' "$dir/server.log" | tail -1 | grep -oE '[0-9.]+x' || true)"
  fi
  local b="$dir/bench_c1.json"
  local ttft_p50="null" ttft_p99="null" tpot_p50="null" decode_toks="null" out_tps="null" e2e_p50="null"
  if [[ -f "$b" ]]; then
    ttft_p50="$(jq -r '.median_ttft_ms // empty' "$b" 2>/dev/null || true)"; : "${ttft_p50:=null}"
    ttft_p99="$(jq -r '.p99_ttft_ms // empty' "$b" 2>/dev/null || true)"; : "${ttft_p99:=null}"
    tpot_p50="$(jq -r '.median_tpot_ms // empty' "$b" 2>/dev/null || true)"; : "${tpot_p50:=null}"
    out_tps="$(jq -r '.output_throughput // empty' "$b" 2>/dev/null || true)"; : "${out_tps:=null}"
    e2e_p50="$(jq -r '.median_e2el_ms // .median_e2e_ms // empty' "$b" 2>/dev/null || true)"; : "${e2e_p50:=null}"
    if [[ "$tpot_p50" != "null" && -n "$tpot_p50" ]]; then
      decode_toks="$(awk -v t="$tpot_p50" 'BEGIN{ if(t>0) printf "%.2f", 1000.0/t; else print "null" }')"
    fi
  fi

  # Parse concurrency benchmarks (c2, c4) — present only when np_c2/np_c4 > 0.
  _parse_conc_bench() {
    local bf="$dir/bench_${1}.json"
    local tpot="" outtps="" agg_toks="null"
    [[ -f "$bf" ]] || { echo "null"; return; }
    tpot="$(jq -r '.median_tpot_ms // empty' "$bf" 2>/dev/null || true)"; : "${tpot:=null}"
    outtps="$(jq -r '.output_throughput // empty' "$bf" 2>/dev/null || true)"; : "${outtps:=null}"
    if [[ "$tpot" != "null" && -n "$tpot" ]]; then
      agg_toks="$(awk -v t="$tpot" -v c="$2" 'BEGIN{ if(t>0) printf "%.2f", c*1000.0/t; else print "null" }')"
    fi
    jq -n --argjson tpot "${tpot:-null}" --argjson outtps "${outtps:-null}" \
          --argjson agg "${agg_toks:-null}" \
          '{tpot_p50_ms:$tpot, output_throughput:$outtps, agg_decode_toks_per_s:$agg}'
  }
  local conc2; conc2="$(_parse_conc_bench c2 2)"
  local conc4; conc4="$(_parse_conc_bench c4 4)"

  jq -n \
    --arg model "$model" --arg cid "$cid" --arg status "$status" --arg reason "$reason" \
    --arg util "$CFG_UTIL" --arg len "$CFG_LEN" --arg seqs "$CFG_SEQS" \
    --arg batched "$CFG_BATCHED" --arg lmonly "$CFG_LMONLY" \
    --arg kv "$kv_tokens" --arg maxconc "$max_conc" \
    --argjson ttft50 "${ttft_p50:-null}" --argjson ttft99 "${ttft_p99:-null}" \
    --argjson tpot50 "${tpot_p50:-null}" --argjson decode "${decode_toks:-null}" \
    --argjson outtps "${out_tps:-null}" --argjson e2e50 "${e2e_p50:-null}" \
    --argjson c2 "${conc2:-null}" --argjson c4 "${conc4:-null}" \
    '{model:$model, config_id:$cid, status:$status, reason:$reason,
      config:{gpu_memory_utilization:($util|tonumber), max_model_len:($len|tonumber),
              max_num_seqs:($seqs|tonumber), max_num_batched_tokens:($batched|tonumber),
              language_model_only:$lmonly},
      capacity:{kv_cache_tokens:(if $kv=="" then null else ($kv|tonumber) end), max_concurrency:$maxconc},
      latency_c1:{ttft_p50_ms:$ttft50, ttft_p99_ms:$ttft99, tpot_p50_ms:$tpot50,
                  decode_toks_per_s:$decode, output_throughput:$outtps, e2e_p50_ms:$e2e50},
      latency_concurrency:{c2:$c2, c4:$c4}}' \
    >"$dir/result.json"
}

# -----------------------------------------------------------------------------
# Dominance pruning (OOM)
# -----------------------------------------------------------------------------
is_dominated_oom() {
  # args: util len seqs  -> 0 if a recorded OOM dominates (=> will also OOM)
  local u="$1" l="$2" s="$3" f fu fl fs
  for f in "${FAILED_OOM[@]:-}"; do
    [[ -z "$f" ]] && continue
    IFS=':' read -r fu fl fs <<<"$f"
    if awk -v u="$u" -v fu="$fu" 'BEGIN{exit !(fu>=u)}' \
       && (( l >= fl )) && (( s >= fs )); then
      return 0
    fi
  done
  return 1
}

# -----------------------------------------------------------------------------
# Run one config (idempotent / resumable)
#   sets globals CFG_* ; echoes the decode tok/s metric (or -1 on failure)
# -----------------------------------------------------------------------------
CFG_UTIL=""; CFG_LEN=""; CFG_SEQS=""; CFG_BATCHED=""; CFG_LMONLY=""
RUN_METRIC=""   # decode tok/s of the last run_config (or -1 fail / 0 dry-run)
# NOTE: run_config MUST be called directly (not via $(...)), so its CFG_* and
# FAILED_OOM side effects persist and log() output isn't captured. Read the
# result from $RUN_METRIC after the call.
run_config() {
  local mkey="$1" util="$2" len="$3" seqs="$4" batched="$5" lmonly="$6"
  CFG_UTIL="$util"; CFG_LEN="$len"; CFG_SEQS="$seqs"; CFG_BATCHED="$batched"; CFG_LMONLY="$lmonly"

  local uflat="${util/./}"
  local cid="u${uflat}_l${len}_s${seqs}_b${batched}_lm${lmonly}"
  local dir="$RUN_DIR/$mkey/$cid"
  mkdir -p "$dir"

  # Resume: skip if already completed.
  if [[ -f "$dir/result.json" ]]; then
    local prev_metric; prev_metric="$(jq -r '.latency_c1.decode_toks_per_s // -1' "$dir/result.json" 2>/dev/null || echo -1)"
    log "  [skip] $mkey/$cid already done (decode=${prev_metric} tok/s)"
    RUN_METRIC="${prev_metric:--1}"; return 0
  fi

  # Prune dominated OOM region.
  if is_dominated_oom "$util" "$len" "$seqs"; then
    log "  [prune] $mkey/$cid dominated by a known OOM — skipping"
    write_result "$dir" "$mkey" "$cid" "pruned" "dominated-oom"
    RUN_METRIC="-1"; return 0
  fi

  local repo="${M_REPO[$mkey]}" served="${M_SERVED[$mkey]}" extra="${M_EXTRA[$mkey]}"
  local mtp mimg menv mnothink
  mtp="$(model_opt M_TP "$mkey" "$TP")"
  mimg="$(model_opt M_IMAGE "$mkey" "$IMAGE")"
  menv="$(model_opt M_ENV "$mkey" "")"
  mnothink="$(model_opt M_NOTHINK "$mkey" "0")"
  local cmd; cmd="$(build_cmd "$repo" "$served" "$util" "$len" "$seqs" "$batched" "$lmonly" "$extra" "$mtp")"

  jq -n --arg image "$mimg" --arg cmd "$cmd" --arg gpus "$GPUS_LIST" --arg tp "$mtp" \
        --arg nvlink "${NVLINK_PRESENT:-n/a}" --arg topo "$TOPO_ARGS" --arg env "$menv" \
        --arg ts "$(date -Is)" \
        '{image:$image, gpus:$gpus, tp:($tp|tonumber), nvlink:$nvlink,
          topo_args:$topo, model_env:$env, command:$cmd, started:$ts}' \
        >"$dir/config.json"

  if (( DRY_RUN == 1 )); then
    log "  [dry-run] $mkey/$cid (tp=$mtp gpus=$GPUS_LIST img=$mimg)"
    log "            docker run ... --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=$GPUS_LIST ${menv:+[env: $menv] }$mimg $cmd"
    RUN_METRIC="0"; return 0
  fi

  log "  [run] $mkey/$cid (tp=$mtp gpus=$GPUS_LIST)"
  log "        $cmd"
  launch_server "$cmd" "$mimg" "$menv"

  if ! wait_ready; then
    docker logs "$CTR_NAME" >"$dir/server.log" 2>&1 || true
    local reason="$READY_REASON"
    warn "  $mkey/$cid not ready ($reason)"
    # OOM back-off: one retry at util-0.05.
    if [[ "$reason" == "oom" ]]; then
      FAILED_OOM+=("$util:$len:$seqs")
      local lower; lower="$(awk -v u="$util" 'BEGIN{printf "%.2f", u-0.05}')"
      if awk -v l="$lower" 'BEGIN{exit !(l>=0.80)}'; then
        log "  [retry] $mkey/$cid at util=$lower (OOM back-off)"
        teardown; wait_gpu_free || true
        CFG_UTIL="$lower"
        local cmd2; cmd2="$(build_cmd "$repo" "$served" "$lower" "$len" "$seqs" "$batched" "$lmonly" "$extra" "$mtp")"
        launch_server "$cmd2" "$mimg" "$menv"
        if wait_ready; then
          util="$lower"; cmd="$cmd2"
        else
          docker logs "$CTR_NAME" >"$dir/server.log" 2>&1 || true
          write_result "$dir" "$mkey" "$cid" "failed" "$READY_REASON"
          teardown; wait_gpu_free || true
          RUN_METRIC="-1"; return 0
        fi
      else
        write_result "$dir" "$mkey" "$cid" "failed" "$reason"
        teardown; wait_gpu_free || true
        RUN_METRIC="-1"; return 0
      fi
    else
      write_result "$dir" "$mkey" "$cid" "failed" "$reason"
      teardown; wait_gpu_free || true
      RUN_METRIC="-1"; return 0
    fi
  fi

  # Ready — capture startup log + metrics, validate, benchmark.
  docker logs "$CTR_NAME" >"$dir/server.log" 2>&1 || true
  curl -fsS "http://localhost:${HOST_PORT}/metrics" >"$dir/metrics_before.txt" 2>/dev/null || true

  if ! validate_config "$served" "$len" "$dir" "$mnothink"; then
    warn "  $mkey/$cid validation failed"
    docker logs "$CTR_NAME" >"$dir/server.log" 2>&1 || true
    write_result "$dir" "$mkey" "$cid" "validation-failed" "coding-or-models-check"
    teardown; wait_gpu_free || true
    # -2 marks a *functional* failure (the server ran fine, the model just didn't
    # pass the gate). The S0 anchor back-off raises util only for capacity (-1)
    # failures; raising util cannot fix a validation failure, so it must not fire.
    RUN_METRIC="-2"; return 0
  fi

  run_bench "$served" "$repo" "$dir"
  curl -fsS "http://localhost:${HOST_PORT}/metrics" >"$dir/metrics_after.txt" 2>/dev/null || true
  docker logs "$CTR_NAME" >"$dir/server.log" 2>&1 || true
  write_result "$dir" "$mkey" "$cid" "ok" ""

  teardown
  wait_gpu_free || true

  local metric; metric="$(jq -r '.latency_c1.decode_toks_per_s // -1' "$dir/result.json" 2>/dev/null || echo -1)"
  log "  [done] $mkey/$cid decode=${metric} tok/s ttft_p50=$(jq -r '.latency_c1.ttft_p50_ms' "$dir/result.json")ms"
  RUN_METRIC="${metric:--1}"
}

budget_exceeded() {
  local now elapsed_h
  now="$(date +%s)"
  elapsed_h="$(awk -v a="$START_EPOCH" -v b="$now" 'BEGIN{printf "%.2f", (b-a)/3600.0}')"
  awk -v e="$elapsed_h" -v m="$MAX_HOURS" 'BEGIN{exit !(e>=m)}'
}

# -----------------------------------------------------------------------------
# Coordinate-descent sweep for one model
# -----------------------------------------------------------------------------
sweep_model() {
  local mkey="$1"
  [[ -n "${M_REPO[$mkey]:-}" ]] || { warn "unknown model key: $mkey"; return; }
  log "=== model: $mkey (${M_REPO[$mkey]}) ==="

  # Reset the OOM-domination set per model: an OOM point recorded for one model
  # (e.g. a 40 GiB 80B that won't fit) says nothing about a smaller model, and
  # would otherwise prune every later config as "dominated-oom" without running.
  FAILED_OOM=()

  local mm="${M_MM[$mkey]}"
  local a_util="${UTIL_VALUES[0]}" a_len="${LEN_VALUES[0]}" a_seqs="${SEQS_VALUES[0]}"
  local a_batched="${BATCHED_VALUES[0]}"
  local a_lmonly="na"; [[ "$mm" == "1" ]] && a_lmonly="on"

  # --- S0 capacity probe: find a working anchor -------------------------------
  # The dominant failure on a single card is "KV cache too small for one full
  # max_model_len sequence" — the container exits during init. The correct
  # recovery is to RAISE util (more KV) and/or LOWER len; lowering util shrinks
  # KV and is never useful here. Walk util up to 0.97, then shorten context.
  local m
  run_config "$mkey" "$a_util" "$a_len" "$a_seqs" "$a_batched" "$a_lmonly"; m="$RUN_METRIC"
  a_util="$CFG_UTIL"
  if [[ "$m" == "-2" ]]; then
    warn "  $mkey: anchor passed startup but failed functional validation — skipping model"
    return
  elif awk -v x="$m" 'BEGIN{exit !(x<0)}'; then
    log "  anchor failed at util=$a_util len=$a_len — raising util / shortening context"
    local got=0 tu tl
    for tu in 0.97 0.95; do
      for tl in 32768 16384 8192; do
        # skip the (util,len) we already tried as the anchor
        awk -v u="$tu" -v au="$a_util" -v l="$tl" -v al="$a_len" \
            'BEGIN{exit !(u==au && l==al)}' && continue
        log "  anchor back-off: util=$tu len=$tl"
        run_config "$mkey" "$tu" "$tl" "$a_seqs" "$a_batched" "$a_lmonly"; m="$RUN_METRIC"; a_util="$CFG_UTIL"
        # A functional failure won't be cured by more util — stop probing.
        if [[ "$m" == "-2" ]]; then
          warn "  $mkey: anchor started but failed functional validation — skipping model"
          return
        fi
        if awk -v x="$m" 'BEGIN{exit !(x>=0)}'; then a_len="$tl"; got=1; break; fi
      done
      (( got == 1 )) && break
    done
    if (( got == 0 )); then
      warn "  $mkey: could not establish a working anchor — skipping model"
      return
    fi
  fi
  log "  anchor: util=$a_util len=$a_len seqs=$a_seqs batched=$a_batched lm=$a_lmonly (decode=$m)"

  if (( SMOKE == 1 )); then log "  [smoke] one config only — done with $mkey"; return; fi

  local tier; tier="$(model_opt M_TIER "$mkey" "full")"
  local best v cand
  best="$m"

  if [[ "$tier" == "full" ]]; then
    # --- S1 max-num-batched-tokens -------------------------------------------
    for v in "${BATCHED_VALUES[@]:1}"; do
      budget_exceeded && { STOP_REQUESTED=1; return; }
      run_config "$mkey" "$a_util" "$a_len" "$a_seqs" "$v" "$a_lmonly"; cand="$RUN_METRIC"
      if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; a_batched="$v"; fi
    done
    log "  S1 best batched=$a_batched (decode=$best)"

    # --- S2 max-num-seqs ------------------------------------------------------
    for v in "${SEQS_VALUES[@]:1}"; do
      budget_exceeded && { STOP_REQUESTED=1; return; }
      run_config "$mkey" "$a_util" "$a_len" "$v" "$a_batched" "$a_lmonly"; cand="$RUN_METRIC"
      # For single-user latency we keep seqs=1 as anchor unless a higher value
      # does not regress decode; we still record all. Keep best decode.
      if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; a_seqs="$v"; fi
    done
    log "  S2 best seqs=$a_seqs (decode=$best)"

    # --- S3 max-model-len -----------------------------------------------------
    for v in "${LEN_VALUES[@]:1}"; do
      budget_exceeded && { STOP_REQUESTED=1; return; }
      run_config "$mkey" "$a_util" "$v" "$a_seqs" "$a_batched" "$a_lmonly"; cand="$RUN_METRIC"
      # Prefer larger context when decode is within ~5% of best.
      if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>=b*0.95 && c>0)}'; then
        if (( v > a_len )); then a_len="$v"; fi
        if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; fi
      fi
    done
    log "  S3 chosen len=$a_len (decode=$best)"

    # --- S4 gpu-memory-utilization -------------------------------------------
    for v in "${UTIL_VALUES[@]:1}"; do
      budget_exceeded && { STOP_REQUESTED=1; return; }
      run_config "$mkey" "$v" "$a_len" "$a_seqs" "$a_batched" "$a_lmonly"; cand="$RUN_METRIC"
      if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; a_util="$v"; fi
    done
    log "  S4 best util=$a_util (decode=$best)"

    # --- S5 language-model-only off (multimodal only) -------------------------
    if [[ "$mm" == "1" ]]; then
      budget_exceeded && { STOP_REQUESTED=1; return; }
      run_config "$mkey" "$a_util" "$a_len" "$a_seqs" "$a_batched" "off" || true
      log "  S5 recorded language-model-only=off for comparison"
    fi
  else
    # --- quick tier: anchor + two light datapoints, then straight to S6 -------
    budget_exceeded && { STOP_REQUESTED=1; return; }
    run_config "$mkey" "$a_util" "$a_len" "${SEQS_VALUES[1]}" "$a_batched" "$a_lmonly"; cand="$RUN_METRIC"
    if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; a_seqs="${SEQS_VALUES[1]}"; fi
    budget_exceeded && { STOP_REQUESTED=1; return; }
    run_config "$mkey" "$a_util" "$a_len" "$a_seqs" "${BATCHED_VALUES[1]}" "$a_lmonly"; cand="$RUN_METRIC"
    if awk -v c="$cand" -v b="$best" 'BEGIN{exit !(c>b)}'; then best="$cand"; a_batched="${BATCHED_VALUES[1]}"; fi
    log "  [quick] anchor+2 done (seqs=$a_seqs batched=$a_batched decode=$best)"
  fi

  # --- S6 context-ceiling probe (both tiers) ----------------------------------
  # Climb max-model-len through CEIL_LADDER (<= the model's native M_CEIL, and
  # above the already-chosen len) at the tuned util/seqs/batched/lm, stopping at
  # the first kv-too-small/failure. The largest len that still reaches `ok` is the
  # model's max usable context (derived in the report from status==ok configs).
  local ceil; ceil="$(model_opt M_CEIL "$mkey" 262144)"
  log "  S6 context-ceiling probe (cap=${ceil}, from len>$a_len)"
  for v in "${CEIL_LADDER[@]}"; do
    (( v > a_len )) || continue
    (( v <= ceil )) || continue
    budget_exceeded && { STOP_REQUESTED=1; return; }
    run_config "$mkey" "$a_util" "$v" "$a_seqs" "$a_batched" "$a_lmonly"; cand="$RUN_METRIC"
    # Stop climbing on the first failure — higher lens can only fail harder.
    if awk -v x="$cand" 'BEGIN{exit !(x<0)}'; then
      log "  S6 ceiling reached: len=$v did not fit (stopping climb)"
      break
    fi
    a_len="$v"
  done
  log "  S6 max usable len for $mkey ≈ $a_len"

  log "=== model $mkey complete — best: util=$a_util len=$a_len seqs=$a_seqs batched=$a_batched lm=$a_lmonly decode=$best ==="
}

# -----------------------------------------------------------------------------
# Results aggregation
# -----------------------------------------------------------------------------
generate_results() {
  local md="$RUN_DIR/RESULTS.md" csv="$RUN_DIR/RESULTS.csv"
  log "Generating results -> $md"

  # Collect all result.json into one array.
  local all; all="$(find "$RUN_DIR" -name result.json -print0 2>/dev/null | xargs -0 cat 2>/dev/null | jq -s '.' 2>/dev/null || echo '[]')"

  echo "model,config_id,status,util,max_model_len,max_num_seqs,max_num_batched_tokens,language_model_only,kv_cache_tokens,ttft_p50_ms,ttft_p99_ms,tpot_p50_ms,decode_toks_per_s,output_throughput,e2e_p50_ms,c2_tpot_p50_ms,c2_agg_toks_per_s,c2_output_throughput,c4_tpot_p50_ms,c4_agg_toks_per_s,c4_output_throughput,reason" >"$csv"
  jq -r '.[] | [.model,.config_id,.status,(.config.gpu_memory_utilization),(.config.max_model_len),
                (.config.max_num_seqs),(.config.max_num_batched_tokens),(.config.language_model_only),
                (.capacity.kv_cache_tokens),(.latency_c1.ttft_p50_ms),(.latency_c1.ttft_p99_ms),
                (.latency_c1.tpot_p50_ms),(.latency_c1.decode_toks_per_s),(.latency_c1.output_throughput),
                (.latency_c1.e2e_p50_ms),
                (.latency_concurrency.c2.tpot_p50_ms),(.latency_concurrency.c2.agg_decode_toks_per_s),(.latency_concurrency.c2.output_throughput),
                (.latency_concurrency.c4.tpot_p50_ms),(.latency_concurrency.c4.agg_decode_toks_per_s),(.latency_concurrency.c4.output_throughput),
                .reason] | @csv' <<<"$all" >>"$csv" 2>/dev/null || true

  {
    local gpu_desc="GPU $GPUS_LIST"
    (( TP >= 2 )) && gpu_desc="GPUs $GPUS_LIST (TP=$TP, NVLink=${NVLINK_PRESENT:-n/a})"
    echo "# vLLM tuning sweep — results ($RUN_TS)"
    echo
    echo "- Host: orion, $gpu_desc, image \`$IMAGE\`"
    echo "- Objective: single-user coding latency (concurrency 1; in=4096, out=512) + max usable context"
    echo "- TTFT budget for 'winner' eligibility: ${TTFT_BUDGET_MS} ms (median)"
    echo "- Models: $MODELS"
    echo
    echo "## Winner (highest decode tok/s within TTFT budget, larger context wins ties)"
    echo
    local winner
    winner="$(jq -r --argjson budget "$TTFT_BUDGET_MS" '
      [ .[] | select(.status=="ok" and .latency_c1.decode_toks_per_s!=null
                     and .latency_c1.ttft_p50_ms!=null
                     and (.latency_c1.ttft_p50_ms <= $budget)) ]
      | sort_by([ -.latency_c1.decode_toks_per_s, -(.config.max_model_len) ])
      | .[0] // empty
      | if . == null then "none" else
        "**\(.model)** — `\(.config_id)`  \n"
        + "- decode: **\(.latency_c1.decode_toks_per_s) tok/s**, TTFT p50: \(.latency_c1.ttft_p50_ms) ms, TPOT p50: \(.latency_c1.tpot_p50_ms) ms\n"
        + "- config: util=\(.config.gpu_memory_utilization), max-model-len=\(.config.max_model_len), max-num-seqs=\(.config.max_num_seqs), max-num-batched-tokens=\(.config.max_num_batched_tokens), language-model-only=\(.config.language_model_only)\n"
        + "- KV cache: \(.capacity.kv_cache_tokens) tokens, max concurrency: \(.capacity.max_concurrency)"
        end' <<<"$all" 2>/dev/null)"
    echo "${winner:-_no successful config met the TTFT budget — see full table below._}"
    echo
    echo "## Max usable context per model (S6 ceiling probe)"
    echo
    echo "Largest \`max-model-len\` that still reached \`ok\` per model, with the KV pool and"
    echo "max-concurrency at that length. The first larger length that failed (\`kv-too-small\`)"
    echo "is in the Failed/pruned table below."
    echo
    echo "| model | max usable ctx | KV cache tokens | max concurrency | decode tok/s @ that ctx |"
    echo "|---|---:|---:|---:|---:|"
    jq -r '
      [ .[] | select(.status=="ok") ] | group_by(.model)
      | map( (max_by(.config.max_model_len)) as $top
             | {model:$top.model, len:$top.config.max_model_len,
                kv:$top.capacity.kv_cache_tokens, conc:$top.capacity.max_concurrency,
                dec:$top.latency_c1.decode_toks_per_s} )
      | sort_by(-.len) | .[]
      | "| \(.model) | \(.len) | \(.kv // "-") | \(.conc // "-") | \(.dec // "-") |"' \
      <<<"$all" 2>/dev/null
    echo

    # --- Quant A/B comparison (matched family, different quant/prune) ----------
    if (( ${#M_AB[@]} > 0 )); then
      echo "## Quant A/B comparison"
      echo
      echo "Each pair is the same model family at a different quant/prune. Rows show the"
      echo "best \`ok\` config (highest decode within the TTFT budget) and the max usable context."
      echo
      echo "| baseline → variant | best decode tok/s | TTFT p50 ms | best ctx | max usable ctx |"
      echo "|---|---:|---:|---:|---:|"
      local _k _p
      _abrow() {  # $1 model-key -> one markdown row body (decode|ttft|ctx|maxctx) for that model
        jq -r --arg m "$1" --argjson budget "$TTFT_BUDGET_MS" '
          [ .[] | select(.model==$m and .status=="ok" and .latency_c1.decode_toks_per_s!=null) ] as $ok
          | ( ( [ $ok[] | select(.latency_c1.ttft_p50_ms!=null and .latency_c1.ttft_p50_ms<=$budget) ]
                | sort_by(-.latency_c1.decode_toks_per_s) | .[0] )
              // ( $ok | sort_by(-.latency_c1.decode_toks_per_s) | .[0] ) ) as $best
          | ( [ $ok[].config.max_model_len ] | max ) as $maxlen
          | if $best==null then "- | - | - | -"
            else "\($best.latency_c1.decode_toks_per_s) | \($best.latency_c1.ttft_p50_ms) | \($best.config.max_model_len) | \($maxlen // "-")" end' \
          <<<"$all" 2>/dev/null
      }
      for _k in "${!M_AB[@]}"; do
        _p="${M_AB[$_k]}"
        echo "| \`$_k\` → \`$_p\` (baseline) | $(_abrow "$_k") |"
        echo "| \`$_k\` → \`$_p\` (variant) | $(_abrow "$_p") |"
      done
      echo
    fi

    echo "## All configs (successful, ranked by decode tok/s)"
    echo
    echo "| model | config | decode tok/s | TTFT p50 ms | TPOT p50 ms | out tok/s | ctx | seqs | batched | lm-only | KV tokens |"
    echo "|---|---|---:|---:|---:|---:|---:|---:|---:|:---:|---:|"
    jq -r '
      [ .[] | select(.status=="ok" and .latency_c1.decode_toks_per_s!=null) ]
      | sort_by(-.latency_c1.decode_toks_per_s) | .[]
      | "| \(.model) | \(.config_id) | \(.latency_c1.decode_toks_per_s) | \(.latency_c1.ttft_p50_ms) | \(.latency_c1.tpot_p50_ms) | \(.latency_c1.output_throughput) | \(.config.max_model_len) | \(.config.max_num_seqs) | \(.config.max_num_batched_tokens) | \(.config.language_model_only) | \(.capacity.kv_cache_tokens // "-") |"' \
      <<<"$all" 2>/dev/null
    echo
    echo "## Concurrency scaling (c1 → c2 → c4)"
    echo
    echo "Aggregate decode throughput at concurrency 1, 2, and 4. Picks the highest-seqs"
    echo "\`ok\` config per model (most KV headroom for batching). c2/c4 TPOT is per-request;"
    echo "agg tok/s = concurrency × (1000 / TPOT p50 ms)."
    echo
    echo "| model | seqs | c1 decode tok/s | c2 agg tok/s | c2 TPOT ms | c4 agg tok/s | c4 TPOT ms |"
    echo "|---|---:|---:|---:|---:|---:|---:|"
    jq -r '
      [ .[] | select(.status=="ok") ] | group_by(.model)
      | map( (max_by(.config.max_num_seqs)) as $top
             | {model:$top.model, seqs:$top.config.max_num_seqs,
                c1:$top.latency_c1.decode_toks_per_s,
                c2agg:$top.latency_concurrency.c2.agg_decode_toks_per_s,
                c2tpot:$top.latency_concurrency.c2.tpot_p50_ms,
                c4agg:$top.latency_concurrency.c4.agg_decode_toks_per_s,
                c4tpot:$top.latency_concurrency.c4.tpot_p50_ms} )
      | sort_by(-.c1) | .[]
      | "| \(.model) | \(.seqs // "-") | \(.c1 // "-") | \(.c2agg // "-") | \(.c2tpot // "-") | \(.c4agg // "-") | \(.c4tpot // "-") |"' \
      <<<"$all" 2>/dev/null
    echo

    echo "## Failed / pruned configs"
    echo
    echo "| model | config | status | reason |"
    echo "|---|---|---|---|"
    jq -r '.[] | select(.status!="ok") | "| \(.model) | \(.config_id) | \(.status) | \(.reason) |"' <<<"$all" 2>/dev/null
    echo
    echo "_Raw per-config artifacts (server.log, bench_*.json, validation.json, metrics) are under \`$RUN_DIR/<model>/<config>/\`._"
  } >"$md"

  log "Results written: $md and $csv"
}

# -----------------------------------------------------------------------------
# Preflight + main
# -----------------------------------------------------------------------------
write_abort_report() {
  mkdir -p "$RUN_DIR"
  {
    echo "# vLLM sweep aborted ($RUN_TS)"
    echo
    echo "GPU(s) [$GPUS_LIST] were not all free at start (used: $(gpus_used_summary) MiB,"
    echo "threshold ${FREE_THRESHOLD_MIB} MiB). The sweep only runs when every target GPU is free."
    echo
    echo "Current GPU state:"
    echo '```'
    nvidia-smi --query-gpu=index,name,memory.used,memory.free,utilization.gpu --format=csv 2>&1 || true
    echo '```'
    echo
    echo "To run: free GPU(s) [$GPUS_LIST] (stop the vllm stack), then re-launch,"
    echo "or launch with \`--wait-for-free <minutes>\`."
  } >"$RUN_DIR/ABORTED.md"
  log "GPU(s) [$GPUS_LIST] not free — abort report at $RUN_DIR/ABORTED.md"
}

# Pre-pull model weights into the hf-cache volume (no GPU needed) so the timed
# sweep never hits READY_TIMEOUT mid-download. Lesson from a prior run where
# uncached large models timed out every config.
prepull_models() {
  log "Pre-pulling model weights into hf-cache (CPU-only; no GPU pinned)"
  local mkey repo img
  for mkey in $MODELS; do
    repo="${M_REPO[$mkey]:-}"
    [[ -n "$repo" ]] || { warn "  unknown model key: $mkey — skipping pull"; continue; }
    img="$(model_opt M_IMAGE "$mkey" "$IMAGE")"
    log "  [pull] $mkey -> $repo"
    if (( DRY_RUN == 1 )); then continue; fi
    docker run --rm \
      -v hf-cache:/root/.cache/huggingface \
      -e "HUGGING_FACE_HUB_TOKEN=${HF_TOKEN_VAL}" \
      --entrypoint bash "$img" -lc \
      "hf download '$repo' 2>/dev/null || huggingface-cli download '$repo'" \
      2>&1 | sed 's/^/      /' || warn "  pull failed for $repo (launch will retry)"
  done
  log "Pre-pull complete"
}

main() {
  mkdir -p "$RUN_DIR"
  log "vLLM sweep run $RUN_TS"
  log "run-dir: $RUN_DIR | gpus: [$GPUS_LIST] | tp: $TP | port: $HOST_PORT | models: $MODELS | dry-run: $DRY_RUN | smoke: $SMOKE | prepull: $PREPULL"

  # Resolve topology (NVLink) once — affects engine args + NCCL env for TP>=2.
  detect_nvlink

  # Pre-pull mode: download weights, then exit (no GPU work).
  if (( PREPULL == 1 )); then
    prepull_models
    log "PREPULL COMPLETE — re-run without --prepull to start the sweep."
    return
  fi

  if (( DRY_RUN == 0 )); then
    if ! gpu_is_free; then
      if (( WAIT_FOR_FREE > 0 )); then
        log "GPU(s) [$GPUS_LIST] busy (used: $(gpus_used_summary) MiB) — waiting up to ${WAIT_FOR_FREE} min"
        local deadline=$((SECONDS + WAIT_FOR_FREE*60))
        while ! gpu_is_free; do
          (( SECONDS < deadline )) || { write_abort_report; exit 0; }
          sleep 30
        done
      else
        write_abort_report; exit 0
      fi
    fi
    log "GPU(s) [$GPUS_LIST] free (used: $(gpus_used_summary) MiB) — starting sweep"
    docker network inspect "$NETWORK" >/dev/null 2>&1 || warn "network '$NETWORK' not found — containers may fail to attach"
  fi

  for mkey in $MODELS; do
    budget_exceeded && { log "time budget (${MAX_HOURS}h) reached — stopping before $mkey"; break; }
    (( STOP_REQUESTED == 1 )) && { log "stop requested (budget) — halting model loop"; break; }
    if (( ${#EXPLICIT_CONFIGS[@]} > 0 )); then
      for spec in "${EXPLICIT_CONFIGS[@]}"; do
        budget_exceeded && { log "time budget reached — stopping explicit configs"; break; }
        (( STOP_REQUESTED == 1 )) && break
        IFS=: read -r c_util c_len c_seqs c_batched c_lmonly <<<"$spec"
        if [[ -z "$c_util" || -z "$c_len" || -z "$c_seqs" || -z "$c_batched" || -z "$c_lmonly" ]]; then
          warn "  bad --config '$spec' (need UTIL:LEN:SEQS:BATCHED:LMONLY) — skipping"; continue
        fi
        log "=== explicit config $mkey: util=$c_util len=$c_len seqs=$c_seqs batched=$c_batched lm=$c_lmonly ==="
        run_config "$mkey" "$c_util" "$c_len" "$c_seqs" "$c_batched" "$c_lmonly"
      done
    else
      sweep_model "$mkey"
    fi
  done

  if (( DRY_RUN == 0 )); then
    generate_results
    log "SWEEP COMPLETE. Report: $RUN_DIR/RESULTS.md"
  else
    log "DRY RUN COMPLETE (no containers launched)."
  fi
}

main "$@"
