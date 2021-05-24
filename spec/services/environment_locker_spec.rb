# frozen_string_literal: true
require "rails_helper"

describe EnvironmentLocker do
  let(:redis) { instance_double(Redis) }

  let(:lock_params) do
    {
      name_with_owner: "atmos/heaven",
      environment: "production",
      actor: "atmos"
    }
  end

  describe "#lock?" do
    it "is true if the task is deploy:lock" do
      locker = described_class.new(lock_params.merge(task: "deploy:lock"))
      locker.redis = redis

      expect(locker.lock?).to be true
    end

    context "with hubot deploy prefix" do
      before { stub_const("ENV", "HUBOT_DEPLOY_PREFIX" => "ship") }

      it "is true if the task is ship:lock" do
        locker = described_class.new(lock_params.merge(task: "ship:lock"))
        expect(locker.lock?).to be true
      end
    end
  end

  describe "#unlock?" do
    it "is true if the task is deploy:unlock" do
      locker = described_class.new(lock_params.merge(task: "deploy:unlock"))
      locker.redis = redis

      expect(locker.unlock?).to be true
    end

    context "with hubot deploy prefix" do
      before { stub_const("ENV", "HUBOT_DEPLOY_PREFIX" => "ship") }

      it "is true if the task is ship:unlock" do
        locker = described_class.new(lock_params.merge(task: "ship:unlock"))
        expect(locker.unlock?).to be true
      end
    end
  end

  describe "#lock!" do
    before do
      allow(redis).to receive(:set).with("atmos/heaven-production-lock", "atmos")
      allow(redis).to receive(:get).with("atmos/heaven-production-lock").and_return("atmos")
    end

    it "locks the environment for the repo and records the locker" do
      locker = described_class.new(lock_params)
      locker.redis = redis

      expect(locker.actor).to eq("atmos")

      locker.lock!
      expect(redis).to have_received(:set).with("atmos/heaven-production-lock", "atmos")

      expect(locker.locked_by).to eq("atmos")
      expect(redis).to have_received(:get).with("atmos/heaven-production-lock")
    end
  end

  describe "#unlock!" do
    before do
      allow(redis).to receive(:del)
    end

    it "unlocks the environment for the repo" do
      locker = described_class.new(lock_params)
      locker.redis = redis

      locker.unlock!
      expect(redis).to have_received(:del).with("atmos/heaven-production-lock")
    end
  end

  describe "#locked?" do
    let(:locker) do
      described_class.new(lock_params).tap do |locker|
        locker.redis = redis
      end
    end

    it "is true if the repo/environment pair exists" do
      allow(redis).to receive(:exists).with("atmos/heaven-production-lock").and_return(true)

      expect(locker.locked?).to be true
      expect(redis).to have_received(:exists).with("atmos/heaven-production-lock")
    end

    it "is false if the repo/environment pair exists" do
      allow(redis).to receive(:exists).with("atmos/heaven-production-lock").and_return(false)

      expect(locker.locked?).to be false
      expect(redis).to have_received(:exists).with("atmos/heaven-production-lock")
    end
  end

  describe "#locked_by" do
    before do
      allow(redis).to receive(:get).with("atmos/heaven-production-lock").and_return("atmos")
    end

    it "returns the user who locked the environment" do
      locker = described_class.new(lock_params)
      locker.redis = redis

      expect(locker.locked_by).to eq("atmos")
      expect(redis).to have_received(:get).with("atmos/heaven-production-lock")
    end
  end
end
