require 'sinatra/base'
require 'sqlite3'

class BaseApp < Sinatra::Base
  set :views, File.expand_path('../views', __dir__)
  set :public_folder, File.expand_path('../public', __dir__)

  helpers do
    def db
      return @db if @db

      @db = SQLite3::Database.new('db/todoer.sqlite')
      @db.results_as_hash = true
      @db.execute('PRAGMA foreign_keys = ON')

      @db
    end

    def logged_in?
      !session[:username].nil?
    end

    def get_current_project_user(project_id)
      get_project_users(project_id).find do |user|
        user['id'] == current_user_id
      end
    end

    def get_project_users(project_id)
      db.execute(<<~SQL, [project_id])
        SELECT
          users.username,
          users.id,
          pa.accepted,
          pa.role_id IS NULL AS owner,
          pa.role_id,
          COALESCE(roles.name, 'owner') AS role_name,
          COALESCE(roles.can_add_todos, 1) AS can_add_todos,
          COALESCE(roles.can_remove_todos, 1) AS can_remove_todos,
          COALESCE(roles.can_delete_users, 1) AS can_delete_users,
          COALESCE(roles.can_add_users, 1) AS can_add_users,
          COALESCE(roles.can_assign_roles, 1) AS can_assign_roles,
          users.profile_picture_id
        FROM
          users
        JOIN
          project_assignments pa ON pa.user_id = users.id
        LEFT JOIN
          roles ON pa.role_id = roles.id
        WHERE
          pa.project_id = ?;
      SQL
    end

    def project_creator_id(project_id)
      db.execute('SELECT creator_id FROM projects WHERE id = ?',
                 [project_id]).first['creator_id']
    end

    def current_user_id
      current_user['id']
    end

    def current_user
      return @current_user if @current_user

      username = session[:username]
      @current_user = db.execute('SELECT * FROM users WHERE username = ?', [username]).first
      @current_user
    end

    def current_date
      Date.today.strftime('%Y-%m-%d')
    end
  end
end
