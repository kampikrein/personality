class AssessmentsController < ApplicationController
  # POST /assessments
  # Finds the current active QuestionSet, creates an Assessment for the
  # current anonymous session, and redirects to the first question.
  def create
    question_set = QuestionSet.current

    assessment = current_session.assessments.create!(
      question_set: question_set,
      status: :in_progress,
      current_question_index: 0,
      started_at: Time.current
    )

    first_question = assessment.question_set.questions.ordered.first

    redirect_to assessment_question_path(assessment, first_question)
  end

  # GET /assessments/:id
  # Displays the assessment container with a Turbo Frame for streaming
  # questions in and out without full page reloads.
  def show
    @assessment = current_session.assessments.find(params[:id])
    @current_question = @assessment.current_question
  end

  # PATCH /assessments/:id/submit
  # Validates all questions are answered, transitions assessment to
  # submitted, enqueues scoring job (inline for MVP), redirects to results.
  def submit
    @assessment = current_session.assessments.find(params[:id])

    unless @assessment.all_questions_answered?
      redirect_to assessment_path(@assessment),
                  alert: "Please answer all questions before submitting."
      return
    end

    @assessment.update!(
      status: :submitted,
      completed_at: Time.current
    )

    # For MVP, scoring runs inline. In production this would be enqueued.
    # ScoringJob.perform_later(@assessment.id)

    redirect_to result_path(assessment_id: @assessment.id)
  end
end
