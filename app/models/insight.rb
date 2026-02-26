class Insight < ApplicationRecord
  CONTEXTS = %w[collaboration conflict learning career recovery].freeze

  belongs_to :profile

  validates :context, presence: true, inclusion: { in: CONTEXTS }
  validates :context, uniqueness: { scope: :profile_id }

  scope :for_context, ->(ctx) { where(context: ctx) }
end
