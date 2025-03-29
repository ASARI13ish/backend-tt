require_relative 'lib/json_to_csv_converter'

input_folder = ARGV[0] || 'input_json_files'
output_folder = ARGV[1] || 'output_csv_files'

# Using regex to identifie files that last with .json extension, and for the gsub
Dir.glob("#{input_folder}/*.json") do |json_file|
  csv_file = json_file.gsub(/#{input_folder}/, output_folder).gsub(/json$/, 'csv')
  json = File.read(json_file)
  converter = JsonToCsvConverter.new(json, csv_file)

  # handling conversion failure or success and display it in the console.
  if converter.convert
    puts "#{json_file} successfully converted to csv"
  else
    puts " Failed to convert #{json_file} (invalid JSON)"
  end
end
