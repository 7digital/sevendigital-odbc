require 'win32ole'

module SevenDigital
	module ODBC
		class Database
			attr_accessor :log

			@connection_string = nil
			@trace = false
			
			def trace?
				return @trace
			end
			
			def trace=(value)
				@trace = value
			end
			
			def initialize(conn_string)
				@connection_string = conn_string
				yield self if block_given?
			end

			def connection_string
				raise ArgumentError.new(
					"Expected connection_string to have been set via initialize()"
				) if @connection_string.nil?

				return @connection_string
			end

			# Returns: The primary key of the added record
			def add(table_name, primary_key, field_names, field_values)
				raise ArgumentError.new("Missing 'table_name' argument") if table_name.nil?
				raise ArgumentError.new("Missing 'primary_key' argument") if primary_key.nil?
				raise ArgumentError.new("Missing 'field_names' argument") if field_names.nil?
				raise ArgumentError.new("Missing 'field_values' argument") if field_values.nil?

				result = nil
				connection = nil
				recordset = nil

				fault = false

				field_values.each do |value|
					value = Database::sql_escape(value) if value.class == 'String'
				end

				begin
					connection = WIN32OLE.new('ADODB.Connection')
					connection.Open(connection_string)

					query = "select top 1 * from [#{table_name}] order by #{primary_key} desc"

					recordset = WIN32OLE.new('ADODB.Recordset')
					recordset.Open(
						query,
						connection,
						SqlServer::AD_OPEN_FORWARD_ONLY,
						SqlServer::AD_LOCK_OPTIMISTIC,
						SqlServer::AD_CMD_TEXT
					)

					recordset.AddNew(field_names, field_values)

					recordset.MoveNext unless recordset.EOF

					result = Integer(recordset.GetRows.transpose[0][0])
				rescue
					fault = true
					raise StandardError.new("An error has occured: #{$!}")
				ensure
					recordset.Close unless fault || recordset.nil? || recordset.State != SqlServer::AD_STATE_OPEN
					connection.Close unless connection.nil? || connection.State != SqlServer::AD_STATE_OPEN
				end

				return result
			end

			def execute(query)
				raise ArgumentError("Missing 'query' argument") if query.nil?
				
				begin
					db 			= SqlServer.new(connection_string)
					db.log 		= self.log unless self.log.nil?
					db.trace 	= @trace
					db.open
					db.query(query)
				ensure
					db.close
				end
			end

			def execute_sp(sp_name, parameters)
				raise ArgumentError.new("Missing 'sp_name' argument") if 
					sp_name.nil? or sp_name.empty?

				connection = nil
				command = nil
				fault = false

				begin
					connection = WIN32OLE.new('ADODB.Connection')
					connection.Open(connection_string)

					command = WIN32OLE.new('ADODB.Command')
					command.ActiveConnection = connection
					command.CommandType = SqlServer::AD_CMD_STOREDPROC
					command.CommandText = sp_name
					
					parameters.each do |p|
						command.Parameters.Append(p)
					end

					return command.Execute()
				rescue
					fault = true
					raise StandardError.new("An error has occured: #{$!}")
				ensure
					command == nil unless fault || command.nil? || command.State != SqlServer::AD_STATE_OPEN
					connection.Close unless connection.nil? || connection.State != SqlServer::AD_STATE_OPEN
				end

			end
			
			def self.sql_escape(text)
				return text.gsub(/'/, "''") unless text.nil?
				return ''
			end
			
			private
			def trace(message)
				unless false == trace? || log.nil? || false == log.debug? then
					log.debug("[#{SqlServer::class_name}] #{message}") unless log.nil?
				end
			end
		end
	end
end