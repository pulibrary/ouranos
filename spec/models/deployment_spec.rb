# frozen_string_literal: true
require 'rails_helper'

describe Deployment, type: :model do
  let(:name_with_owner) do
    'atmos/heaven'
  end
  let(:deployments) do
    described_class.latest_for_name_with_owner(name_with_owner)
  end
  let(:name1) do
    "atmos1"
  end
  let(:name2) do
    "atmos2"
  end
  let(:environment) do
    "production"
  end
  let(:repository) do
    Repository.create
  end

  describe '.latest_for_name_with_owner' do
    let(:deployment1) do
      described_class.create(name_with_owner: name_with_owner, name: name1, environment: environment, repository: repository)
    end
    let(:deployment2) do
      described_class.create(name_with_owner: name_with_owner, name: name2, environment: environment, repository: repository)
    end

    before do
      deployment1
      deployment2
    end

    # describe '.latest_for_name_with_owner' do
    it 'finds all of the Deployment models' do
      expect(deployments).not_to be_empty

      expect(deployments.first).to be_a(described_class)
      expect(deployments).to include(deployment1, deployment2)
    end
  end

  describe '#payload' do
    let(:payload_name) { name1 }
    let(:custom_payload) do
      {
        'name' => payload_name
      }
    end
    let(:custom_payload_json) do
      JSON.generate(custom_payload)
    end

    let(:deployment1) do
      described_class.create(
          name_with_owner: name_with_owner,
          name: name1,
          environment: environment,
          repository: repository,
          custom_payload: custom_payload_json
        )
    end

    it 'accesses the parsed API response payload' do
      expect(deployment1.payload).to include('name' => 'atmos1')
    end
  end

  describe '#auto_deploy_payload' do
    let(:payload_name) { name1 }
    let(:custom_payload) do
      {
        'name' => payload_name
      }
    end
    let(:custom_payload_json) do
      JSON.generate(custom_payload)
    end
    let(:deployment1) do
      described_class.create(
          name_with_owner: name_with_owner,
          name: name1,
          environment: environment,
          repository: repository,
          custom_payload: custom_payload_json
        )
    end
    let(:actor) { 'test-actor' }
    let(:sha) { 'test-sha' }
    let(:auto_deploy_payload) do
      deployment1.auto_deploy_payload(actor, sha)
    end

    it 'accesses the parsed deployed payload' do
      expect(auto_deploy_payload).to include(name: 'atmos1')
      expect(auto_deploy_payload).to include(actor: 'test-actor')
      expect(auto_deploy_payload).to include(sha: 'test-sha')
    end
  end
end
