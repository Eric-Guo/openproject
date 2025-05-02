# OpenProject AI Coding Agent Instructions

> **Note for developers**: You can create `AGENTS.local.md` (or `CLAUDE.local.md`) in this directory to add your own custom instructions or preferences for AI coding agents. These files are git-ignored and will not be committed to the repository.

## Repository Overview

**OpenProject** is a web-based, open-source project management software written in Ruby on Rails with PostgreSQL for data persistence.

- **Size**: Large monorepo (~840MB, ~1M+ lines of code)
- **Backend**: Ruby 3.4.7, Rails ~8.0.3
- **Frontend**: Node.js 22.21.0, npm 10.1.0+, TypeScript
- **Database**: PostgreSQL (required)
- **Architecture**: Server-rendered HTML with Hotwire (Turbo + Stimulus). Legacy Angular components exist and are being migrated to custom elements. Uses GitHub's Primer Design System via ViewComponent.
- **Editions**: Community, Enterprise (SSO, LDAP, SCIM), and BIM (construction industry, code in `modules/bim/`)

## Critical Setup Requirements

**ALWAYS verify versions before building:**
- Ruby: `4.0.2` (see `.ruby-version`)
- Node: `^22.21.0` (see `package.json` engines)
- Bundler: Latest 2.x

OpenProject supports two development setups: **Local** and **Docker**. Choose one based on your preference.

### Local Development Setup

```bash
bundle install                    # Install Ruby gems
cd frontend && npm ci && cd ..   # Install Node packages
bundle exec rails db:migrate      # Setup database
bin/dev                          # Start all services (Rails, frontend, Good Job worker)
# Access at http://localhost:3000
```

### Docker Development Setup

The Docker development environment uses configurations in `docker/dev/` and the `bin/compose` wrapper script.

```bash
# Initial setup (first time only)
bin/compose setup                         # Installs backend and frontend dependencies

# Starting services
bin/compose start                         # Start backend and frontend in background
bin/compose run                           # Start frontend in background, backend in foreground (for debugging with pry)

# Running tests
bin/compose rspec spec/models/user_spec.rb   # Run specific tests in backend-test container

# Other operations
bin/compose reset                         # Remove all containers and volumes (requires setup again)
bin/compose <command>                     # Pass any docker-compose command directly
```

**Important Docker Notes:**
- **CRITICAL**: `config/database.yml` must NOT exist when using Docker (rename or delete it)
- Most developers use a local `docker-compose.override.yml` for custom port mappings and configurations
- Copy `docker-compose.override.example.yml` to `docker-compose.override.yml` and customize as needed
- Default ports: Backend at http://localhost:3000 (or 4200 for frontend dev server)
- Services: `backend`, `frontend`, `worker`, `db`, `db-test`, `backend-test`, `cache`
- Persisted volumes: `pgdata`, `bundle`, `npm`, `tmp`, `opdata` (data survives container restarts)
- Docker build context: Uses Dockerfiles in `docker/dev/backend/` and `docker/dev/frontend/`

## Project Structure

### Key Directories
- `app/` - Rails application code
  - `app/components/` - ViewComponent-based UI components (Ruby + ERB)
  - `app/contracts/` - Validation and authorization contracts
  - `app/controllers/` - Rails controllers
  - `app/models/` - ActiveRecord models
  - `app/services/` - Service objects (business logic)
  - `app/workers/` - Background job workers
- `config/` - Rails configuration, routes, locales
- `db/` - Database migrations and seeds
- `frontend/src/` - Frontend code
  - `frontend/src/app/` - Legacy Angular modules/components
  - `frontend/src/stimulus/` - Stimulus controllers
  - `frontend/src/turbo/` - Turbo integration
