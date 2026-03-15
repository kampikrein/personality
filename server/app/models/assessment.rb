class Assessment < ApplicationRecord
  STATUSES = %w[in_progress submitted scored completed failed].freeze

  belongs_to :anonymous_session
  belongs_to :question_set

  has_many :responses, dependent: :destroy
  has_many :domain_scores, dependent: :destroy
  has_one :profile, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }

  before_validation :set_defaults, on: :create

  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }

  def submit!
    update!(status: "submitted")
  end

  def score!
    update!(status: "scored")
  end

  def complete!
    update!(status: "completed")
  end

  def fail!
    update!(status: "failed")
  end

  def current_question
    question_set.questions.active.ordered.offset(current_question_index).first
  end

  def advance_to_next_question!
    next_question!
    current_question
  end

  def all_questions_answered?
    responses.answered.count >= total_questions
  end

  def next_question!
    update!(current_question_index: current_question_index + 1)
  end

  def total_questions
    question_set.questions.active.count
  end

  def progress_percentage
    return 0 if total_questions.zero?
    ((current_question_index.to_f / total_questions) * 100).round
  end

  private

  def set_defaults
    self.status ||= "in_progress"
    self.current_question_index ||= 0
    self.completion_rate ||= 0.0
    self.non_response_rate ||= 0.0
    self.extreme_response_rate ||= 0.0
    self.retry_token ||= SecureRandom.hex(16)
  end
end
