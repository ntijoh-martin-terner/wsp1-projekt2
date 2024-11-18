# frozen_string_literal: true

require 'date'

# App
class App < BaseApp
  def get_project(project_id)
    # Check if the user has access to the requested project
    db.execute("SELECT p.* FROM projects p
                                JOIN project_assignments pa ON pa.project_id = p.id
                                WHERE p.id = ? AND pa.user_id = ? AND accepted = 1
                                ", [project_id, current_user_id]).first
  end

  post '/projects/:project_id/users/add/' do |project_id|
    get_project(project_id)

    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted) VALUES (?, ?, 0)',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/decline' do |project_id|
    db.execute('DELETE FROM project_assignments WHERE project_id = ? AND user_id = ? AND admin = 0',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/accept' do |project_id|
    db.execute('UPDATE project_assignments SET accepted=1 WHERE project_id = ? AND user_id = ? AND admin = 0',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/users/delete/' do |project_id|
    project = get_project(project_id)

    remove_user_id = params['id']

    is_admin = db.execute('SELECT FROM project_assignments WHERE project_id = ? AND user_id = ?',
                          [project_id, current_user_id]).first['admin'] == 1

    if project.nil? || !is_admin
      status 401
      redirect '/unauthorized'
    end

    # user_id = db.execute("SELECT id FROM users WHERE username=?", [username]).first['id']

    db.execute('DELETE FROM project_assignments WHERE project_id = ? AND user_id = ? AND admin = 0',
               [project_id, remove_user_id])

    redirect back
  end

  post '/projects/new/' do
    start_date = Date.today.strftime('%Y-%m-%d')

    db.execute('INSERT INTO projects (name, description, start_date, end_date) VALUES (?, ?, ?, ?)',
               [params['name'], params['description'], start_date, params['end_date']])

    project_id = db.last_insert_row_id

    db.execute('INSERT INTO project_assignments (project_id, user_id, admin, accepted) VALUES (?, ?, 1, 1)',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/delete/' do |project_id|
    project = get_project(project_id)

    db.execute('DELETE FROM projects WHERE id=?', [project['id']]).first

    redirect back
  end

  post '/projects/:project_id/edit/' do |project_id|
    project = get_project(project_id)

    db.execute("UPDATE projects
                     SET name = ?, description = ?, end_date = ?
                     WHERE id = ?;", [params['name'], params['description'], params['end_date'], project['id']]).first

    redirect back
  end

  get '/projects/:project_id/users' do |project_id|
    content_type :json
    @project = get_project(project_id)

    if @project.nil?
      status 401
      redirect '/unauthorized'
    end

    # if @project
    db.execute(
      'SELECT users.username, pa.admin, users.profile_picture_id from users
      JOIN project_assignments pa ON pa.user_id = users.id WHERE project_id = 1', [project_id]
    )

    # Return the results as JSON
    results.to_json
    # end
  end

  get '/projects/:project_id' do |project_id|
    @project = get_project(project_id)

    if @project.nil?
      status 401
      redirect '/unauthorized'
    end

    @todos = db.execute('SELECT * FROM todo WHERE project_id = ?', [@project['id']])

    @users = db.execute(
      'SELECT users.username, users.id, pa.admin, pa.accepted, users.profile_picture_id from users
       JOIN project_assignments pa ON pa.user_id = users.id WHERE project_id = ?', [project_id]
    )

    @is_admin = db.execute(
      'SELECT admin from project_assignments JOIN users ON users.id = project_assignments.user_id
       WHERE users.username = ? AND project_id = ?', [
         session[:username], project_id
       ]
    ).first['admin'] == 1

    erb :projects
  end
end
