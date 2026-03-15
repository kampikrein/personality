class DeletionRequest < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze
  SLA_DAYS = 7

  belongs_to :anonymous_session

  validates :request_token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  before_validation :set_defaults, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :overdue, -> { pending.where("sla_deadline < ?", Time.current) }

  def process!
    update!(status: "processing")
  end

  def complete!
    update!(status: "completed")
  end

  def fail!
    update!(status: "failed")
  end

  private

  def set_defaults
    self.request_token ||= SecureRandom.hex(16)
    self.status ||= "pending"
    self.sla_deadline ||= SLA_DAYS.days.from_now
  end
end
