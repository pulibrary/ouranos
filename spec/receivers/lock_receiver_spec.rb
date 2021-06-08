# frozen_string_literal: true
require 'rails_helper'

describe LockReceiver do
  describe '#run!' do
    subject(:lock_receiver) do
      described_class.new(data)
    end
    let(:full_name) do
      "test"
    end

    let(:repository_data) do
      {
        "full_name" => full_name
      }
    end

    let(:login) do
      "test"
    end

    let(:creator) do
      {
        "login" => login
      }
    end

    let(:environment) do
      "test"
    end

    let(:deployment_id) do
      "test"
    end

    let(:task) do
      "test"
    end

    let(:deployment_data) do
      {
        "creator" => creator,
        "environment" => environment,
        "id" => deployment_id,
        "task" => task
      }
    end

    let(:data) do
      {
        "repository" => repository_data,
        "deployment" => deployment_data
      }
    end

    let(:environment_locker) do
      instance_double(EnvironmentLocker)
    end

    before do
      allow(EnvironmentLocker).to receive(:new).and_return(environment_locker)

      allow(Resque).to receive(:enqueue)
    end

    context 'when there is a lock on the deployment task' do
      it 'enqueues using the Resque client' do
        allow(environment_locker).to receive(:lock?).and_return(true)
        lock_receiver.run!

        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::EnvironmentLock, {
                                                         actor: login,
                                                         deployment_id: deployment_id,
                                                         environment: environment,
                                                         name_with_owner: full_name,
                                                         task: task
                                                       })
      end
    end

    context 'when there is no lock on the deployment task' do
      it 'enqueues using the Resque client' do
        allow(environment_locker).to receive(:unlock?).and_return(true)
        allow(environment_locker).to receive(:lock?).and_return(false)
        lock_receiver.run!

        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::EnvironmentUnlock, {
                                                         actor: login,
                                                         deployment_id: deployment_id,
                                                         environment: environment,
                                                         name_with_owner: full_name,
                                                         task: task
                                                       })
      end
    end

    context 'when it cannot be determined if there is a lock on the deployment task' do
      it 'enqueues using the Resque client' do
        allow(environment_locker).to receive(:locked?).and_return(true)
        allow(environment_locker).to receive(:unlock?).and_return(false)
        allow(environment_locker).to receive(:lock?).and_return(false)
        lock_receiver.run!

        expect(Resque).to have_received(:enqueue).with(Ouranos::Jobs::EnvironmentLockedError, {
                                                         actor: login,
                                                         deployment_id: deployment_id,
                                                         environment: environment,
                                                         name_with_owner: full_name,
                                                         task: task
                                                       })
      end
    end
  end
end
