class DomainScore < ApplicationRecord
  DOMAINS = Question::DOMAINS

  belongs_to :assessment

  validates :domain, presence: true, inclusion: { in: DOMAINS }
  validates :domain, uniqueness: { scope: :assessment_id }
  validates :raw_score, presence: true
  validates :normalized_score, presence: true, numericality: { in: 0..100 }

  scope :for_domain, ->(domain) { where(domain: domain) }
end
