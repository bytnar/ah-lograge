require 'lograge'
require 'ah/lograge/custom_options_preparer'
require 'ah/lograge/railtie'

module Ah
  module Lograge
    def self.filter_params(&block)
      @@filter_params_block = block
    end

    def self.filter_params_block
      @@filter_params_block
    end
  end
end
