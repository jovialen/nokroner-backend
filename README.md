# Nokroner Backend

[![CI](https://github.com/jovialen/nokroner-backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jovialen/nokroner-backend/actions/workflows/ci.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Rails](https://img.shields.io/badge/Rails-8.1.2-red.svg)](https://rubyonrails.org/)
[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

A personal finance management API built with Ruby on Rails. Track accounts, transactions, and manage your finances with ease.

## Features

- 🔐 **User Authentication** - Secure session-based and token-based authentication
- 👤 **User Profiles** - Manage personal information and preferences
- 💼 **Multi-Owner Support** - Create and manage multiple financial entities
- 🏦 **Account Management** - Track multiple bank accounts per owner
- 💸 **Transaction Tracking** - Record income, expenses, and transfers
- 📊 **Transaction Categorization** - Internal vs external transactions
- 🔍 **Advanced Querying** - Filter transactions by date, account, and type
- 📖 **API Documentation** - Auto-generated OpenAPI documentation

## Technology Stack

- **Framework**: Ruby on Rails 8.1.2
- **Database**: PostgreSQL
- **Authentication**: BCrypt with has_secure_password
- **API Documentation**: OasRails (OpenAPI/Swagger)
- **Testing**: Minitest
- **Deployment**: Kamal with Docker
- **Job Queue**: Solid Queue
- **Cable**: Solid Cable
- **Cache**: Solid Cache

## Getting Started

### Prerequisites

- Ruby 3.4+ (or the version specified in `.ruby-version`)
- PostgreSQL
- Bundler

### Installation

1. Clone the repository:
```bash
git clone https://github.com/jovialen/nokroner-backend.git
cd nokroner-backend
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
bin/rails db:create
bin/rails db:migrate
```

4. Start the server:
```bash
bin/rails server
```

The application will be available at `http://localhost:3000`.

### Running Tests

Run the full test suite:
```bash
bin/rails test
```

Run specific test files:
```bash
bin/rails test test/controllers/api/v1/user_controller_test.rb
```

### Code Quality

Run RuboCop for style checking:
```bash
bin/rubocop
```

Run Brakeman for security analysis:
```bash
bin/brakeman
```

Run Bundler Audit for dependency security:
```bash
bin/bundler-audit
```

Run all CI checks:
```bash
bin/ci
```

## API Documentation

Interactive API documentation is available at `/docs` when the server is running.

Visit `http://localhost:3000/docs` to explore the API endpoints.

## API Overview

### Authentication

The API supports two authentication methods:

1. **Bearer Token**: Include the token in the Authorization header
   ```
   Authorization: Bearer <your_token>
   ```

2. **Encrypted Cookie**: Automatically set when logging in through the web interface

### Main Endpoints

#### User Management
- `POST /api/v1/register` - Create a new user account
- `POST /api/v1/login` - Authenticate and get session token
- `DELETE /api/v1/logout` - End current session
- `GET /api/v1/me` - Get current user information
- `DELETE /api/v1/me` - Delete user account

#### Profile
- `GET /api/v1/me/profile` - Get user profile
- `PATCH /api/v1/me/profile` - Update user profile

#### Owners
- `GET /api/v1/owners` - List all owners
- `POST /api/v1/owners` - Create new owner
- `GET /api/v1/owners/:id` - Get owner details
- `PATCH /api/v1/owners/:id` - Update owner
- `DELETE /api/v1/owners/:id` - Delete owner

#### Accounts
- `GET /api/v1/accounts` - List all accounts
- `GET /api/v1/owners/:owner_id/accounts` - List accounts for specific owner
- `POST /api/v1/accounts` - Create new account
- `GET /api/v1/accounts/:id` - Get account details
- `PATCH /api/v1/accounts/:id` - Update account
- `DELETE /api/v1/accounts/:id` - Delete account

#### Transactions
- `GET /api/v1/transactions` - List all transactions
- `POST /api/v1/transactions` - Create new transaction
- `GET /api/v1/transactions/:id` - Get transaction details
- `PATCH /api/v1/transactions/:id` - Update transaction
- `DELETE /api/v1/transactions/:id` - Delete transaction

## Database Schema

### Core Models

- **User**: User accounts with authentication
- **Profile**: User profile information (name, date of birth)
- **Session**: User authentication sessions
- **Owner**: Financial entities (user can have multiple)
- **Account**: Bank accounts belonging to owners
- **Transaction**: Financial transactions between accounts

### Key Relationships

- Users have one Profile and one Owner (as themselves)
- Users can create multiple additional Owners
- Owners have multiple Accounts
- Accounts have many sent and received Transactions
- Transactions belong to a User (creator)

## Transaction Logic

Transactions automatically update account balances:

- **Internal Transfer**: Between two accounts owned by same owner
- **External Transfer**: Between accounts with different owners
- **Income**: Money coming into an account (from_account is nil)
- **Expense**: Money leaving an account (to_account is nil)

Account balances are automatically maintained through transaction callbacks.

## Development

### Environment Configuration

Configure your environment variables in `.env` or through your deployment system:

- `POSTGRES_HOST` - PostgreSQL host (default: localhost)
- `POSTGRES_PORT` - PostgreSQL port (default: 5432)
- `POSTGRES_USER` - PostgreSQL username
- `POSTGRES_PASSWORD` - PostgreSQL password
- `RAILS_MASTER_KEY` - Rails master key for credentials

### Database Setup

The application uses PostgreSQL with multiple databases in production:
- Primary database for main data
- Cache database for Rails cache
- Queue database for job queue
- Cable database for Action Cable

## Deployment

The application is configured for deployment with Kamal:

```bash
# Setup deployment
kamal setup

# Deploy
kamal deploy

# View logs
kamal logs -f
```

See `config/deploy.yml` for deployment configuration.

## Development

### Code Style

- Follow the Ruby style guide enforced by RuboCop
- Write tests for new features
- Ensure all tests pass before submitting PR
- Keep test coverage high

## Security

- Passwords are hashed using BCrypt
- Sessions use secure tokens
- CORS is configured for cross-origin requests
- API supports both cookie and bearer token authentication
- Regular security audits with Brakeman and Bundler Audit

## License

This project is licensed under the GNU General Public License version 3 - see the LICENSE file for details.

## Contact

Nicolai Frigaard - nicofri@pm.me

Project Link: [https://github.com/jovialen/nokroner-backend](https://github.com/jovialen/nokroner-backend)
