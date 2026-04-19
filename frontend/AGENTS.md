# Repository Guidelines

## Project Structure & Module Organization
This package is the OpenProject frontend workspace. Main application code lives in `src/app/` (legacy Angular features, shared UI, and core services). Newer UI layers are split across `src/react/`, `src/stimulus/`, and `src/turbo/`. Static assets and styling live in `src/assets/` and `src/global_styles/`. Locale files are in `src/locales/`, custom elements in `src/elements/`, and test helpers in `src/test/`. Keep tests close to the code they verify, for example `src/app/.../widget.service.spec.ts`.

## Build, Test, and Development Commands
Run commands from `frontend/`.

- `pnpm install`: install dependencies with the repo-standard package manager.
- `pnpm serve`: start the Angular dev server on `localhost:4200`.
- `pnpm build`: create a production frontend build.
- `pnpm build:watch`: rebuild continuously while developing assets.
- `pnpm test`: run Jasmine unit tests once through Karma.
- `pnpm test:watch`: re-run frontend tests on file changes.
- `pnpm lint`: run ESLint across TypeScript, templates, and specs.
- `pnpm lint:fix`: apply safe lint fixes.
- `pnpm generate-typings`: regenerate TypeScript declaration output.

If frontend assets fail in the full app, rerun `bin/setup_dev` from the monorepo root.

## Coding Style & Naming Conventions
Follow the root `.editorconfig`: UTF-8, LF endings, and 2-space indentation. ESLint is the source of truth for TypeScript, HTML templates, and Jasmine specs. Use single quotes and semicolons. Prefix intentionally unused variables with `_` to satisfy lint rules.

Angular selectors are enforced:
- Components: kebab-case elements with `op-` or `opce-` prefixes.
- Directives: camelCase attributes with `op` or `opce` prefixes.
- Component classes should end in `Component`.

## Testing Guidelines
Frontend tests use Jasmine with Karma. Name tests `*.spec.ts` and place them beside the implementation. Cover behavior changes, regressions, and edge cases introduced by your patch. Run `pnpm test` before opening a PR and `pnpm lint` for any TS, HTML, or React changes.

## Commit & Pull Request Guidelines
Recent history favors short, imperative commit subjects focused on one change, for example `Migrate npm workflows to pnpm`. Keep the first line concise, ideally under 72 characters, and add details in the body when context matters.

PRs should include a clear summary, linked issue or work package when applicable, and test notes. Add screenshots or short recordings for visible UI changes, and call out locale, asset, or configuration updates explicitly.

