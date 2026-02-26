class Alert < ApplicationRecord
  SEVERITIES = %w[low medium high critical].freeze
  STATUSES = %w[open acknowledged resolved dismissed].freeze
  TYPES = %w[bot_detected policy_violation anomaly_detected system_error].freeze

  validates :alert_type, presence: true, inclusion: { in: TYPES }
  validates :severity, presence: true, inclusion: { in: SEVERITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :open, -> { where(status: "open") }
  scope :unresolved, -> { where.not(status: %w[resolved dismissed]) }

  def resolve!(notes: nil)
    update!(status: "resolved", resolved_at: Time.current, notes: notes)
  end

  def acknowledge!
    update!(status: "acknowledged")
  end

  def dismiss!(notes: nil)
    update!(status: "dismissed", notes: notes)
  end
end
