# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Notifier::Default do
  subject(:notifier) { described_class.new(data) }
  let(:id) { 'test-id' }
  let(:state) { nil }
  let(:target_url) { 'https://test.localdomain' }
  let(:description) { 'Testing' }
  let(:data) do
    {
      'deployment' => {
        'id' => 'test-id',
        'environment' => 'production',
        'task' => 'deploy',
        'sha' => 'sha',
        'ref' => 'main',
        'payload' => {
          'notify' => {
            'user' => 'user',
            'room' => 'room'
          },
          'name' => 'foo'
        }
      },
      'deployment_status' => {
        'id' => id,
        'state' => state,
        'target_url' => target_url,
        'description' => description
      }
    }
  end

  describe '#change_delivery_enabled?' do
    it "does not deliver changes unless an environment opt-in is present" do
      expect(notifier.change_delivery_enabled?).to be false
    end

    context 'when the display commits env. variable is set' do
      before do
        ENV["HEAVEN_NOTIFIER_DISPLAY_COMMITS"] = "true"
      end

      after do
        ENV["HEAVEN_NOTIFIER_DISPLAY_COMMITS"] = nil
      end

      it 'delivers changes' do
        expect(notifier.change_delivery_enabled?).to be true
      end
    end
  end

  describe '#deliver' do
    it 'is an abstract message' do
      expect { notifier.deliver('test') }.to raise_error("Unable to deliver, write your own #deliver(test) method.")
    end
  end

  describe '#pending?' do
    let(:state) { 'pending' }

    it 'determines whether or not the notifier is pending' do
      expect(notifier.pending?).to be true
    end
  end

  describe '#success?' do
    let(:state) { 'success' }

    it 'determines whether or not the notifier is successful' do
      expect(notifier.success?).to be true
    end
  end

  describe '#deploy?' do
    it 'determines whether or not the notifier is set for a deployment task' do
      expect(notifier.deploy?).to be true
    end
  end

  describe '#green?' do
    context 'when the state is pending' do
      let(:state) { 'pending' }

      it 'determines whether or not the notifier is set for a deployment task' do
        expect(notifier.green?).to be true
      end
    end

    context 'when the state is success' do
      let(:state) { 'success' }

      it 'determines whether or not the notifier is set for a deployment task' do
        expect(notifier.green?).to be true
      end
    end
  end

  ##
  describe '#ascii_face' do
    context 'when the state is pending' do
      let(:state) { 'pending' }

      it 'renders the pending state emoji' do
        expect(notifier.ascii_face).to eq('•̀.̫•́✧')
      end
    end

    context 'when the state is success' do
      let(:state) { 'success' }

      it 'renders the success state emoji' do
        expect(notifier.ascii_face).to eq('(◕‿◕)')
      end
    end

    context 'when the state is failure' do
      let(:state) { 'failure' }

      it 'renders the failure state emoji' do
        expect(notifier.ascii_face).to eq('ಠﭛಠ')
      end
    end

    context 'when the state is error' do
      let(:state) { 'error' }

      it 'renders the error state emoji' do
        expect(notifier.ascii_face).to eq('¯_(ツ)_/¯')
      end
    end

    it 'renders the default state emoji' do
      expect(notifier.ascii_face).to eq('٩◔̯◔۶')
    end
  end
end
