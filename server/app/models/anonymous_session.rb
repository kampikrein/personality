class AnonymousSession < ApplicationRecord
  belongs_to :user, optional: true

  has_many :assessments, dependent: :destroy
  has_many :profiles, dependent: :destroy
  has_many :consents, dependent: :destroy
  has_many :deletion_requests, dependent: :destroy

  validates :session_token, presence: true, uniqueness: true

  before_validation :generate_session_token, on: :create

  private

  def generate_session_token
    self.session_token ||= SecureRandom.uuid
  end
end
