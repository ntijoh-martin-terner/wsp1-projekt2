require 'date'

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

    def get_project(project_id)
        username = session[:user_id]
        user = @db.execute("SELECT id FROM users WHERE username=?", [username]).first

        # Get user_id from user data
        user_id = user['id']

        # Check if the user has access to the requested project
        return @db.execute("SELECT p.* FROM projects p
                                JOIN project_assignments pa ON pa.project_id = p.id
                                WHERE p.id = ? AND pa.user_id = ?
                                ", [project_id, user_id]).first
    end

    post '/projects/new/' do
        start_date = Date.today.strftime("%Y-%m-%d")

        db.execute("INSERT INTO projects (name, description, start_date, end_date) VALUES (?, ?, ?, ?)", 
                    [params['name'], params['description'], start_date, params['end_date']])

        project_id = db.last_insert_row_id

        username = session[:user_id]
        user = @db.execute("SELECT id FROM users WHERE username=?", [username]).first

        # Get user_id from user data
        user_id = user['id']

        db.execute("INSERT INTO project_assignments (project_id, user_id) VALUES (?, ?)", [project_id, user_id])  # bob to Project Beta

        redirect back
    end

    post '/projects/delete/:project_id' do |project_id|
        project = get_project(project_id)

        @db.execute("DELETE FROM projects WHERE id=?", [project['id']]).first

        redirect back
    end

    post '/projects/edit/:project_id' do |project_id|
        project = get_project(project_id)

        @db.execute("UPDATE projects
                     SET name = ?, description = ?, end_date = ?
                     WHERE id = ?;", [params['name'], params['description'], params['end_date'], project['id']]).first

        redirect back
    end

    get '/projects/:project_id' do |project_id|
        @project = get_project(project_id)

        if @project
            @todos = @db.execute('SELECT * FROM todo WHERE project_id = ?', [@project['id']])
            
            erb :"projects"
        end
    end
end
