# frozen_string_literal: true

require 'active_record'

# Configure the database connection
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/todoer.sqlite'
)

# Require all model files
Dir[File.join(__dir__, '../app/models/*.rb')].sort.each { |file| require file }
