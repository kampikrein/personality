class Question < ApplicationRecord
  DOMAINS = %w[energy decision_making relationship recovery].freeze
  POLARITIES = %w[positive negative].freeze

  belongs_to :question_set
  has_many :responses, dependent: :destroy

  validates :domain, presence: true, inclusion: { in: DOMAINS }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :body_ko, presence: true
  validates :polarity, presence: true, inclusion: { in: POLARITIES }

  scope :active, -> { where(active: true) }
  scope :by_domain, ->(domain) { where(domain: domain) }
  scope :ordered, -> { order(:position) }

  def negative?
    polarity == "negative"
  end
end
