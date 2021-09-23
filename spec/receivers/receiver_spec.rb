# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Receiver do
  subject(:receiver) { described_class.new(event, guid, data) }

  let(:guid) { 'guid' }
  let(:full_name) { 'full_name' }
  let(:login) { 'login' }
  let(:payload_name) { 'payload_name' }
  let(:payload_repository) do
    {
      "full_name" => full_name,
      "owner" => {
        "login" => login
      }
    }
  end
  let(:data) do
    {
      "repository" => payload_repository,
      "deployment" => {
        "creator" => {
          "login" => login
        },

        "payload" => {
          "name" => payload_name
        }
      }
    }
  end
  let(:event) { 'deployment' }

  describe '#full_name' do
    it 'accesses the full name' do
      expect(receiver.full_name).to eq(full_name)
    end
  end

  describe '#active_repository?' do
    let(:repository) { instance_double(Repository) }

    before do
      allow(Repository).to receive(:find_or_create_by).and_return(repository)
    end

    it 'indicates that the repository is active' do
      allow(repository).to receive(:active?).and_return(true)

      expect(receiver.active_repository?).to be true
    end

    context 'when the retrieved Repository is not active' do
      before do
        allow(repository).to receive(:active?).and_return(false)
      end

      it 'indicates that the repository is not active' do
        expect(receiver.active_repository?).to be false
      end
    end

    context 'when a repository is not specified within the payload' do
      let(:payload_repository) { nil }

      it 'indicates that the repository is not active' do
        expect(receiver.active_repository?).to be false
      end
    end
  end

  describe '#run_deployment!' do
    let(:lock_receiver) { instance_double(LockReceiver) }
    let(:logger) { instance_double(ActiveSupport::Logger) }

    before do
      allow(LockReceiver).to receive(:new).and_return(lock_receiver)
    end

    context 'when a LockReceiver job successfully runs' do
      it '' do
        allow(lock_receiver).to receive(:run!).and_return(true)

        receiver.run_deployment!
        expect(lock_receiver).to have_received(:run!)
      end
    end

    context 'when a deployment job is already locked by another concurrently executing job' do
      it 'enqueues a locked error' do
        allow(logger).to receive(:info)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(Resque).to receive(:enqueue)
        allow(Ouranos::Jobs::Deployment).to receive(:locked?).and_return(true)
        allow(lock_receiver).to receive(:run!).and_return(false)

        receiver.run_deployment!

        expect(logger).to have_received(:info).with('Deployment locked for: payload_name--deployment')
        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::LockedError, guid, data)
      end
    end

    it 'enqueues a deployment job' do
      allow(Resque).to receive(:enqueue)
      allow(Ouranos::Jobs::Deployment).to receive(:locked?).and_return(false)
      allow(lock_receiver).to receive(:run!).and_return(false)

      receiver.run_deployment!

      expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::Deployment, guid, data)
    end
  end

  describe '#run!' do
    before do
      allow(Resque).to receive(:enqueue)
      allow(Ouranos::Jobs::Deployment).to receive(:locked?).and_return(false)

      receiver.run!
    end

    it 'enqueues a deployment job' do
      expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::Deployment, guid, data)
    end

    context 'with a deployment status event' do
      let(:event) { 'deployment_status' }

      before do
        allow(Resque).to receive(:enqueue)

        receiver.run!
      end

      it 'enqueues a deployment status job' do
        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::DeploymentStatus, data).twice
      end
    end

    context 'with a status event' do
      let(:event) { 'status' }

      before do
        allow(Resque).to receive(:enqueue)

        receiver.run!
      end

      it 'enqueues a status job' do
        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::Status, guid, data).twice
      end
    end

    context 'with an unhandled event' do
      let(:logger) { instance_double(ActiveSupport::Logger) }
      let(:event) { 'unhandled' }

      before do
        allow(logger).to receive(:info)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(Resque).to receive(:enqueue)

        receiver.run!
      end

      it 'logs a message' do
        expect(logger).to have_received(:info).with('Unhandled event type, unhandled.')
      end
    end
  end

  describe '.perform' do
    let(:built) { instance_double(described_class) }

    before do
      allow(built).to receive(:run!)
      allow(described_class).to receive(:new).and_return(built)
    end

    it 'runs the receiver job' do
      allow(built).to receive(:active_repository?).and_return(true)

      described_class.perform(event, guid, data)

      expect(built).to have_received(:active_repository?)
      expect(built).to have_received(:run!)
    end

    context 'when the repository is active' do
      let(:logger) { instance_double(ActiveSupport::Logger) }

      it 'runs the receiver job' do
        allow(logger).to receive(:info)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(built).to receive(:full_name).and_return(full_name)
        allow(built).to receive(:active_repository?).and_return(false)

        described_class.perform(event, guid, data)

        expect(built).to have_received(:active_repository?)
        expect(logger).to have_received(:info).with('Repository is not configured to deploy: full_name')
      end
    end
  end
end
