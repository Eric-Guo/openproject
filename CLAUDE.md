# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

### Development Setup
```bash
# One-time setup: Install dependencies and prepare databases
./bin/setup_dev

# Start all development services (Rails, Angular, worker)
bin/dev

# Or start services manually:
# Terminal 1: Rails server
RAILS_ENV=development bin/rails server

# Terminal 2: Angular dev server
npm run serve

# Terminal 3: Background worker
RAILS_ENV=development bundle exec good_job start
```

### Running Tests

#### Frontend (Angular)
```bash
# Run all frontend tests
npm test

# Watch mode for TDD
npm run test:watch

# Run specific test file
cd frontend && ng test --watch=false --include='**/work-package.service.spec.ts'
```

#### Backend (Rails/Rspec)
```bash
# Run single spec
RAILS_ENV=test bundle exec rspec spec/models/work_package_spec.rb

# Run multiple specs
RAILS_ENV=test bundle exec rspec spec/models/work_package_spec.rb spec/models/project_spec.rb

# Run all feature tests
RAILS_ENV=test bundle exec rake parallel:spec

# Run specific module tests
RAILS_ENV=test bundle exec parallel_rspec -- modules/team_planner/spec

# Extract and run failing tests from CI
./script/github_pr_errors | xargs bundle exec rspec
```

#### Running Tests with Debug
```bash
# Run tests with browser visible (for system tests)
OPENPROJECT_TESTING_NO_HEADLESS=1 RAILS_ENV=test bundle exec rspec spec/features/work_packages_spec.rb

# Slow down browser interactions (helpful for debugging)
OPENPROJECT_TESTING_SLOWDOWN_FACTOR=0.2 RAILS_ENV=test bundle exec rspec spec/features/work_packages_spec.rb

# Run with DevTools enabled
OPENPROJECT_TESTING_AUTO_DEVTOOLS=1 RAILS_ENV=test bundle exec rspec spec/features/work_packages_spec.rb
```

### Code Quality

```bash
# Install git hooks for linting
bundle exec lefthook install

# Ruby linting
bundle exec rubocop

# Fix Ruby linting issues
bundle exec rubocop --fix

# Frontend linting
cd frontend && npm run lint:fix

# Type checking
npm run tslint_typechecks
```

### Database Operations

```bash
# Migrate development database
RAILS_ENV=development bin/rails db:migrate

# Prepare test database
RAILS_ENV=test bin/rails parallel:create db:migrate parallel:prepare

# Reset and migrate databases
RAILS_ENV=development rails db:migrate db:test:prepare
```

## Architecture Overview

OpenProject is a **web-based project management application** built as a **Ruby on Rails monolith with a separate Angular frontend**. It follows a modular architecture with 27 feature modules.

### Core Components

#### Backend (Ruby on Rails 8.0.1)
- **Main application**: `app/` following Rails MVC pattern
  - `models/` - Data models and business logic
  - `controllers/` - HTTP controllers
  - `services/` - Service objects for complex business operations
  - `views/` - ERB templates (rails-rendered pages)
  - `workers/` - Background jobs using GoodJob
  - `mailers/` - Email templates
  - `contracts/` - API contracts
  - `policies/` - Authorization policies (Pundit-style)

- **API layer**: `lib/api/` with versioned endpoints (`v3/`, `v3明日`)

- **Modular architecture**: 27 feature modules in `modules/`
  - Example modules: `bim/`, `boards/`, `budgets/`, `calendar/`, `costs/`, `gantt/`, `meeting/`, `reporting/`, `storages/`

#### Frontend (Angular 17.x)
- **Source code**: `frontend/src/`
  - Modules, components, services organized by feature
  - Standalone Angular components
  - Some React components (hybrid architecture)

- **Build tooling**: Angular CLI with custom webpack configuration
- **Routing**: UI-Router for Angular
- **State management**: RxJS observables, Akita store pattern
- **Testing**: Jasmine + Karma

#### Hybrid Approach
OpenProject uses both Rails-rendered pages and Angular SPA routes:
- Some pages fully rendered by Rails with ERB templates
- Complex UI modules (work packages, calendars) are Angular SPAs
- Angular components can be embedded as custom elements in Rails views
- Rails handles routing for page-level navigation, Angular handles module-level routing