- `lib/` - Ruby libraries and extensions
- `lookbook/` - ViewComponent previews (https://qa.openproject-edge.com/lookbook/)
- `modules/` - OpenProject plugin modules
- `spec/` - RSpec test suite
  - `spec/features/` - System/feature tests (Capybara)
  - `spec/models/` - Model unit tests
  - `spec/requests/` - API/integration tests
  - `spec/services/` - Service tests

### Configuration Files
- `.ruby-version` - Ruby version
- `.rubocop.yml` - Ruby linting rules
- `.erb_lint.yml` - ERB template linting
- `frontend/eslint.config.mjs` - JavaScript/TypeScript linting
- `Gemfile` - Ruby dependencies
- `package.json` / `frontend/package.json` - Node.js dependencies
- `lefthook.yml` - Git hooks configuration

## Building and Testing

### Linting (Run Before Committing)

```bash
# Ruby
bundle exec rubocop                              # Check all files
bin/dirty-rubocop --uncommitted                  # Check only uncommitted changes

# JavaScript/TypeScript
cd frontend && npx eslint src/ && cd ..

# ERB Templates
erb_lint {files}

# Install Git Hooks (recommended)
bundle exec lefthook install
```

### Running Tests

```bash
# Backend (RSpec) - prefer specific tests over running all
bundle exec rspec spec/models/user_spec.rb              # Single file
bundle exec rspec spec/models/user_spec.rb:42           # Single line
bundle exec rspec spec/features                         # Directory
bundle exec rake parallel:spec                          # Parallel execution

# Frontend (Jasmine/Karma)
cd frontend && npm test && cd ..
```

### Debugging CI Failures
```bash
./script/github_pr_errors | xargs bundle exec rspec    # Run failed tests from CI
./script/bulk_run_rspec spec/path/to/flaky_spec.rb     # Run tests multiple times
```

## Code Style Guidelines

### Ruby
- Follow [Ruby community style guide](https://github.com/bbatsov/ruby-style-guide)
- Use service objects for complex business logic (return `ServiceResult`)
- Use contracts for validation and authorization
- Keep controllers thin, models focused
- Document with [YARD](https://yardoc.org/)
- Write RSpec tests for all new features
- **Work package identifiers**: `WorkPackage.find("PROJ-42")` resolves semantic identifiers transparently. Use `find_by_display_id` only when input could legitimately be numeric OR semantic (controllers, URL-driven components, macro resolvers). Low-level code (queries, filters, services) should stick to `find_by(id:)` with primary keys. See `app/models/work_package/semantic_identifier/finder_methods.rb`.

### JavaScript/TypeScript
- **New development**: Use Hotwire (Turbo + Stimulus) with server-rendered HTML
- **Legacy code**: Follow ESLint rules
- Prefer TypeScript over JavaScript
- Use [Primer Design System](https://primer.style/product/) via ViewComponent

### Templates
- Use ERB for server-rendered views
- Use ViewComponents for reusable UI (with Lookbook previews)
- Lint with erb_lint before committing

### Database Migrations
- Follow Rails migration conventions
- Migrations are "squashed" between major releases (see `docs/development/migrations/`)

### Translations
- UI strings must use translation keys (never hard-coded)
- Source translations in `**/config/locales/en.yml` can be modified directly
- Other translations managed via Crowdin

### Commit Messages
- First line: < 72 characters, then blank line, then detailed description
- Reference work packages when applicable
- Merge strategy: "Merge pull request" (not squash), except single-commit PRs can use "Rebase and merge"

## Important Commands Reference

### Local Development Commands

```bash
# Setup
bin/setup              # Initial Rails setup
bin/setup_dev          # Full dev environment setup

# Database
bundle exec rails g migration MigrationName  # Generate a migration
bundle exec rails db:migrate                 # Run migrations
bundle exec rails db:rollback                # Rollback last migration
bundle exec rails db:seed                    # Seed sample data

# Development
bin/dev                                  # Start all services
bundle exec rails console                # Rails console
bundle exec rails routes                 # List routes

# Testing
bundle exec rspec                        # Run RSpec tests
bundle exec rails parallel:spec          # Parallel tests
cd frontend && npm test                  # Frontend tests

# Linting
bundle exec rubocop                      # Ruby linting
cd frontend && npx eslint src/           # JS/TS linting
erb_lint {files}                         # ERB linting
```

### Docker Development Commands

```bash
# Setup and lifecycle
bin/compose setup                        # Setup Docker environment (first time)
bin/compose start                        # Start all services in background
bin/compose run                          # Start frontend in background, backend in foreground
bin/compose reset                        # Remove all containers and volumes
bin/compose stop                         # Stop all services
bin/compose down                         # Stop and remove containers

# Testing
bin/compose rspec spec/models/user_spec.rb    # Run specific tests
bin/compose exec backend bundle exec rspec    # Run tests directly in backend container

# Development
bin/compose exec backend bundle exec rails console   # Rails console
bin/compose logs backend                 # View backend logs
bin/compose logs -f backend              # Follow backend logs
bin/compose ps                           # List running containers

# Database
bin/compose exec backend bundle exec rails db:migrate      # Run migrations
bin/compose exec backend bundle exec rails db:seed         # Seed data

# Direct docker-compose commands
bin/compose up -d                        # Start services
bin/compose restart backend              # Restart backend service
```

## Additional Documentation

- `docs/development/` - Development documentation
- `docs/development/running-tests/` - Testing guide
- `docs/development/code-review-guidelines/` - Code review standards
- `CONTRIBUTING.md` - Contribution workflow
- `.github/copilot-instructions.md` - Extended agent instructions with troubleshooting
