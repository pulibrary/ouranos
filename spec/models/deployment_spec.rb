# frozen_string_literal: true
require 'rails_helper'

describe Deployment, type: :model do
  describe '.latest_for_name_with_owner' do
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

    it 'finds all of the Deployment models' do
      expect(deployments).not_to be_empty

      expect(deployments.first).to be_a(described_class)
      expect(deployments).to include(deployment1, deployment2)
    end
  end

  describe '#payload' do
    it '' do
    end
  end

  describe '#auto_deploy_payload' do
    it '' do
    end
  end
end