### Services Stack
- **Database**: PostgreSQL (primary), MySQL (for BI/analytics)
- **Cache**: Memcached or Redis
- **Background Jobs**: GoodJob (Rails-native queuing)
- **App Server**: Puma
- **Frontend Dev Server**: Angular CLI (proxied to Rails in development)

### Key Technologies
- **Ruby**: 3.4.7
- **Rails**: 8.0.1
- **TypeScript**: 5.4.x
- **Angular**: 17.3.x
- **Package Manager**: PNPM (frontend), Bundler (backend)

## Key Files and Locations

### Backend Structure
```
config/
├── application.rb          # Rails application configuration
├── routes.rb              # Main routes (Rails controllers)
├── database.yml           # Database configuration
└── environments/          # Environment-specific configs

lib/
└── api/                   # Ruby API (v3, v3明日)
    └── v3/

modules/
└── [module_name]/         # Feature modules (27 total)
    ├── app/
    ├── db/migrate/
    └── config/locales/

spec/
├── models/                # Unit tests
├── services/              # Service object tests
├── features/              # System/feature tests (Capybara)
└── requests/              # API tests
```

### Frontend Structure
```
frontend/
├── src/
│   ├── app/                    # Angular application
│   │   ├── features/           # Feature modules
│   │   ├── core/               # Core services
│   │   └── shared/             # Shared components
│   ├── assets/                 # Static assets
│   └── locales/                # i18n translations
├── angular.json                # Angular CLI configuration
├── tsconfig.json              # TypeScript configuration
└── package.json               # Dependencies and scripts
```

### API and Communication

#### Development Mode
- Angular CLI runs on port 4200 (or custom FE_PORT)
- Rails server on port 3000
- Angular proxy (`frontend/cli_to_rails_proxy.js`) forwards API requests to Rails
- WebSocket support via ActionCable

#### API Design
- **RESTful API with HAL** (Hypertext Application Language)
- **Versioned**: `api/v3/` and `api/v3明日`
- **JSON-based** responses with hypermedia links
- **Frontend communicates** primarily via APIv3

## Development Workflows

### Setting Up Development Environment

#### Option 1: Native Development
1. Ensure PostgreSQL is running
2. Create databases: `openproject_development` and `openproject_test`
3. Run `./bin/setup_dev`
4. Start services with `bin/dev` or manually

#### Option 2: Docker Development
```bash
docker-compose up
# Access at http://localhost:3000 (backend) and http://localhost:4200 (frontend)
```

### Making Changes

#### Backend Changes
1. Follow Rails conventions (models, services, controllers)
2. Add RSpec tests in `spec/`
3. Ensure migrations in `db/migrate/` are reversible
4. Update `config/routes.rb` for new controller routes
5. Internationalization: Use `I18n.t` with keys in `config/locales/`

#### Frontend Changes
1. Follow Angular conventions and module boundaries
2. Keep components presentational, move logic to services
3. Use RxJS observables for async data
4. Add `.spec.ts` tests alongside components
5. Respect lazy-loading configuration
6. Use translation helpers (no hard-coded strings)

#### Module Changes
- Modules are self-contained in `modules/[name]/`
- Can have own migrations, views, controllers, specs
- Register frontend components: `bundle exec rake openproject:plugins:register_frontend`

### Testing Strategy

OpenProject has a comprehensive test strategy:

- **Unit Tests** (RSpec): Models, services, libraries in `spec/models/`, `spec/services/`
- **Integration Tests**: Controllers, requests in `spec/requests/`, `spec/controllers/`
- **System/Feature Tests** (Capybara): Full-stack tests in `spec/features/`
- **Frontend Tests**: Jasmine/Karma specs in `frontend/src/**/*.spec.ts`

#### Best Practices
- Keep tests fast and deterministic
- Use `FactoryBot` for test data
- Test happy paths and edge cases
- Follow Arrange-Act-Assert pattern
- Mock external services
- Run full test suite via CI (takes ~15 minutes)

### Code Style and Standards

