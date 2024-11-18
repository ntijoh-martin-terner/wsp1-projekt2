# frozen_string_literal: true

require 'date'

class App < BaseApp
  get '/notification' do
    @notifications = db.execute("SELECT projects.name, projects.description, projects.id as project_id from project_assignments JOIN projects
                                      ON projects.id = project_assignments.project_id WHERE user_id = ? AND accepted = 0", [current_user_id])

    erb(:notifications)
  end
end
