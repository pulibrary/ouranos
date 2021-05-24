# frozen_string_literal: true

module Ouranos
  REDIS_PREFIX = "ouranos:#{Rails.env}"

  class << self
    attr_writer :testing, :redis

    def testing?
      @testing.present?
    end

    def redis
      @redis ||= if ENV['REDIS_PROVIDER']
                   Redis.new(url: ENV[ENV['REDIS_PROVIDER']])
                 else
                   Redis.new
                 end
    end

    def redis_reconnect!
      @redis = nil
      redis
    end
  end
end

# Initialize early to ensure proper resque prefixes
Ouranos.redis

require 'ouranos/version'
require 'ouranos/jobs'
require 'ouranos/provider'
require 'ouranos/notifier'
