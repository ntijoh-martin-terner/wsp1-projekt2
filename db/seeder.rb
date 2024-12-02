# frozen_string_literal: true

require 'sqlite3'
require 'bcrypt'

class Seeder
  def self.db
    @db ||= SQLite3::Database.new('db/todoer.sqlite').tap do |database|
      database.results_as_hash = true
    end
  end

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS projects')
    db.execute('DROP TABLE IF EXISTS roles')
    db.execute('DROP TABLE IF EXISTS project_assignments')
    db.execute('DROP TABLE IF EXISTS todo')
  end

  def self.create_tables
    db.execute(<<-SQL)
      CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          username TEXT UNIQUE NOT NULL CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 20),
          password_hash TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          profile_picture_id TEXT DEFAULT NULL,
          verification_token TEXT,
          verified INTEGER DEFAULT 0 NOT NULL
      );
    SQL

    db.execute(<<-SQL)
      CREATE TABLE projects (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          start_date DATE,
          end_date DATE,
          creator_id INTEGER NOT NULL REFERENCES users (id) ON DELETE SET NULL
      );
    SQL

    db.execute(<<-SQL)
      CREATE TABLE roles (
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          can_add_todos BOOLEAN DEFAULT 0 NOT NULL,
          can_remove_todos BOOLEAN DEFAULT 0 NOT NULL,
          can_delete_users BOOLEAN DEFAULT 0 NOT NULL,
          can_add_users BOOLEAN DEFAULT 0 NOT NULL,
          can_assign_roles BOOLEAN DEFAULT 0 NOT NULL,
          UNIQUE (id, project_id), -- Enforce unique (id, project_id) if necessary
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      );
    SQL

    db.execute(<<-SQL)
      CREATE TABLE project_assignments (
          project_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          assigned_date DATE DEFAULT CURRENT_DATE,
          accepted BOOLEAN DEFAULT 0 NOT NULL,
          role_id INTEGER DEFAULT NULL,
          PRIMARY KEY (project_id, user_id),
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (role_id, project_id) REFERENCES roles (id, project_id) ON DELETE CASCADE
      );
    SQL

    db.execute(<<-SQL)
        CREATE TRIGGER enforce_role_id_constraint
        BEFORE INSERT ON project_assignments
        FOR EACH ROW
        WHEN NEW.role_id IS NULL AND NOT EXISTS (
            SELECT 1
            FROM projects
            WHERE projects.id = NEW.project_id AND projects.creator_id = NEW.user_id
        )
        BEGIN
            SELECT RAISE(ABORT, "role_id must be set unless the user is the project creator");
        END;
    SQL

    db.execute(<<-SQL)
        CREATE TRIGGER enforce_role_id_constraint_update
        BEFORE UPDATE ON project_assignments
        FOR EACH ROW
        WHEN NEW.role_id IS NULL AND NOT EXISTS (
            SELECT 1
            FROM projects
            WHERE projects.id = NEW.project_id AND projects.creator_id = NEW.user_id
        )
        BEGIN
            SELECT RAISE(ABORT, "role_id must be set unless the user is the project creator");
        END;
    SQL

    db.execute(<<-SQL)
      CREATE TABLE todo (
          id INTEGER PRIMARY KEY,
          project_id INTEGER NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          description TEXT,
          start_date DATE,
          end_date DATE,
          last_edit_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
          creator_id INTEGER REFERENCES users (id) ON DELETE SET NULL,
          completed BOOLEAN DEFAULT 0
      );
    SQL
  end

  def self.populate_tables
    # Password hash for all users
    password_hash = BCrypt::Password.create('SecretPassword')

    # Insert users
    db.execute('INSERT INTO users (username, password_hash, email, verified) VALUES (?, ?, ?, ?)',
               ['oudend', password_hash, 'oudend@gmail.com', 1])
    db.execute('INSERT INTO users (username, password_hash, email, verified) VALUES (?, ?, ?, ?)',
               ['alice', password_hash, 'alice@example.com', 1])
    db.execute('INSERT INTO users (username, password_hash, email, verified) VALUES (?, ?, ?, ?)',
               ['bob', password_hash, 'bob@example.com', 1])

    # Insert projects
    db.execute('INSERT INTO projects (name, description, start_date, end_date, creator_id) VALUES (?, ?, ?, ?, ?)',
               ['Project Alpha', 'First project description', '2024-01-01', '2024-06-30', 1]) # Created by 'oudend'
    db.execute('INSERT INTO projects (name, description, start_date, end_date, creator_id) VALUES (?, ?, ?, ?, ?)',
               ['Project Beta', 'Second project description', '2024-02-15', '2024-12-15', 3]) # Created by 'bob'

    # Insert roles for Project Alpha
    db.execute('INSERT INTO roles (project_id, name, can_add_todos) VALUES (?, ?, ?)',
               [1, 'non_admin', 1]) # Non-admin role with edit but no delete/assign permissions

    # Insert roles for Project Beta
    db.execute('INSERT INTO roles (project_id, name, can_add_todos) VALUES (?, ?, ?)',
               [2, 'non_admin', 1]) # Non-admin role with edit but no delete/assign permissions

    # Assign users to projects
    # For Project Alpha
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [1, 1, 1, nil]) # 'oudend' is owner of Project Alpha
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [1, 2, 1, 1])  # 'alice' is non-admin in Project Alpha
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [1, 3, 1, 1])  # 'bob' is non-admin in Project Alpha

    # For Project Beta
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [2, 3, 1, nil]) # 'bob' is owner of Project Beta
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [2, 1, 1, 2])  # 'oudend' is non-admin in Project Beta
    db.execute('INSERT INTO project_assignments (project_id, user_id, accepted, role_id) VALUES (?, ?, ?, ?)',
               [2, 2, 1, 2])  # 'alice' is non-admin in Project Beta

    # Insert todos
    db.execute('INSERT INTO todo (project_id, name, description, start_date, end_date, last_edit_id, creator_id, completed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
               [1, 'Define Project Scope', 'Initial scope definition', '2024-01-02', '2024-01-05', 1, 1, 0])
    db.execute('INSERT INTO todo (project_id, name, description, start_date, end_date, last_edit_id, creator_id, completed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
               [1, 'Draft Proposal', 'Prepare the project proposal', '2024-01-06', '2024-01-10', 2, 1, 0])
    db.execute('INSERT INTO todo (project_id, name, description, start_date, end_date, last_edit_id, creator_id, completed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
               [2, 'Beta Testing', 'Start beta testing phase', '2024-03-01', '2024-06-01', 3, 3, 0])
  end
end

Seeder.seed!
