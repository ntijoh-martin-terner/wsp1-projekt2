# frozen_string_literal: true

require 'bcrypt'
require 'sanitize'

class App < BaseApp
  get '/register' do
    erb :register, { layout: false }
  end

  post '/register' do
    content_type :json

    request_payload = JSON.parse request.body.read

    username = Sanitize.fragment(request_payload['username'])
    email = Sanitize.fragment(request_payload['email'])
    password = Sanitize.fragment(request_payload['password'])

    p username, email, password

    p request_payload

    begin
      db.transaction do
        # Hash the password
        password_hash = BCrypt::Password.create(password)
        verification_token = SecureRandom.hex(16)

        # Save user to the database
        db.execute('INSERT INTO users (username, email, password_hash, verification_token, verified) VALUES (?, ?, ?, ?, ?)',
                   [username, email, password_hash, verification_token, 1])

        # no verification currently
        # db.execute("INSERT INTO users (verified) VALUES (?)",
        #             [1])
        # Send verification email
        # send_verification_email(email, verification_token)
      end

      return { status: 'success', message: 'Registration successful! Please verify your email.' }.to_json
    rescue SQLite3::ConstraintException => e
      return { status: 'error', message: 'Username or email already exists!' }.to_json
    rescue StandardError => e
      return { status: 'error', message: "An error occurred during registration: #{e}" }.to_json
    end
  end
end
