declare module 'astro:content' {
	interface Render {
		'.mdx': Promise<{
			Content: import('astro').MarkdownInstance<{}>['Content'];
			headings: import('astro').MarkdownHeading[];
			remarkPluginFrontmatter: Record<string, any>;
			components: import('astro').MDXInstance<{}>['components'];
		}>;
	}
}

declare module 'astro:content' {
	interface RenderResult {
		Content: import('astro/runtime/server/index.js').AstroComponentFactory;
		headings: import('astro').MarkdownHeading[];
		remarkPluginFrontmatter: Record<string, any>;
	}
	interface Render {
		'.md': Promise<RenderResult>;
	}

	export interface RenderedContent {
		html: string;
		metadata?: {
			imagePaths: Array<string>;
			[key: string]: unknown;
		};
	}
}

declare module 'astro:content' {
	type Flatten<T> = T extends { [K: string]: infer U } ? U : never;

	export type CollectionKey = keyof AnyEntryMap;
	export type CollectionEntry<C extends CollectionKey> = Flatten<AnyEntryMap[C]>;

	export type ContentCollectionKey = keyof ContentEntryMap;
	export type DataCollectionKey = keyof DataEntryMap;

	type AllValuesOf<T> = T extends any ? T[keyof T] : never;
	type ValidContentEntrySlug<C extends keyof ContentEntryMap> = AllValuesOf<
		ContentEntryMap[C]
	>['slug'];

	/** @deprecated Use `getEntry` instead. */
	export function getEntryBySlug<
		C extends keyof ContentEntryMap,
		E extends ValidContentEntrySlug<C> | (string & {}),
	>(
		collection: C,
		// Note that this has to accept a regular string too, for SSR
		entrySlug: E,
	): E extends ValidContentEntrySlug<C>
		? Promise<CollectionEntry<C>>
		: Promise<CollectionEntry<C> | undefined>;

	/** @deprecated Use `getEntry` instead. */
	export function getDataEntryById<C extends keyof DataEntryMap, E extends keyof DataEntryMap[C]>(
		collection: C,
		entryId: E,
	): Promise<CollectionEntry<C>>;

	export function getCollection<C extends keyof AnyEntryMap, E extends CollectionEntry<C>>(
		collection: C,
		filter?: (entry: CollectionEntry<C>) => entry is E,
	): Promise<E[]>;
	export function getCollection<C extends keyof AnyEntryMap>(
		collection: C,
		filter?: (entry: CollectionEntry<C>) => unknown,
	): Promise<CollectionEntry<C>[]>;

	export function getEntry<
		C extends keyof ContentEntryMap,
		E extends ValidContentEntrySlug<C> | (string & {}),
	>(entry: {
		collection: C;
		slug: E;
	}): E extends ValidContentEntrySlug<C>
		? Promise<CollectionEntry<C>>
		: Promise<CollectionEntry<C> | undefined>;
	export function getEntry<
		C extends keyof DataEntryMap,
		E extends keyof DataEntryMap[C] | (string & {}),
	>(entry: {
		collection: C;
		id: E;
	}): E extends keyof DataEntryMap[C]
		? Promise<DataEntryMap[C][E]>
		: Promise<CollectionEntry<C> | undefined>;
	export function getEntry<
		C extends keyof ContentEntryMap,
		E extends ValidContentEntrySlug<C> | (string & {}),
	>(
		collection: C,
		slug: E,
	): E extends ValidContentEntrySlug<C>
		? Promise<CollectionEntry<C>>
		: Promise<CollectionEntry<C> | undefined>;
	export function getEntry<
		C extends keyof DataEntryMap,
		E extends keyof DataEntryMap[C] | (string & {}),
	>(
		collection: C,
		id: E,
	): E extends keyof DataEntryMap[C]
		? Promise<DataEntryMap[C][E]>
		: Promise<CollectionEntry<C> | undefined>;

