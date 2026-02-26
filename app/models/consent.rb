class Consent < ApplicationRecord
  belongs_to :anonymous_session, optional: true
  belongs_to :user, optional: true

  TYPES = %w[data_processing account_linking analytics].freeze

  validates :consent_type, presence: true, inclusion: { in: TYPES }
  validates :consent_version, presence: true
  validates :consent_text_snapshot, presence: true
  validate :has_session_or_user

  scope :granted, -> { where(granted: true, revoked_at: nil) }
  scope :for_type, ->(type) { where(consent_type: type) }

  def revoke!
    update!(revoked_at: Time.current, granted: false)
  end

  private

  def has_session_or_user
    if anonymous_session_id.blank? && user_id.blank?
      errors.add(:base, "Must belong to a session or user")
    end
  end
end
