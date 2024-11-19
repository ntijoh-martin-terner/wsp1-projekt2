require 'date'

class App < BaseApp
  def get_project(project_id)
    # Check if the user has access to the requested project
    db.execute("SELECT p.* FROM projects p
                                JOIN project_assignments pa ON pa.project_id = p.id
                                WHERE p.id = ? AND pa.user_id = ? AND accepted = 1
                                ", [project_id, current_user_id]).first
  end

  post '/projects/:project_id/todos/new/' do |project_id|
    project = get_project(project_id)

    if project.nil?
      status 401
      redirect '/unauthorized'
    end

    todo_name = params['name']
    todo_description = params['description']
    end_date = params['end_date']
    start_date = Date.today.strftime('%Y-%m-%d')

    db.execute('INSERT INTO todo (project_id, name, description, start_date, end_date, last_edit_id, creator_id, completed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
               [project_id.to_i, todo_name, todo_description, start_date, end_date, current_user_id, current_user_id,
                0])

    redirect back
  end

  post '/projects/:project_id/todos/edit/' do |project_id|
    project = get_project(project_id)

    if project.nil?
      status 401
      redirect '/unauthorized'
    end

    todo_id = params['id'].to_i

    # Remove non-updatable keys
    updatable_params = params.reject { |key, _| %w[id project_id].include?(key) }

    if updatable_params.empty?
      status 400
      return 'No valid fields to update.'
    end

    updatable_params['completed'] = updatable_params['completed'].to_i if updatable_params.key?('completed')

    # Dynamically generate the SET clause
    set_clause = updatable_params.keys.map { |key| "#{key} = ?" }.join(', ')

    # Build the SQL query
    sql = "UPDATE todo SET #{set_clause} WHERE project_id = ? AND id = ?"

    # Prepare the values to pass into the query
    values = updatable_params.values + [project_id.to_i, todo_id]

    # Execute the query
    db.execute(sql, values)

    redirect back
  end

  post '/projects/:project_id/todos/delete/' do |project_id|
    project = get_project(project_id)

    if project.nil?
      status 401
      redirect '/unauthorized'
    end

    todo_id = params['id'].to_i
    db.execute('DELETE FROM todo WHERE project_id = ? AND id = ?', [project_id.to_i, todo_id])
    redirect back
  end
end
