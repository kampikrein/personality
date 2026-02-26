module AssessmentHelpers
  def create_full_assessment(score_map: nil)
    session = create(:anonymous_session)
    qs = QuestionSet.current || create(:question_set, :with_questions)
    assessment = create(:assessment, anonymous_session: session, question_set: qs)

    qs.questions.active.ordered.each_with_index do |q, i|
      value = if score_map && score_map[q.domain]
                score_map[q.domain]
              else
                3
              end
      create(:response,
             assessment: assessment,
             question: q,
             value: value,
             response_time_ms: rand(1000..5000),
             sequence_number: i + 1)
    end

    assessment
  end
end

RSpec.configure do |config|
  config.include AssessmentHelpers
end
