class PersonalityType < ApplicationRecord
  VALID_CODES = %w[
    ENFP ENFJ ENTP ENTJ
    ESFP ESFJ ESTP ESTJ
    INFP INFJ INTP INTJ
    ISFP ISFJ ISTP ISTJ
  ].freeze

  has_many :profiles, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true, inclusion: { in: VALID_CODES }
  validates :character_name_ko, presence: true
  validates :character_name_en, presence: true

  def self.find_by_code(code)
    find_by(code: code.upcase)
  end
end
