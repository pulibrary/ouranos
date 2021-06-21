# frozen_string_literal: true
require 'rails_helper'

describe Deployment::Output, type: :model do
  subject(:output) { described_class.new(name, number, guid) }

  let(:name) { 'name' }
  let(:number) { 'number' }
  let(:guid) { 'guid' }
  let(:client) { instance_double(Octokit::Client) }
  let(:gist_id) { 'id' }
  let(:gist) { double }

  before do
    allow(gist).to receive(:id).and_return(gist_id)
    allow(gist).to receive(:html_url)
    allow(client).to receive(:create_gist).and_return(gist)
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  describe '.new' do
    it 'constructs a new object with a GUID, name, and number' do
      expect(output.guid).to eq(guid)
      expect(output.name).to eq(name)
      expect(output.number).to eq(number)
    end
  end

  describe '#create' do
    before do
      output.create
    end

    it 'transmits a POST request for the GitHub Gist' do
      expect(client).to have_received(:create_gist)
    end
  end

  describe '#update' do
    it 'transmits a POST request for the GitHub Gist' do
      allow(client).to receive(:edit_gist)
      output.update
      expect(client).to have_received(:edit_gist)
    end

    context 'when an unprocessable entity error is encountered' do
      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        allow(logger).to receive(:info)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(client).to receive(:edit_gist).and_raise(Octokit::UnprocessableEntity)
      end

      it 'logs an error' do
        output.update
        expect(logger).to have_received(:info).with("Unable to update #{gist_id}: Octokit::UnprocessableEntity")
      end
    end
  end

  describe '#url' do
    let(:gist) do
      double
    end

    before do
      allow(gist).to receive(:html_url)
      allow(client).to receive(:create_gist).and_return(gist)
    end

    it 'accesses the URL for the Gist' do
      allow(gist).to receive(:html_url)
    end
  end
end
