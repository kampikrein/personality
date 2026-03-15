class Response < ApplicationRecord
  belongs_to :assessment
  belongs_to :question

  validates :sequence_number, presence: true
  validates :value, inclusion: { in: 1..5 }, allow_nil: true
  validates :question_id, uniqueness: { scope: :assessment_id }

  scope :answered, -> { where.not(value: nil) }
  scope :skipped, -> { where(value: nil) }
  scope :for_domain, ->(domain) { joins(:question).where(questions: { domain: domain }) }

  def skipped?
    value.nil?
  end

  def extreme?
    value == 1 || value == 5
  end
end
