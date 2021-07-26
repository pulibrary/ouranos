# Ouranos
![Image of the Greek God Ouranos, father of the Titans](./ouranos.png)

[![CircleCI](https://circleci.com/gh/pulibrary/ouranos.svg?style=svg)](https://circleci.com/gh/pulibrary/ouranos)

A Capistrano-driven deployment service built using [atmos/heaven](https://github.com/atmos/heaven.git).

## Dependencies

 * [Ruby](https://www.ruby-lang.org/en/downloads/) 2.7.3 or 2.6.7
 * [Node.js](https://nodejs.org/en/) 14.16.1
 * [Yarn](https://yarnpkg.com/getting-started/install) 1.22.10
 * [Redis](https://redis.io/)
   * Start Redis with `brew services start redis` on macOS, or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.

## Getting Started

### Running the App.

```bash
bundle install
bundle exec rails db:migrate
bundle exec rails server
bundle exec webpacker-dev-server
```

## Development

```bash
bundle exec cap staging deploy
```

### Lint using RuboCop

```bash
bundle exec rubocop
```

### Executing the Ruby Test Suites

```bash
RAILS_ENV=test bundle exec rails db:migrate
bundle exec rspec
```
