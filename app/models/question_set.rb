class QuestionSet < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  has_many :questions, dependent: :destroy
  has_many :assessments, dependent: :restrict_with_error

  validates :version_code, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def self.current
    active.order(created_at: :desc).first
  end

  def activate!
    transaction do
      QuestionSet.where(status: "active").update_all(status: "archived")
      update!(status: "active")
    end
  end
end
