require 'date'
require 'json'

class App < BaseApp
    post '/users/search' do
        content_type :json
        request_payload = JSON.parse request.body.read

        username = request_payload['username'] || params['username']

        # Query the database for users with names similar to the search term
        results = db.execute("SELECT id, username FROM users WHERE username LIKE ? LIMIT 5", ["%#{username}%"])

        # Return the results as JSON
        results.to_json
    end
end