	/** Resolve an array of entry references from the same collection */
	export function getEntries<C extends keyof ContentEntryMap>(
		entries: {
			collection: C;
			slug: ValidContentEntrySlug<C>;
		}[],
	): Promise<CollectionEntry<C>[]>;
	export function getEntries<C extends keyof DataEntryMap>(
		entries: {
			collection: C;
			id: keyof DataEntryMap[C];
		}[],
	): Promise<CollectionEntry<C>[]>;

	export function render<C extends keyof AnyEntryMap>(
		entry: AnyEntryMap[C][string],
	): Promise<RenderResult>;

	export function reference<C extends keyof AnyEntryMap>(
		collection: C,
	): import('astro/zod').ZodEffects<
		import('astro/zod').ZodString,
		C extends keyof ContentEntryMap
			? {
					collection: C;
					slug: ValidContentEntrySlug<C>;
				}
			: {
					collection: C;
					id: keyof DataEntryMap[C];
				}
	>;
	// Allow generic `string` to avoid excessive type errors in the config
	// if `dev` is not running to update as you edit.
	// Invalid collection names will be caught at build time.
	export function reference<C extends string>(
		collection: C,
	): import('astro/zod').ZodEffects<import('astro/zod').ZodString, never>;

	type ReturnTypeOrOriginal<T> = T extends (...args: any[]) => infer R ? R : T;
	type InferEntrySchema<C extends keyof AnyEntryMap> = import('astro/zod').infer<
		ReturnTypeOrOriginal<Required<ContentConfig['collections'][C]>['schema']>
	>;

