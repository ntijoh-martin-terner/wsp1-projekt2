class App < BaseApp
  # Assign a role to a user
  post '/projects/:project_id/roles/assign' do |project_id|
    user_id = params[:user_id]
    role_id = params[:role_id]

    p user_id
    p role_id
    p project_id

    db.execute('UPDATE project_assignments SET role_id = ? WHERE user_id = ? AND project_id = ?',
               [role_id, user_id, project_id])

    redirect back
  end

  # Create a new role for a specific project
  post '/projects/:project_id/roles/new' do
    project_id = params[:project_id]
    name = params[:name]

    # Collect permissions from form
    permissions = {
      can_add_todos: params[:can_add_todos] ? 1 : 0,
      can_remove_todos: params[:can_remove_todos] ? 1 : 0,
      can_delete_users: params[:can_delete_users] ? 1 : 0,
      can_add_users: params[:can_add_users] ? 1 : 0,
      can_assign_roles: params[:can_assign_roles] ? 1 : 0
    }

    # Insert the new role into the database
    db.execute(
      <<-SQL,
      INSERT INTO roles (project_id, name, can_add_todos, can_remove_todos, can_delete_users, can_add_users, can_assign_roles)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      SQL
      [project_id, name, *permissions.values]
    )

    # Redirect to the project page or refresh the roles modal
    redirect back
  end

  # Update a user's role
  post '/projects/:project_id/roles/:role_id/update' do
    project_id = params[:project_id]
    role_id = params[:role_id]
    name = params[:name]
    permissions = {
      can_add_todos: params[:can_add_todos] ? 1 : 0,
      can_remove_todos: params[:can_remove_todos] ? 1 : 0,
      can_delete_users: params[:can_delete_users] ? 1 : 0,
      can_add_users: params[:can_add_users] ? 1 : 0,
      can_assign_roles: params[:can_assign_roles] ? 1 : 0
    }

    db.execute(
      <<-SQL,
      UPDATE roles
      SET#{' '}
          name = ?,
          can_add_todos = ?,
          can_remove_todos = ?,
          can_delete_users = ?,
          can_add_users = ?,
          can_assign_roles = ?
      WHERE id = ? AND project_id = ?
      SQL
      [name, *permissions.values, role_id, project_id]
    )

    redirect back
  end

  get '/projects/:project_id/roles/:role_id/delete' do
    project_id = params[:project_id]
    role_id = params[:role_id]

    db.execute('DELETE FROM roles WHERE id = ? AND project_id = ?', [role_id, project_id])

    redirect back
  end
end
