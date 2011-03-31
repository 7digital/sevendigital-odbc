require 'win32ole'

module SevenDigital
	module ODBC
		# TODO: This class is misnamed, consider a more general name
		# See: http://rubyonwindows.blogspot.com/2007/03/ruby-ado-and-sqlserver.html
		class SqlServer
			# This class manages database connection and queries
			attr_accessor :connection, :data, :fields, :connection_string, :log
			
			@trace = false
			
			def trace?
				return @trace
			end
			
			def trace=(value)
				@trace = value
			end

			@@class_name = nil
			
			@cursor_type = 0
			@lock_type = 0
			@option = -1
			
			AD_STATE_CLOSED 	= 0  	# The object is closed
			AD_STATE_OPEN 		= 1 	# The object is open
			AD_STATE_CONNECTING = 2 	# The object is connecting
			AD_STATE_EXECUTING 	= 4 	# The object is executing a command
			AD_STATE_FETCHING 	= 8 	# The rows of the object are being retrieved
			
			# Cursor type
			AD_OPEN_FORWARD_ONLY 	= 0
			AD_OPEN_KEYSET 			= 1
			AD_OPEN_DYNAMIC 		= 2
			AD_OPEN_STATIC  		= 3

			# Lock type
			AD_LOCK_READONLY 			= 1
			AD_LOCK_OPTIMISTIC			= 3 
			AD_LOCK_BATCH_OPTIMISTIC 	= 4
			
			# Command type
			AD_CMD_TEXT 				= 1
			AD_CMD_TABLE 				= 2
			AD_CMD_STOREDPROC			= 4
			AD_CMD_TABLE_DIRECT 		= 512

			# Database type
			AD_INT				= 3
			AD_BIT				= 11
			AD_DB_TIMESTAMP		= 135
			AD_VARCHAR			= 200

			# Parameter Direction
			AD_PARAM_INPUT			= 1
			AD_PARAM_OUTPUT			= 2
			AD_PARAM_INPUTOUTPUT	= 3
			AD_PARAM_RETURN			= 4
			
			def initialize(
				connection_string, 
				cursor_type = AD_OPEN_FORWARD_ONLY, 
				lock_type = AD_LOCK_READONLY, 
				option = nil
			)
				@connection_string = connection_string
				@cursor_type = cursor_type
				@lock_type = lock_type
				@option = option
				@connection = nil
				@data = nil
			end

			def open
				raise StandardError.new('Missing connection string') if @connection_string.nil?
				
				@connection = WIN32OLE.new('ADODB.Connection')
				
				# Getting errors about Open not being a method? Ensure your connection string
				# contains provider attribute: 'Provider=SQLOLEDB.1'
				@connection.Open(@connection_string)
			end

			def query(sql)
				trace(sql)
				
				recordset = WIN32OLE.new('ADODB.Recordset')
				
				recordset.Open(sql, @connection, @cursor_type, @lock_type, @option)
				
				@fields = []
				recordset.Fields.each do |field|
					@fields << field.Name
				end
				
				@data = []
				
				begin
					if recordset.State != AD_STATE_CLOSED && !recordset.BOF && !recordset.EOF then
						# Move to the first record/row, if any exist
						recordset.MoveFirst
						
						@data = recordset.GetRows
					end
				ensure
					recordset.Close unless recordset.State == AD_STATE_CLOSED
				end
				 
				# An ADO Recordset's GetRows method returns an array 
				# of columns, so we'll use the transpose method to 
				# convert it to an array of rows
				@data = @data.transpose
			end
			
			def execute(sql)
				trace(sql)
				# See: http://www.w3schools.com/ADO/met_conn_execute.asp
				
				command = WIN32OLE.new('ADODB.Command')
				command.ActiveConnection = @connection
				command.CommandText = sql
				command.CommandType = SqlServer::AD_CMD_TEXT
				
				result_set = command.Execute
				
				while !(result_set == nil)
					result_set = result_set.NextRecordSet
				end
				
				result_set
			end

			def close
				@connection.Close unless @connection.nil? || @connection.State == AD_STATE_CLOSED
			end
			
			private
			def trace(message)
				unless false == trace? || log.nil? || false == log.debug? then
					log.debug("[#{SqlServer::class_name}] #{message}") unless log.nil?
				end
			end
			
			def self.class_name
				return @@class_name unless @@class_name.nil?
				return @@class_name = 'SqlServer' # self.class
			end
		end
	end
end