	type ContentEntryMap = {
		"blog": {
"22seven-com-folly-or-genius.md": {
	id: "22seven-com-folly-or-genius.md";
  slug: "22seven-com-folly-or-genius";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"backend-100-revisions.md": {
	id: "backend-100-revisions.md";
  slug: "backend-100-revisions";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"backend-core-a-restful-mvc-php-framework.md": {
	id: "backend-core-a-restful-mvc-php-framework.md";
  slug: "backend-core-a-restful-mvc-php-framework";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"backend-intro.md": {
	id: "backend-intro.md";
  slug: "backend-intro";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"building-php-projects-with-jenkins.md": {
	id: "building-php-projects-with-jenkins.md";
  slug: "building-php-projects-with-jenkins";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"decorator-pattern-implemented-properly-in-php.md": {
	id: "decorator-pattern-implemented-properly-in-php.md";
  slug: "decorator-pattern-implemented-properly-in-php";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"diy-dynamic-dns-using-cloudflare.md": {
	id: "diy-dynamic-dns-using-cloudflare.md";
  slug: "diy-dynamic-dns-using-cloudflare";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"firefox-requests-a-page-twice.md": {
	id: "firefox-requests-a-page-twice.md";
  slug: "firefox-requests-a-page-twice";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"getting-started-with-node-js.md": {
	id: "getting-started-with-node-js.md";
  slug: "getting-started-with-node-js";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"good-developers-think-like-a-startup.md": {
	id: "good-developers-think-like-a-startup.md";
  slug: "good-developers-think-like-a-startup";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"im-the-most-organized-disorganized-person-youll-meet.md": {
	id: "im-the-most-organized-disorganized-person-youll-meet.md";
  slug: "im-the-most-organized-disorganized-person-youll-meet";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"import-to-google-gears.md": {
	id: "import-to-google-gears.md";
  slug: "import-to-google-gears";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"is-php-the-slums-of-the-programming-world.md": {
	id: "is-php-the-slums-of-the-programming-world.md";
  slug: "is-php-the-slums-of-the-programming-world";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"js-trim.md": {
	id: "js-trim.md";
  slug: "js-trim";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"json-encode-ing-private-and-protected-properties.md": {
	id: "json-encode-ing-private-and-protected-properties.md";
  slug: "json-encode-ing-private-and-protected-properties";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"logstash-config-guide.md": {
	id: "logstash-config-guide.md";
  slug: "logstash-config-guide";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"ms-sql-stored-procs-with-output-variables-in-sequel.md": {
	id: "ms-sql-stored-procs-with-output-variables-in-sequel.md";
  slug: "ms-sql-stored-procs-with-output-variables-in-sequel";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"my-take-on-single-or-multiple-returns.md": {
	id: "my-take-on-single-or-multiple-returns.md";
  slug: "my-take-on-single-or-multiple-returns";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"new-look.md": {
	id: "new-look.md";
  slug: "new-look";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"node-parser-email.md": {
	id: "node-parser-email.md";
  slug: "node-parser-email";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"parse-http-accept-header.md": {
	id: "parse-http-accept-header.md";
  slug: "parse-http-accept-header";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"php-array-merge-recursive-function-explained.md": {
	id: "php-array-merge-recursive-function-explained.md";
  slug: "php-array-merge-recursive-function-explained";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"php-community-in-south-africa-lack-thereof.md": {
	id: "php-community-in-south-africa-lack-thereof.md";
  slug: "php-community-in-south-africa-lack-thereof";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"php-virtualhost.md": {
	id: "php-virtualhost.md";
  slug: "php-virtualhost";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"populate-form-with-referring-entity-symfony.md": {
	id: "populate-form-with-referring-entity-symfony.md";
  slug: "populate-form-with-referring-entity-symfony";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"prepopulating-entity-in-symfony-2-form.md": {
	id: "prepopulating-entity-in-symfony-2-form.md";
  slug: "prepopulating-entity-in-symfony-2-form";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"quick-guide-to-creating-a-website-quickly.md": {
	id: "quick-guide-to-creating-a-website-quickly.md";
  slug: "quick-guide-to-creating-a-website-quickly";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"redirect-request-to-index.md": {
	id: "redirect-request-to-index.md";
  slug: "redirect-request-to-index";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"remove-www-from-url.md": {
	id: "remove-www-from-url.md";
  slug: "remove-www-from-url";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"setting-a-default-order-for-doctrine-symfony-2.md": {
	id: "setting-a-default-order-for-doctrine-symfony-2.md";
  slug: "setting-a-default-order-for-doctrine-symfony-2";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"setting-up-puppet-on-ubuntu-10-4.md": {
	id: "setting-up-puppet-on-ubuntu-10-4.md";
  slug: "setting-up-puppet-on-ubuntu-10-4";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"setting-up-the-swiftmailer-spooler.md": {
	id: "setting-up-the-swiftmailer-spooler.md";
  slug: "setting-up-the-swiftmailer-spooler";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"sqllite-view.md": {
	id: "sqllite-view.md";
  slug: "sqllite-view";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"summary-of-symfony-2-authorization.md": {
	id: "summary-of-symfony-2-authorization.md";
  slug: "summary-of-symfony-2-authorization";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"the-low-hanging-fruit-of-testing.md": {
	id: "the-low-hanging-fruit-of-testing.md";
  slug: "the-low-hanging-fruit-of-testing";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"twitter-api-request-entity-too-large-http-413-error.md": {
	id: "twitter-api-request-entity-too-large-http-413-error.md";
  slug: "twitter-api-request-entity-too-large-http-413-error";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"update-on-backend.md": {
	id: "update-on-backend.md";
  slug: "update-on-backend";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"why-i-code.md": {
	id: "why-i-code.md";
  slug: "why-i-code";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad.md": {
	id: "why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad.md";
  slug: "why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
"why-oo-is-great.md": {
	id: "why-oo-is-great.md";
  slug: "why-oo-is-great";
  body: string;
  collection: "blog";
  data: InferEntrySchema<"blog">
} & { render(): Render[".md"] };
};
"writing": Record<string, {
  id: string;
  slug: string;
  body: string;
  collection: "writing";
  data: InferEntrySchema<"writing">;
  render(): Render[".md"];
}>;

	};

	type DataEntryMap = {
		
	};

	type AnyEntryMap = ContentEntryMap & DataEntryMap;

	export type ContentConfig = typeof import("../../src/content/config.js");
}
