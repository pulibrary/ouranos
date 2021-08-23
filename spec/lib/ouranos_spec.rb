# frozen_string_literal: true
require "rails_helper"

describe Ouranos do
  after do
    ENV['REDIS_PROVIDER'] = 'REDIS_HOST'
    key = ENV['REDIS_PROVIDER']
    ENV[key] = nil
  end

  describe '#redis' do
    # let(:redis) { described_class.redis }

    it 'constructs the Redis client' do
      redis = described_class.redis

      expect(redis).to be_a(Redis)
      expect(redis.connection).to include(id: 'redis://127.0.0.1:6379/0')
    end

    context 'when the REDIS_PROVIDER env. variable is provided' do
      it 'constructs the Redis client' do
        ENV['REDIS_PROVIDER'] = 'REDIS_HOST'
        key = ENV['REDIS_PROVIDER']
        ENV[key] = 'redis://redis-host.local:6379'
        redis = described_class.redis

        expect(redis).to be_a(Redis)
        expect(redis.connection).to include(id: 'redis://redis-host.local:6379/0')
      end
    end
  end

  describe '#redis_reconnect!' do
    it 'constructs the Redis client' do
      described_class.redis
      described_class.redis_reconnect!

      ENV['REDIS_PROVIDER'] = 'REDIS_HOST'
      key = ENV['REDIS_PROVIDER']
      ENV[key] = 'redis://redis-host.local:6379'

      expect(described_class.redis).to be_a(Redis)
      expect(described_class.redis.connection).to include(id: 'redis://redis-host.local:6379/0')
    end
  end
end
