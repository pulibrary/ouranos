# frozen_string_literal: true

require Rails.root.join('lib', 'ouranos', 'provider', 'default_provider')

module Ouranos
  # Top-level module for providers.
  module Provider
    # The capistrano provider.
    class Capistrano < DefaultProvider
      def initialize(guid, payload)
        super
        @name = 'capistrano'
      end

      def cap_path
        gem_executable_path('cap')
      end

      def task
        name = deployment_data['task'] || 'deploy'
        raise "Invalid capistrano taskname: #{name.inspect}" unless /deploy(?:\:[\w+:]+)?/.match?(name)

        name
      end

      def execute
        return execute_and_log(['/usr/bin/true']) if Rails.env.test?

        unless File.exist?(checkout_directory)
          log "Cloning #{repository_url} into #{checkout_directory}"
          execute_and_log(['git', 'clone', clone_url, checkout_directory])
        end

        Dir.chdir(checkout_directory) do
          log 'Fetching the latest code'
          execute_and_log(%w[git fetch])
          execute_and_log(['git', 'reset', '--hard', sha])
          deploy_command = [cap_path, environment, task]
          log "Executing capistrano: #{deploy_command.join(' ')}"
          execute_and_log(deploy_command, 'BRANCH' => ref)
        end
      end
    end
  end
end
