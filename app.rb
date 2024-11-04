require 'bcrypt'

class App < Sinatra::Base

    def logged_in?
        !session[:user_id].nil?
    end

    get '/' do
        redirect '/home'
    end

    get '/home' do 
        erb(:"home")
    end

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/fruits.sqlite")
        @db.results_as_hash = true

        return @db
    end

    before do
        @user = db.execute("SELECT * FROM users WHERE username = ?", [session['user_id']]).first

        unless @user.nil? || request.path_info == '/login' || request.path_info == '/register'
            redirect '/login'
        end
    end

    get '/login' do
        erb :"login", :layout => false
    end

    get '/register' do
        erb :"register", :layout => false
    end

    post '/login' do
        content_type :json

        request_payload = JSON.parse request.body.read

        username = request_payload["usernameInput"]
        password = request_payload["passwordInput"]

        
        user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
        
        p user

        return { status: 'error', message: 'Incorrect password or username' }.to_json unless user

        if user['verified'] == 0 
            { status: 'error', message: 'Account is not verified, please check your mail' }.to_json
        end

        stored_password_hash = user['password_hash']

        if BCrypt::Password.new(stored_password_hash) == password
            session[:user_id] = username
            p "redirect"
            return { status: 'success', redirect_url: '/home', message: 'Redirecting to /home' }.to_json
            # redirect '/home'
        end

        { status: 'error', message: 'Incorrect password or username' }.to_json
    end
end
