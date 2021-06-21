# frozen_string_literal: true

module Ouranos
  # Top-level module for providers.
  module Provider
    # The super class provider, all providers inherit from this.
    class DefaultProvider
      include ApiClient
      include DeploymentTimeout
      include LocalLogFile

      attr_accessor :credentials, :guid, :last_child, :data

      # See http://stackoverflow.com/questions/12093748/how-do-i-check-for-valid-git-branch-names
      # and http://linux.die.net/man/1/git-check-ref-format
      VALID_GIT_REF = %r{\A(?!/)(?!.*(?:/\.|//|@\{|\\|\.\.))[\040-\176&&[^ ~\^:?*\[]]+(?<!\.lock|/|\.)\z}.freeze

      def initialize(guid, data)
        @guid        = guid
        @name        = 'unknown'
        @data        = data

        @credentials = Deployment::Credentials.new(working_directory)
      end

      def output
        @output ||= Deployment::Output.new(name, number, guid)
      end

      def status
        @status ||= Deployment::Status.new(name_with_owner, number)
      end

      def redis
        Ouranos.redis
      end

      def log(line)
        Rails.logger.info "#{name}-#{guid}: #{line}"
      end

      def gem_executable_path(name)
        executable_path = Rails.root.join('bin', 'cap').to_s
        if File.exist?(executable_path)
          executable_path
        else
          "bin/#{name}"
        end
      end

      def number
        deployment_data['id']
      end

      def name
        name_with_owner
      end

      def name_with_owner
        return @name unless data.key?('repository') && data['repository'].key?('full_name')

        data['repository']['full_name'] || @name
      end

      def sha
        deployment_data['sha'][0..7]
      end

      def ref
        deploy_ref = deployment_data['ref']
        raise "Invalid git reference #{deploy_ref.inspect}" unless VALID_GIT_REF.match?(deploy_ref)

        deploy_ref
      end

      def environment
        deployment_data['environment']
      end

      def description
        deployment_data['description'] || "Deploying from #{Ouranos::VERSION}"
      end

      def repository_url
        data['repository']['clone_url']
      end

      def default_branch
        data['repository']['default_branch']
      end

      def clone_url
        uri = Addressable::URI.parse(repository_url)
        uri.user = github_token
        uri.password = ''
        uri.to_s
      end

      def deployment_data
        data['deployment'] || data
      end

      def custom_payload
        @custom_payload ||= deployment_data['payload']
      end

      def custom_payload_name
        custom_payload && custom_payload['name']
      end

      def custom_payload_config
        custom_payload && custom_payload['config']
      end

      def setup
        credentials.setup!

        output.create
        status.output = output.url
        status.pending!
      end

      delegate :completed?, to: :status

      def execute
        warn "Ouranos Provider(#{name}) didn't implement execute"
      end

      def record
        Deployment.create(custom_payload: JSON.dump(custom_payload),
                          environment: environment,
                          guid: guid,
                          name: name,
                          name_with_owner: name_with_owner,
                          output: output.url,
                          ref: ref,
                          sha: sha)
      end

      def update_output
        output.stderr = File.read(stderr_file) if File.exist?(stderr_file)
        output.stdout = File.read(stdout_file) if File.exist?(stdout_file)

        output.update
      end

      def notify
        update_output

        last_child.success? ? status.success! : status.failure!
      end

      def run!
        Timeout.timeout(timeout) do
          start_deployment_timeout!
          setup
          execute unless Rails.env.test?
          notify
          record
        end
      rescue POSIX::Spawn::TimeoutExceeded, Timeout::Error => e
        Rails.logger.info e.message
        Rails.logger.info e.backtrace
        output.stderr += "\n\nDEPLOYMENT TIMED OUT AFTER #{timeout} SECONDS"
      rescue StandardError => e
        Rails.logger.info e.message
        Rails.logger.info e.backtrace
      ensure
        update_output
        status.failure! unless completed?
      end
    end
  end
end
