# frozen_string_literal: true

module Ouranos
  autoload(:VERSION, Rails.root.join('lib', 'ouranos', 'version'))
  autoload(:Jobs, Rails.root.join('lib', 'ouranos', 'jobs'))
  autoload(:Provider, Rails.root.join('lib', 'ouranos', 'provider'))
  autoload(:Notifier, Rails.root.join('lib', 'ouranos', 'notifier'))

  REDIS_PREFIX = "ouranos:#{Rails.env}"

  class << self
    attr_writer :testing, :redis

    def testing?
      @testing.present?
    end

    def redis
      @redis = if ENV['REDIS_PROVIDER']
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
