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

    get '/projects/:project_id' do |project_id|
        username = session[:user_id]
        user = @db.execute("SELECT id FROM users WHERE username=?", [username]).first

        # Get user_id from user data
        user_id = user['id']

        # Check if the user has access to the requested project
        @project = @db.execute("SELECT p.* FROM projects p
                                JOIN project_assignments pa ON pa.project_id = p.id
                                WHERE p.id = ? AND pa.user_id = ?
                                ", [project_id, user_id]).first

        if @project
            erb :"projects"
        end
    end
end
