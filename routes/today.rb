require 'date'

class App < BaseApp
    get '/today' do
        current_date = Date.today.strftime("%Y-%m-%d")

        @todos = db.execute('SELECT * FROM todo JOIN project_assignments ON todo.project_id = project_assignments.project_id WHERE project_assignments.user_id = ? AND todo.end_date = ? AND completed = 0', [current_user_id, current_date])

        erb(:"today")
    end
end