# Repository Guidelines

## Project Structure & Module Organization
OpenProject pairs a Rails 8 backend (`app/`) with an Angular workspace (`frontend/`). Shared helpers sit in `lib/`, automation scripts in `script/`, and optional feature packs live under `modules/*` with their own `app` and `spec` trees. Angular modules and design tokens live in `frontend/src/app`; compiled assets land in `public/`. Check `docs/` for architecture notes and `docker/` or `Procfile.dev` when you need ready-made environments.

## Build, Test, and Development Commands
- `bundle install && yarn install` — install Ruby and Node dependencies from the root.
- `bin/rails db:setup` — bootstrap the database schema and seeds.
- `bundle exec rails server -p 3000` — run the backend; use `yarn run serve` to mount the Angular dev shell alongside it.
- `bundle exec rspec` or `docker compose exec backend-test bundle exec rspec` — execute backend specs locally or inside the provided container.
- `cd frontend && yarn test` — launch Karma/Jasmine specs (`--watch` keeps them running).

## Coding Style & Naming Conventions
Ruby code uses two-space indentation and the `.rubocop.yml` rules; run `bin/dirty-rubocop --uncommitted` (or `bundle exec rubocop`) before you push. Keep classes and services inside namespaced directories that mirror their module path (e.g., `WorkPackages::Export::Csv`). Angular and TypeScript rely on ESLint with the Airbnb presets via `esprint`; name components `*.component.ts` and tests `*.spec.ts`.

## Testing Guidelines
Every feature needs RSpec coverage located next to the behaviour under test, using the `*_spec.rb` pattern. Targeted runs such as `bundle exec rspec spec/models/work_package_spec.rb` help keep feedback fast. Frontend changes belong in Angular specs and should pass `yarn test --watch=false`; update Lookbook previews (`lookbook/`) for notable UI adjustments.

## Commit & Pull Request Guidelines
Keep commit subjects short and imperative—recent history shows messages like `Fix 500.` and `Link to query page.`. Open pull requests against `dev`, include a short summary, test evidence, and links to related OpenProject work packages. UI work should come with screenshots or GIFs, and call out migrations or configuration changes in the description.

## Security & Configuration Tips
Store secrets in environment variables or `config/configuration.yml` overrides, never in Git; `docker-compose.override.example.yml` documents the expected keys. Review `SECURITY.md` before touching authentication, permissions, or integrations, and flag reviewers early for anything that could impact user data.
