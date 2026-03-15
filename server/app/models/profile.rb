class Profile < ApplicationRecord
  belongs_to :assessment
  belongs_to :anonymous_session
  belongs_to :personality_type

  has_many :insights, dependent: :destroy

  validates :type_code, presence: true
  validates :assessment_id, uniqueness: true

  delegate :character_name_ko, :character_name_en, :summary_ko, :summary_en,
           :collaboration_style, :conflict_style, :learning_style,
           :career_hints, :recovery_style, to: :personality_type

  def domain_score(domain)
    score_vector&.dig(domain.to_s) || 0
  end

  def blocked?
    policy_blocked?
  end
end
