$:.unshift File.dirname(__FILE__) + '/../lib/'

require "itunes_observer"

module SpecHelper
end

Spec::Runner.configure do |config|
  config.include SpecHelper
end