#### Ruby/Rails
- Follow Rails conventions
- Use Rubocop for linting (`.rubocop.yml`)
- Prefer service objects for complex business logic
- Use Pundit for authorization
- Write reversible migrations

#### TypeScript/Angular
- Follow Angular style guide
- Use TypeScript strict mode
- Use ESLint rules configured in `.eslintrc.js`
- Prefer components over directives
- Use OnPush change detection where applicable

### Git Workflow

- **Branch model**: Feature branches from `dev`, PRs back to `dev`
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)
- **CI**: All PRs tested via GitHub Actions
- **Hooks**: Lefthook can enforce Rubocop and ESLint on commit

## Common Tasks

### Working with Migrations
```bash
# Generate migration
rails generate migration AddColumnToTable

# Rollback migration
rails db:rollback

# Check migration status
rails db:migrate:status
```

### Working with Background Jobs
```bash
# Start worker in development
RAILS_ENV=development bundle exec good_job start

# Check job queue (in Rails console)
GoodJob::Job.all
```

### Accessing Rails Console
```bash
RAILS_ENV=development bin/rails console
```

### Asset Management
```bash
# Precompile assets for production
bundle exec rake assets:precompile

# Export locale files
bundle exec rake assets:export_locales
```

### Working with Modules
```bash
# Register frontend assets from all modules
bundle exec rake openproject:plugins:register_frontend
```

## Important Conventions

### Database Configuration
```yaml
# config/database.yml
development:
  adapter: postgresql
  database: openproject_development

test:
  adapter: postgresql
  database: openproject_test
```

### Environment Variables
- Configuration via `config/configuration.yml`
- Secrets in `config/credentials.yml.enc`
- Docker-specific env vars documented in `docker-compose.yml`

### JavaScript in ERB Templates
```erb
<!-- DO use: -->
<%= nonced_javascript_tag do %>
  // JavaScript code
<% end %>

<!-- DON'T use: -->
<script>
  // Inline script - blocked by CSP
</script>
```

### API Resources
- API endpoints return HAL (Hypertext Application Language) format
- Resources have `_links` and `_embedded` sections
- Version in URL path: `/api/v3/...`

## Troubleshooting

### Common Issues

1. **Frontend not loading assets**
   - Run `./bin/setup_dev` to rebuild assets
   - Ensure Angular CLI is running: `npm run serve`

2. **Database errors**
   - Check PostgreSQL is running
   - Verify databases exist: `openproject_development`, `openproject_test`
   - Run migrations: `RAILS_ENV=development rails db:migrate db:test:prepare`

3. **Test failures on CI but passing locally**
   - Check random seed: GitHub Actions logs show seed used
   - Run with same seed: `SPEC_OPTS="--seed 12345" bundle exec rake spec`
   - Check for order-dependent tests
   - Try bisecting: `bundle exec rspec --bisect`

4. **JavaScript errors in browser**
   - Check console for CSP violations
   - Ensure assets compiled: `rm -rf public/assets && bundle exec rake assets:precompile`
   - Clear browser cache

### Logs
- **Development**: `log/development.log`
- **Test**: `log/test.log`
- **Background jobs**: Check GoodJob dashboard or logs

### Getting Help
- Development docs: `docs/development/`
- Running tests guide: `docs/development/running-tests/`
- Architecture docs: `docs/development/application-architecture/`
- Git workflow: `docs/development/git-workflow/`

## Cursor Rules Summary

The repository includes detailed cursor rules in `.cursor/rules/`:

1. **Project Structure** (`01-project-structure.mdc`) - Monorepo layout and key files
2. **Rails Conventions** (`02-rails-conventions.mdc`) - Backend patterns and practices
3. **Angular Frontend** (`03-angular-frontend.mdc`) - Frontend architecture
4. **API and Routing** (`04-api-and-routing.mdc`) - API design and routing
5. **Testing and Environments** (`05-testing-and-environments.mdc`) - Testing strategy
6. **Navigation and Search** (`06-navigation-and-search.mdc`) - Code navigation tips
7. **Rails Views** (`07-rails-view-erb.mdc`) - ERB template conventions

Follow these rules when making changes to ensure consistency with the codebase.
