require "json"
require "csv"

class JsonToCsvConverter
  def initialize(json, csv)
    @json = json
    @csv = csv
  end

  def convert
    profiles = JSON.parse(@json)

    # Checking if profiles is an array
    unless profiles.is_a?(Array)
      puts "Error: Unexpected format of data (expected an array, got #{profiles.class})"
      return false
    end

    write_to_csv(profiles)

    # returns true if everything gone well, useful for the run.rb success (or fail) messages.
    true
  rescue JSON::ParserError => error
    puts "Error parsing JSON: #{error}"
    false
  end

  private

  def headers
    [
      "id",
      "email",
      "tags",
      "profiles.facebook.id",
      "profiles.facebook.picture",
      "profiles.twitter.id",
      "profiles.twitter.picture"
    ]
  end

  # Checks if the profile has the minimum informations required (an id and an email).
  def valid_profile?(profile)
    profile.is_a?(Hash) && profile.key?("id") && profile.key?("email")
  end

  def write_to_csv(profiles)
    CSV.open(@csv, "wb") do |csv|
      csv << headers
      profiles.each do |profile|
        next unless valid_profile?(profile)

        csv << flatten_profile(profile)
      end
    end
  end

  # Transform the JSON data into csv row
  def flatten_profile(profile)
    [
      profile["id"],
      profile["email"],
      profile["tags"].nil? ? '' : profile["tags"].join(','),
      profile.dig("profiles", "facebook", "id"),
      profile.dig("profiles", "facebook", "picture"),
      profile.dig("profiles", "twitter", "id"),
      profile.dig("profiles", "twitter", "picture")
    ]
  end
end
