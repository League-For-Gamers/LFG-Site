# League for Gamers

This is the Rails app for our [main site](http://leagueforgamers.com/).

## Requirements
 - A Local Postgres Server for development and testing envs (9.4 or 9.5 preferred)
 	- HStore plugin. For Linux, if this not already installed with your postgres installation, it can usually be found in the `postgres-contrib` (or similarly named) package of your distro's package manager
 - ImageMagick in path
 - An Amazon S3 bucket for uploads (Unless you can get paperclip to behave locally, because I sure as hell couldn't)

## Setup

First of all, you'll need to make the `application.yml` and `database.yml` files in the `config/` directory. `database.yml` is the standard Rails format, but is currently postgres-only. `application.yml` can all be derived from the `application.example.yml` file. Secret keys can be generated with `rake secret`, just copy/paste the result in the correct places.
Once these are set up, run `rake db:seed` to seed the DB with roles, permissions, users, groups and test posts.  
There are two users created from seed, simply named `admin` and `boring_user`, their passwords are simply their usernames. 'admin' has full admin control over the site and group and 'boring_user' is simply a standard permission user.

Be sure to occasionally run `rake db:permission_migration` as we update the site. This will ensure your database has the latest permission configuration.

It is recommended that you have both optipng and jpegoptim installed on your system and in path, for image uploads. However, this is optional and will gracefully fail without them.

## Contributing
All pull requests are welcome, however it's greatly appreciated if your tests pass 100% and you write tests for all new code. We use RSpec, so tests can be run via `rake spec`

## License
See LICENSE file.