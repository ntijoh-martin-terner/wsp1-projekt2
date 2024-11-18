# frozen_string_literal: true

require 'bcrypt'
require 'date'
require_relative 'base_route'
Dir['./routes/*.rb'].sort.each { |file| require file }

# App
class App < BaseApp
  set :views, File.expand_path('./views', __dir__)
  set :public_folder, File.expand_path('./public', __dir__)

  before do
    return unless logged_in?

    @projects = db.execute("SELECT name, description, start_date, end_date, project_id as id FROM
                                project_assignments
                                LEFT JOIN Projects
                                ON Projects.id = project_assignments.project_id
                                WHERE user_id=? AND accepted = 1", [current_user_id])

    @notification_count = db.execute('SELECT COUNT(*) from project_assignments WHERE user_id = ? AND accepted = 0',
                                     [current_user_id]).first['COUNT(*)']

    @today_count = db.execute(
      'SELECT COUNT(*) FROM todo JOIN project_assignments ON todo.project_id = project_assignments.project_id WHERE project_assignments.user_id = ? AND todo.end_date = ? AND completed = 0', [
        current_user_id, current_date
      ]
    ).first['COUNT(*)']

    @path = request.path_info
  end

  get '/' do
    redirect '/today'
  end

  get '/unauthorized' do
    erb(:unauthorized, layout: nil)
  end
end
