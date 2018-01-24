require 'sequel'
DB = Sequel.sqlite("./db/todoable_#{ENV.fetch('RACK_ENV', 'development')}.db")