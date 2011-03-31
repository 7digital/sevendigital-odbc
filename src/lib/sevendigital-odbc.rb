$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'sevendigital-odbc/database'
require 'sevendigital-odbc/sql_server'
  
module SevenDigital::ODBC
	VERSION = '0.0.1'
end