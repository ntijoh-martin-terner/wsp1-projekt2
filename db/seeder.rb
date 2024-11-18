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
    # db.execute("PRAGMA foreign_keys = ON")
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                username TEXT UNIQUE NOT NULL CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 20),
                password_hash TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                profile_picture_id TEXT DEFAULT NULL,
                verification_token TEXT,
                verified INTEGER DEFAULT 0 NOT NULL)')
    db.execute('CREATE TABLE projects (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                start_date DATE,
                end_date DATE,
                creator user_id REFERENCES users (id) ON DELETE SET NULL)')
    db.execute('CREATE TABLE roles (
                id INTEGER PRIMARY KEY)')
    db.execute('CREATE TABLE project_assignments (
                project_id INTEGER,
                user_id INTEGER,
                assigned_date DATE DEFAULT CURRENT_DATE,
                accepted BOOLEAN DEFAULT 0 NOT NULL,
                role_id INTEGER DEFAULT 0 NOT NULL
                admin INTEGER DEFAULT 0 NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
                PRIMARY KEY (project_id, user_id),
                FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE)')
    db.execute('CREATE TABLE todo (
                id INTEGER PRIMARY KEY,
                project_id  NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                description TEXT,
                start_date DATE,
                end_date DATE,
                last_edit_id REFERENCES users (id) ON DELETE SET NULL,
                creator_id REFERENCES users (id) ON DELETE SET NULL,
                completed BOOLEAN DEFAULT 0)')
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
    db.execute('INSERT INTO projects (name, description, start_date, end_date) VALUES (?, ?, ?, ?)',
               ['Project Alpha', 'First project description', '2024-01-01', '2024-06-30'])
    db.execute('INSERT INTO projects (name, description, start_date, end_date) VALUES (?, ?, ?, ?)',
               ['Project Beta', 'Second project description', '2024-02-15', '2024-12-15'])

    # Assign users to projects
    db.execute('INSERT INTO project_assignments (project_id, user_id, admin, accepted) VALUES (?, ?, ?, ?)', [1, 1, 1, 1])  # oudend to Project Alpha
    db.execute('INSERT INTO project_assignments (project_id, user_id, admin, accepted) VALUES (?, ?, ?, ?)', [1, 2, 0, 1])  # alice to Project Alpha
    db.execute('INSERT INTO project_assignments (project_id, user_id, admin, accepted) VALUES (?, ?, ?, ?)', [2, 3, 1, 1])  # bob to Project Beta

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
