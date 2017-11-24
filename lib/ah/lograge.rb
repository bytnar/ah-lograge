require 'lograge'
require 'ah/lograge/custom_options_preparer'
require 'ah/lograge/railtie'

module Ah
  module Lograge
    @@filter_params_block = nil
    @@additional_custom_entries_block = nil

    def self.filter_params(&block)
      @@filter_params_block = block
    end

    def self.filter_params_block
      @@filter_params_block
    end

    def self.additional_custom_entries(&block)
      @@additional_custom_entries_block = block
    end

    def self.additional_custom_entries_block
      @@additional_custom_entries_block
    end
  end
end
