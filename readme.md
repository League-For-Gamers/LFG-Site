# League for Gamers

This is the Rails app for our [main site](http://leagueforgamers.com/).

## Setup

First of all, you'll need to make the `application.yml` and `database.yml` files in the `config/` directory. `database.yml` is the standard Rails format, but is currently postgres-only. `application.yml` can all be derived from the `application.example.yml` file. Secret keys can be generated with `rake secret`, just copy/paste the result.
One all these are done, run `rake db:seed` to seed the DB with the current roles and permissions in use.

## Contributing
All pull requests are welcome, however it's greatly appreciated if your tests pass 100% and you write tests for all new code. We use RSpec, so tests can be run via `rake spec`

## License
See LICENSE file.