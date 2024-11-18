# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require_relative '../base_route'

class App < BaseApp
  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(32) # Change this to a secure secret
  end

  before do
    if !logged_in? && request.path_info != '/login' && request.path_info != '/register' && request.path_info != '/unauthorized'
      redirect '/login'
    end
  end

  get '/login' do
    erb :login, { layout: false }
  end

  post '/login' do
    content_type :json

    request_payload = JSON.parse request.body.read

    username = request_payload['usernameInput']
    password = request_payload['passwordInput']

    user = db.execute('SELECT * FROM users WHERE username = ?', [username]).first

    return { status: 'error', message: 'Incorrect password or username' }.to_json unless user

    { status: 'error', message: 'Account is not verified, please check your mail' }.to_json if user['verified'] == 0

    stored_password_hash = user['password_hash']

    if BCrypt::Password.new(stored_password_hash) == password
      session[:username] = username
      return { status: 'success', redirect_url: '/today', message: 'Redirecting to /today' }.to_json
    end

    status 401

    { status: 'error', message: 'Incorrect password or username' }.to_json
  end

  post '/logout' do
    session[:username] = nil
    redirect '/login'
  end
end
