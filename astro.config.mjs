import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';

export default defineConfig({
  site: 'https://jrgns.net',
  // Applies to the plain-Markdown posts in src/content/blog. Dimmed keeps the
  // syntax colours from shouting against the muted "Dusk Slate" panel.
  markdown: {
    shikiConfig: {
      theme: 'github-dark-dimmed',
    },
  },
  integrations: [
    tailwind({
      content: {
        files: ['**/*.{md,mdx,astro}'],
      },
    }),
    sitemap(),
    mdx({
      shikiConfig: {
        theme: "github-dark-dimmed",
      },
    }),
  ],
  redirects: {
    '/content/22seven-com-folly-or-genius.html': '/archive/22seven-com-folly-or-genius',
    '/content/backend_100_revisions.html': '/archive/backend_100_revisions',
    '/content/backend-core-a-restful-mvc-php-framework.html': '/archive/backend-core-a-restful-mvc-php-framework',
    '/content/backend_intro.html': '/archive/backend_intro',
    '/content/building-php-projects-with-jenkins.html': '/archive/building-php-projects-with-jenkins',
    '/content/decorator-pattern-implemented-properly-in-php.html': '/archive/decorator-pattern-implemented-properly-in-php',
    '/content/firefox_requests_a_page_twice.html': '/archive/firefox_requests_a_page_twice',
    '/content/getting_started_with_node_js.html': '/archive/getting_started_with_node_js',
    '/content/good_developers_think_like_a_startup.html': '/archive/good_developers_think_like_a_startup',
    '/content/import_to_google_gears.html': '/archive/import_to_google_gears',
    '/content/js-trim.html': '/archive/js-trim',
    '/content/json-encode-ing-private-and-protected-properties.html': '/archive/json-encode-ing-private-and-protected-properties',
    '/content/my_take_on_single_or_multiple_returns.html': '/archive/my_take_on_single_or_multiple_returns',
    '/content/new_look.html': '/archive/new_look',
    '/content/node_parser_email.html': '/archive/node_parser_email',
    '/content/parse_http_accept_header.html': '/archive/parse_http_accept_header',
    '/content/php-community-in-south-africa-lack-thereof.html': '/archive/php-community-in-south-africa-lack-thereof',
    '/content/php-virtualhost.html': '/archive/php-virtualhost',
    '/content/quick_guide_to_creating_a_website_quickly.html': '/archive/quick_guide_to_creating_a_website_quickly',
    '/content/redirect_request_to_index.html': '/archive/redirect_request_to_index',
    '/content/redirect_request_to_index/index.html': '/archive/redirect_request_to_index',
    '/content/remove_www_from_url.html': '/archive/remove_www_from_url',
    '/content/setting-up-puppet-on-ubuntu-10.4.html': '/archive/setting-up-puppet-on-ubuntu-10.4',
    '/content/sqllite_view.html': '/archive/sqllite_view',
    '/content/the-low-hanging-fruit-of-testing.html': '/archive/the-low-hanging-fruit-of-testing',
    '/content/twitter_api_request_entity_too_large_http_413_error.html': '/archive/twitter_api_request_entity_too_large_http_413_error',
    '/content/Update on Backend.html': '/archive/update-on-backend',
    '/content/why_i_code.html': '/archive/why_i_code',
    '/content/why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad.html': '/archive/why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad',
    '/content/why_oo_is_great.html': '/archive/why_oo_is_great',
    // The vLLM sweep post briefly lived at /archive/ before the /blog/ split.
    '/archive/vllm-sweep-setup-and-aim': '/blog/vllm-sweep-setup-and-aim',
  },
});
