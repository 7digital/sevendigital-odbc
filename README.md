# sevendigital-odbc

## Usage:

	def setup(connection_string, script_file)
		sql = ''

		File.open(script_path(script_file), 'r') do |file|
			file.each_line do |line|
				sql += line
			end
		end

		database = nil
		
		begin
			database = SevenDigital::ODBC::SqlServer.new(connection_string)
			database.open
			database.execute sql
		ensure
			database.close unless database.nil?
		end
	end
	
## Credits:

Mostly the work of @ben-biddington