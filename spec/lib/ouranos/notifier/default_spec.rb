# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Notifier::Default do
  include ComparisonHelper

  subject(:default_notifier) { described_class.new(data.deep_stringify_keys) }

  let(:state) { 'success' }
  let(:user) { 'user' }
  let(:room) { 'room' }
  let(:name) { 'name' }
  let(:full_name) { 'atmos/heaven' }
  let(:html_url) { 'https://localhost' }
  let(:sha) { '1333c018defc50bfe123e2e7acbc83bb' }
  let(:data) do
    {
      repository: {
        full_name: full_name,
        html_url: html_url
      },
      deployment: {
        payload: {
          notify: {
            user: user,
            room: room
          },
          name: name
        },
        sha: sha
      },
      deployment_status: {
        state: state
      }
    }
  end
  let(:comparison) do
    {
      html_url: "https://github.com/org/repo/compare/sha...sha",
      total_commits: 1,
      commits: [
        build_commit_hash("Commit message #123"),
        build_commit_hash("Another commit")
      ],
      files: [{
        additions: 1,
        deletions: 2,
        changes: 3
      }, {
        additions: 1,
        deletions: 2,
        changes: 3
      }]
    }
  end
  let(:comparison_json) do
    JSON.generate(comparison)
  end

  before do
    stub_request(:get, "https://api.github.com/repos/atmos/heaven/compare/...1333c018").with(
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Authorization' => 'token <unknown>',
          'Content-Type' => 'application/json'
        }
      ).to_return(
        status: 200,
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Content-Type' => 'application/json'
        },
        body: comparison_json
      )
  end

  it "does not deliver changes unless an environment opt-in is present" do
    notifier = described_class.new("{}")

    expect(notifier.change_delivery_enabled?).to be false
  end

  context 'when the notifier is configured to display commit messages' do
    before do
      ENV["OURANOS_NOTIFIER_DISPLAY_COMMITS"] = "true"
    end

    after do
      ENV["OURANOS_NOTIFIER_DISPLAY_COMMITS"] = nil
    end

    it "does not deliver changes unless an environment opt-in is present" do
      notifier = described_class.new("{}")

      expect(notifier.change_delivery_enabled?).to be true
    end
  end

  describe '#ascii_face' do
    let(:state) { 'invalid' }

    it 'renders the unknown face' do
      expect(default_notifier.ascii_face).to eq('٩◔̯◔۶')
    end

    context 'when the state is pending' do
      let(:state) { 'pending' }

      it 'renders the pending face' do
        expect(default_notifier.ascii_face).to eq('•̀.̫•́✧')
      end
    end

    context 'when it is in a successful state' do
      let(:state) { 'success' }

      it 'renders the success face' do
        expect(default_notifier.ascii_face).to eq('(◕‿◕)')
      end
    end

    context 'when it is in a failed state' do
      let(:state) { 'failure' }

      it 'renders the failure face' do
        expect(default_notifier.ascii_face).to eq('ಠﭛಠ')
      end
    end

    context 'when it encounters an error' do
      let(:state) { 'error' }

      it 'renders the error face' do
        expect(default_notifier.ascii_face).to eq('¯_(ツ)_/¯')
      end
    end
  end

  describe '#default_message' do
    context 'when the deployment state is unsupported' do
      let(:state) { 'invalid' }

      before do
        allow(Rails.logger).to receive(:error)
        default_notifier.default_message
      end

      it 'logs an error for unhandled deployment states' do
        expect(Rails.logger).to have_received(:error).with('Unhandled deployment state, invalid')
      end
    end

    it 'builds the deployment message' do
      expect(default_notifier.default_message).to eq("[user](https://github.com/user)'s  deployment of [name](https://localhost) is done! ")
    end

    context 'when the deployment was a failure' do
      let(:state) { 'failure' }

      it 'builds the failure message' do
        expect(default_notifier.default_message).to eq("[user](https://github.com/user)'s  deployment of [name](https://localhost) failed. ")
      end
    end

    context 'when the deployment encountered an error' do
      let(:state) { 'error' }

      it 'builds the error message' do
        expect(default_notifier.default_message).to eq("[user](https://github.com/user)'s  deployment of [name](https://localhost) has errors. ")
      end
    end

    context 'when the deployment is pending' do
      let(:state) { 'pending' }

      it 'builds the pending message' do
        expect(default_notifier.default_message).to eq('[user](https://github.com/user) is deploying [name](https://localhost/tree/) to ')
      end
    end
  end

  describe '#comparison' do
    it 'requests the GitHub API comparison' do
      expect(default_notifier.comparison).to eq({
                                                  "commits" => [
                                                    { "author" => {
                                                      "html_url" => "https://github.com/login", "login" => "login"
                                                    },
                                                      "commit" => {
                                                        "message" => "Commit message #123"
                                                      },
                                                      "html_url" => "https://github.com/org/repo/commit/sha",
                                                      "sha" => "sha" },
                                                    {
                                                      "author" => {
                                                        "html_url" => "https://github.com/login",
                                                        "login" => "login"
                                                      },
                                                      "commit" => {
                                                        "message" => "Another commit"
                                                      },
                                                      "html_url" => "https://github.com/org/repo/commit/sha",
                                                      "sha" => "sha"
                                                    }
                                                  ],
                                                  "files" => [
                                                    {
                                                      "additions" => 1, "changes" => 3, "deletions" => 2
                                                    },
                                                    { "additions" => 1, "changes" => 3, "deletions" => 2 }
                                                  ],
                                                  "html_url" => "https://github.com/org/repo/compare/sha...sha",
                                                  "total_commits" => 1

                                                })
    end
  end

  describe '#commit_change_limit' do
    before do
      ENV['OURANOS_NOTIFIER_DISPLAY_COMMITS_LIMIT'] = '2'
    end

    after do
      ENV['OURANOS_NOTIFIER_DISPLAY_COMMITS_LIMIT'] = nil
    end

    it 'accesses the limit on the number of commit changes handled by the notifier' do
      expect(default_notifier.commit_change_limit).to eq(2)
    end
  end

  describe '#changes' do
    it 'generates messages from the changes committed using git' do
      expect(default_notifier.changes).to eq("Total Commits: 1\n2 Additions, 4 Deletions, 6 Changes\n\nsha by login: Another commit\nsha by login: Commit message #123")
    end
  end
end
