# Ouranos
[![CircleCI](https://circleci.com/gh/jrgriffiniii/ouranos.svg?style=svg)](https://circleci.com/gh/jrgriffiniii/ouranos)

A Capistrano-driven deployment service build using [atmos/heaven](https://github.com/atmos/heaven.git).

## Dependencies

 * Ruby 2.7.3 or 2.6.7
 * Bundler 2.2.17

## Getting Started

### Running the App.

```bash
bundle install
bundle exec rails db:migrate
bundle exec rails server
bundle exec webpacker-dev-server
```

## Development

### Executing the Ruby Test Suites

```bash
RAILS_ENV=test bundle exec rails db:migrate
bundle exec rspec
```
