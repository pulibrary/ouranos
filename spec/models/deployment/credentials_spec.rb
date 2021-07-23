# frozen_string_literal: true
require 'rails_helper'

describe Deployment::Credentials, type: :model do
  subject(:credentials) do
    described_class.new(root)
  end

  let(:root) do
    Rails.root.join('tmp')
  end

  let(:ssh_config_path) do
    Rails.root.join(root, '.ssh', 'config')
  end

  let(:ssh_config) do
    File.read(ssh_config_path)
  end

  let(:ssh_key_path) do
    Rails.root.join(root, '.ssh', 'id_rsa')
  end

  let(:ssh_key) do
    File.read(ssh_key_path)
  end

  let(:github_token) do
    '<unknown>'
  end

  let(:netrc_config_path) do
    Rails.root.join(root, '.netrc')
  end

  let(:netrc_config) do
    File.read(netrc_config_path)
  end

  before do
    ENV["DEPLOYMENT_PRIVATE_KEY"] = "secret"
  end

  after do
    ENV["DEPLOYMENT_PRIVATE_KEY"] = nil
  end

  describe '#setup!' do
    before do
      credentials.setup!
    end

    it 'updates the .ssh public key, .netrc file, and .ssh config. file' do
      expect(ssh_config).to include('StrictHostKeyChecking no')
      expect(ssh_config).to include('UserKnownHostsFile /dev/null')
      expect(ssh_config).to include('ForwardAgent yes')
      expect(ssh_config).to include('Host all')
      expect(ssh_config).to include('Hostname *')
      expect(ssh_config).to include("IdentityFile #{ssh_key_path}")

      expect(netrc_config).to include('machine github.com')
      expect(netrc_config).to include("username #{github_token}")
      expect(netrc_config).to include('password x-oauth-basic')
    end
  end
end
