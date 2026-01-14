// @ts-check

import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
	// TODO: Replace 'your-username' with your GitHub username
	site: 'https://your-username.github.io',
	// TODO: Replace 'your-repo-name' with your repository name (e.g., '/blog')
	// base: '/your-repo-name', 
	integrations: [mdx(), sitemap()],
});
