class User < ApplicationRecord
  has_secure_password

  encrypts :email, deterministic: true
  encrypts :display_name

  has_many :anonymous_sessions, dependent: :nullify
  has_many :consents, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
