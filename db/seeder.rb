require 'sqlite3'
require 'bcrypt'

class Seeder
  
  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                verification_token TEXT,
                verified INTEGER DEFAULT 0 NOT NULL,
                admin INTEGER DEFAULT 0 NOT NULL)')
  end

  def self.populate_tables
    password_hash = BCrypt::Password.create('SecretPassword')
    db.execute("INSERT INTO users (username, password_hash, email, verified, admin) VALUES (?, ?, ?, ?, ?)", ['oudend', password_hash, "oudend@gmail.com", 1, 1])
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/fruits.sqlite')
    @db.results_as_hash = true
    @db
  end
end


Seeder.seed!