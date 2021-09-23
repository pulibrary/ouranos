# frozen_string_literal: true
# Top-level class for Deployments.
class Deployment
  # All of the process output from a deployment
  class Output
    include ApiClient
    attr_accessor :guid, :name, :number, :stderr, :stdout

    def initialize(name, number, guid)
      @guid   = guid
      @name   = name
      @number = number
      @stdout = ""
      @stderr = ""
    end

    def gist
      @gist ||= api.create_gist(create_params)
    end

    def create
      gist
    end

    def update
      api.edit_gist(gist.id, update_params)
    rescue Octokit::UnprocessableEntity => entity_error
      Rails.logger.info "Unable to update #{gist.id}: #{entity_error}"
    rescue StandardError => e
      Rails.logger.info "Unable to update #{gist.id}, #{e.class.name} - #{e.message}"
    end

    def url
      gist.html_url
    end

    private

    def create_params
      {
        files: { stdout: { content: "Deployment #{number} pending" } },
        public: false,
        description: "Ouranos number #{number} for #{name}"
      }
    end

    def update_params
      params = {
        files: {},
        public: false
      }

      params[:files][:stderr] = { content: stderr } unless stderr.empty?

      params[:files][:stdout] = { content: stdout } unless stdout.empty?

      params
    end
  end
end
