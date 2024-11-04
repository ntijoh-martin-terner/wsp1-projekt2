require 'bcrypt'
require_relative 'routes/login.rb'
require_relative 'routes/register.rb'

class App < Sinatra::Base

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todoer.sqlite")
        @db.results_as_hash = true
        @db.execute("PRAGMA foreign_keys = ON")

        return @db
    end

    get '/' do
        redirect '/home'
    end

    get '/home' do 
        erb(:"home")
    end
end
