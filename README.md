[![Build Status](https://travis-ci.org/eozelius/teachable_todoable.svg?branch=master)](https://travis-ci.org/eozelius/teachable_todoable)
[![Maintainability](https://api.codeclimate.com/v1/badges/d3cdf6ae8c4a59e5698b/maintainability)](https://codeclimate.com/github/eozelius/teachable_todoable/maintainability)
# Teachable's Todoable

Welcome! Thanks for checking out one solution for Teachable's take home coding [exam](http://todoable.teachable.tech/), also see [this blog post](https://medium.com/teachable/how-teachable-revamped-the-backend-take-home-assignment-24e73ac36a0d) for more info.

## Installation

Clone this repo: 
```
$ git clone https://github.com/eozelius/teachable_todoable
```
Run .bin/setup to install any dependencies, as well as set up a test and development database

```
$ cd teachable_todoable
$ bin/setup
```

Ensure everything is working well by running the test suite:
```
$ rspec
```
If the tests executed without any failures, you're up and running!

## Dependencies
ruby 2.4.1

rspec 3.7

Sqlite3

## API Endpoints
post '/authenticate'

get '/lists'

get '/lists:list_id'

post '/lists'

post '/lists/:list_id/items'

patch '/lists/:list_id'

delete '/lists/:list_id'

put '/lists/:list_id/items/:item_id/finish'

delete '/lists/:list_id/items/:item_id'

## Classes
```API < Sinatra::Base``` - Sinatra class that responsible for routing HTTP (JSON format) requests to CRUD actions that will be executed by ```Ledger```.  

```Ledger``` - Ruby class responsible for CRUD operations with User, List and Item models.

```User < Sequel::Model``` - Database backed model representing a user 

```List < Sequel::Model``` - Database backed model representing a Todo List

```Item < Sequel::Model``` - Database backed model representing an Item that needs to be accomplished  

## SQL association

```User``` has_many ```List```'s, 

```List```'s has_many ```Item```'s

## Gotchas and Caveats
To create a new Database
```$ sequel -m "./db/migrations" sqlite3```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
