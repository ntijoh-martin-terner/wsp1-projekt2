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

    added_user_name = params['name']
    role_id = params['role_id']

    p added_user_name

    added_user_id = db.execute('SELECT id from users WHERE USERNAME = ?', [added_user_name]).first['id']

    db.execute('INSERT INTO project_assignments (project_id, user_id, role_id, accepted) VALUES (?, ?, ?, 0)',
               [project_id, added_user_id.to_i, role_id.to_i])

    redirect back
  end

  post '/projects/:project_id/decline' do |project_id|
    db.execute('DELETE FROM project_assignments WHERE project_id = ? AND user_id = ?',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/accept' do |project_id|
    db.execute('UPDATE project_assignments SET accepted=1 WHERE project_id = ? AND user_id = ?',
               [project_id, current_user_id])

    redirect back
  end

  post '/projects/:project_id/users/delete/' do |project_id|
    # project = get_project(project_id)

    remove_user_id = params['id']

    # @is_owner = project_creator_id(project_id) == current_user_id

    can_delete_users = db.execute(<<~SQL, [project_id, current_user_id]).first['can_delete_users'] == 1
      SELECT
        COALESCE(roles.can_delete_users, 1) AS can_delete_users
      FROM
        users
      JOIN
        project_assignments pa ON pa.user_id = users.id
      LEFT JOIN
        roles ON pa.role_id = roles.id
      WHERE
        pa.project_id = ? AND pa.user_id = ?;
    SQL

    unless can_delete_users
      status 401
      redirect '/unauthorized'
    end

    p project_id
    p remove_user_id

    begin
      db.execute('DELETE FROM project_assignments WHERE project_id = ? AND user_id = ? AND role_id IS NOT NULL',
                 [project_id.to_i, remove_user_id.to_i])
    rescue SQLite3::ConstraintException => e
      status 401
      redirect '/unauthorized'
    end

    redirect back
  end

  post '/projects/new/' do
    start_date = Date.today.strftime('%Y-%m-%d')
    begin
      db.transaction do
        db.execute('INSERT INTO projects (name, description, start_date, end_date, creator_id) VALUES (?, ?, ?, ?, ?)',
                   [params['name'], params['description'], start_date, params['end_date'], current_user_id])

        project_id = db.last_insert_row_id.to_i

        db.execute('INSERT INTO roles (name, project_id, can_edit, can_delete, can_assign_roles) VALUES
                    (?, ?, 1, 0, 0)',
                   ['Default', project_id])

        # admin_role_id = db.last_insert_row_id.to_i

        db.execute('INSERT INTO project_assignments (project_id, user_id, role_id, accepted) VALUES (?, ?, ?, 1)',
                   [project_id, current_user_id, nil])
      end
    rescue SQLite3::ConstraintException => e
      p e
      redirect back
    end

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

    @users = get_project_users(project_id)

    @current_user = get_current_project_user(project_id)

    @roles = db.execute(<<~SQL, [project_id])
      SELECT *
      FROM roles
      WHERE project_id = ?;
    SQL

    erb :projects
  end
end
