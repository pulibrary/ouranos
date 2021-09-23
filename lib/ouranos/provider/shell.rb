# frozen_string_literal: true

module Ouranos
  # Top-level module for providers.
  module Provider
    # The shell provider.
    class Shell < DefaultProvider
      def initialize(guid, payload)
        super
        @name = 'shell'
      end

      def execute
        unless File.exist?(checkout_directory)
          log "Cloning #{repository_url} into #{checkout_directory}"
          execute_and_log(['git', 'clone', clone_url, checkout_directory])
        end

        Dir.chdir(checkout_directory) do
          # binding.pry
          log 'Fetching the latest code'
          execute_and_log(%w[git fetch])
          execute_and_log(['git', 'reset', '--hard', sha])
          Bundler.with_clean_env do
            log "Executing script: #{deployment_command}"
            execute_and_log([deployment_command], deployment_environment)
          end
        end
      end

      private

      def deployment_command
        script = custom_payload_config.try(:[], 'deploy_script')
        raise 'No deploy script configured.' unless script
        raise 'Only deploy scripts from the repo are allowed.' unless %r{\A([\w-]+/)*[\w-]+(\.\w+)?\Z}.match?(script)
        raise "Deploy script #{script} not found or not executable" unless File.executable?('./' + script)

        './' + script
      end

      def deployment_environment
        {
          'BRANCH' => ref,
          'SHA' => sha,
          'DEPLOY_ENV' => environment,
          'DEPLOY_TASK' => task
        }
      end

      def task
        name = deployment_data['task'] || 'deploy'
        raise "Invalid taskname: #{name.inspect}" unless /deploy(?:\:[\w+:]+)?/.match?(name)

        name
      end
    end
  end
end
