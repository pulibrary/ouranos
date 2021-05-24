# frozen_string_literal: true
require "rails_helper"

describe "Ouranos::Notifier::Default" do
  it "does not deliver changes unless an environment opt-in is present" do
    notifier = Ouranos::Notifier::Default.new("{}")

    expect(notifier.change_delivery_enabled?).to be false

    ENV["HEAVEN_NOTIFIER_DISPLAY_COMMITS"] = "true"

    notifier = Ouranos::Notifier::Default.new("{}")

    expect(notifier.change_delivery_enabled?).to be true
  end
end
