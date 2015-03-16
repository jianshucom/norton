require 'active_record'
require 'nulldb'
require 'norton'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/mock'
require 'minitest/pride'

Norton.setup url: 'redis://localhost:6379/0'

ActiveRecord::Base.establish_connection :adapter => :nulldb