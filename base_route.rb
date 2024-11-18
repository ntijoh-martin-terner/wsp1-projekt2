require 'sinatra/base'
require 'sqlite3'

class BaseApp < Sinatra::Base
  set :views, File.expand_path('../views', __dir__)
  set :public_folder, File.expand_path('../public', __dir__)

  helpers do
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/todoer.sqlite")
      @db.results_as_hash = true
      @db.execute("PRAGMA foreign_keys = ON")

      @db
    end

    def logged_in?
      !session[:username].nil?
    end

    def current_user_id
      return current_user['id']
    end

    def current_user
      return @current_user if @current_user

      username = session[:username]
      @current_user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
      @current_user
    end

    def current_date()
      Date.today.strftime("%Y-%m-%d")
    end
  end
end
