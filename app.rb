require 'bcrypt'
# require_relative 'routes/login.rb'
# require_relative 'routes/register.rb'
Dir["./routes/*.rb"].each {|file| require file }

class App < Sinatra::Base

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todoer.sqlite")
        @db.results_as_hash = true
        @db.execute("PRAGMA foreign_keys = ON")

        return @db
    end

    before do
        username = session[:user_id]

        user = @db.execute("SELECT * FROM users WHERE username=?", [username]).first

        if user
            @projects = @db.execute("SELECT name, description, start_date, end_date, project_id as id FROM 
                                    project_assignments 
                                    LEFT JOIN Projects
                                    ON Projects.id = project_assignments.project_id
                                    WHERE user_id=?", [user["id"]])

            p "projects:"
            p @projects
        end
    end

    get '/' do
        redirect '/today'
    end

    get '/today' do 
        erb(:"today")
    end
end
