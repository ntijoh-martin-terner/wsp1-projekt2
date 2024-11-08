class App < Sinatra::Base
    set :views, File.expand_path('../views', __dir__)
    set :public_folder, File.expand_path('../public', __dir__)

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todoer.sqlite")
        @db.results_as_hash = true
        @db.execute("PRAGMA foreign_keys = ON")

        return @db
    end

    get '/projects' do
        username = session[:user_id]

        user = @db.execute("SELECT * FROM users WHERE username=?", [username]).first

        @projects = @db.execute("SELECT name, description, start_date, end_date, project_id as id FROM 
                                project_assignments 
                                LEFT JOIN Projects
                                ON Projects.id = project_assignments.project_id
                                WHERE user_id=?", [user["id"]])

        p @projects

        erb :"projects"
    end
end
