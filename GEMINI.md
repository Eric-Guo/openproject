# OpenProject Developer Context

## Overview
OpenProject is a web-based project management software. This repository contains the monolithic codebase, consisting of a Ruby on Rails backend and an Angular frontend.

## Tech Stack
- **Backend:** Ruby on Rails (Ruby 3.4.7)
- **Frontend:** Angular 17+ (TypeScript)
- **Runtime:** Node.js ^22.15.0
- **Package Manager:** pnpm (v10.21.0+)
- **Database:** PostgreSQL (implied standard for this stack)
- **Background Jobs:** `good_job`

## Getting Started

### Prerequisites
Ensure you have the following installed:
- Ruby 3.4.7
- Node.js ^22.15.0
- pnpm
- PostgreSQL

### Installation
1.  Install backend dependencies:
    ```bash
    bundle install
    ```
2.  Install frontend dependencies:
    ```bash
    pnpm install
    ```
    *(Note: The root `package.json` has a `postinstall` script that automatically installs frontend dependencies).*

### Running Locally
The project uses a `Procfile.dev` for local development, orchestrating the Rails server, Angular dev server, and background workers.

Use a process manager like `foreman` or `overmind` to run the application:

```bash
# If using foreman
foreman start -f Procfile.dev
```

Alternatively, run components individually:
- **Rails API:** `bundle exec rails server -p 3000`
- **Angular Frontend:** `cd frontend && pnpm run serve` (Default port: 4200)
- **Worker:** `bundle exec good_job start`

## Testing & Quality

### Backend (Rails)
- **Test Framework:** RSpec
- **Run Tests:** `bundle exec rspec`
- **Linting:** RuboCop (`bundle exec rubocop`)

### Frontend (Angular)
- **Test Framework:** Karma / Jasmine
- **Run Tests:**
  ```bash
  cd frontend
  pnpm test        # Single run
  pnpm test:watch  # Watch mode
  ```
- **Linting:** ESLint (via `esprint`)
  ```bash
  cd frontend
  pnpm run lint
  ```

## Key Directory Structure

- `app/` - Rails application code (models, controllers, views, etc.).
- `config/` - Rails configuration files.
- `db/` - Database schema and migrations.
- `docs/` - Extensive documentation for development and usage.
- `frontend/` - Angular single-page application.
- `modules/` - Additional OpenProject modules/plugins.
- `spec/` - Backend RSpec tests.
