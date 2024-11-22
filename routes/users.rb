require 'date'
require 'json'
require 'mini_magick'
require 'securerandom'

class App < BaseApp
  post '/users/search' do
    content_type :json
    request_payload = JSON.parse request.body.read

    username = request_payload['username'] || params['username']

    # Query the database for users with names similar to the search term
    results = db.execute('SELECT id, username FROM users WHERE username LIKE ? LIMIT 5', ["%#{username}%"])

    # Return the results as JSON
    results.to_json
  end
  post '/users/update_profile_picture' do
    if params[:profile_picture] && params[:profile_picture][:tempfile]
      tempfile = params[:profile_picture][:tempfile]
      filename = params[:profile_picture][:filename]

      # Ensure the file is a valid image
      unless ['image/jpeg', 'image/png'].include?(params[:profile_picture][:type])
        halt 400, 'Invalid file type. Only PNG and JPG are allowed.'
      end

      # Generate a random ID for the image
      random_id = SecureRandom.uuid
      extension = File.extname(filename)
      output_path = "public/profile_pictures/#{random_id}#{extension}"

      # Resize the image to 128x128
      image = MiniMagick::Image.read(tempfile)
      image.resize '128x128'
      image.write output_path

      # Update the database
      db.execute('UPDATE users SET profile_picture_id = ? WHERE id = ?',
                 ["#{random_id}#{extension}", current_user['id']])

      redirect back
    else
      halt 400, 'No file uploaded.'
    end
  end
end
