# frozen_string_literal: true
class Deployment < ApplicationRecord
  validates :name, :name_with_owner, presence: true

  belongs_to :repository

  def self.latest_for_name_with_owner(name_with_owner)
    sets = self.select(:name, :environment)
               .where(name_with_owner: name_with_owner)
               .group("name,environment")

    sets.map do |deployment|
      params = {
        name: deployment.name,
        environment: deployment.environment,
        name_with_owner: name_with_owner
      }
      Deployment.where(params).order("created_at desc").limit(1)
    end.flatten
  end

  def payload
    @payload ||= custom_payload_json.with_indifferent_access
  end

  def auto_deploy_payload(actor, sha)
    payload.merge(actor: actor, sha: sha)
  end

  private

  def custom_payload_json
    JSON.parse(custom_payload)
  end
end
