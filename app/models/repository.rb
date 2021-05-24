# frozen_string_literal: true
class Repository < ApplicationRecord
  validates :name, :owner, presence: true

  has_many :deployments, dependent: :nullify
end
