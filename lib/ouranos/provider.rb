# frozen_string_literal: true

require 'ouranos/provider/default_provider'
require 'ouranos/provider/capistrano'
require 'ouranos/provider/bundler_capistrano'
require 'ouranos/provider/shell'

module Ouranos
  # A dispatcher for provider identification
  module Provider
    PROVIDERS ||= {
      'capistrano' => Capistrano,
      'bundler_capistrano' => BundlerCapistrano,
      'shell' => Shell
    }.freeze

    def self.from(guid, data)
      klass = provider_class_for(data)
      klass&.new(guid, data)
    end

    def self.provider_class_for(data)
      name     = provider_name_for(data)
      provider = PROVIDERS[name]

      Rails.logger.info "No deployment system for #{name}" unless provider

      provider
    end

    def self.provider_name_for(data)
      return unless data&.key?('deployment') &&
                    data['deployment'].key?('payload') &&
                    data['deployment']['payload'].key?('config')

      data['deployment']['payload']['config']['provider']
    end
  end
end
