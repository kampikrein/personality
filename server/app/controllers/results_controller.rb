class ResultsController < ApplicationController
  def show
    @assessment = current_session.assessments.find(params[:assessment_id])

    if @assessment.status == "submitted"
      run_scoring_pipeline!(@assessment)
    end

    @profile = @assessment.profile
    if @profile
      @personality_type = @profile.personality_type
      @insights = @profile.insights.order(:context)
    else
      redirect_to root_path, alert: "결과를 생성할 수 없습니다. 다시 시도해주세요."
    end
  end

  private

  def run_scoring_pipeline!(assessment)
    ActiveRecord::Base.transaction do
      # Step 1: Calculate raw scores
      raw_scores = Scoring::DomainCalculator.new(assessment).call

      # Step 2: Normalize to 0-100
      normalized_scores = Scoring::Normalizer.new(assessment, raw_scores).call

      # Step 3: Classify type code
      classification = Scoring::TypeClassifier.new(assessment, normalized_scores).call

      # Step 4: Check reliability
      reliability = Scoring::ReliabilityAdjuster.new(assessment).call

      # Step 5: Persist domain scores
      normalized_scores.each do |domain, score|
        assessment.domain_scores.find_or_create_by!(domain: domain) do |ds|
          ds.raw_score = raw_scores[domain]
          ds.normalized_score = score || 0
          ds.reliability_coefficient = reliability[:reliability_coefficient]
          ds.consistency_index = reliability[:consistency_index]
          ds.speed_flag = reliability[:speed_flag]
          ds.policy_blocked = false
        end
      end

      assessment.score!

      # Step 6: Check policy
      policy_result = Scoring::PolicyChecker.new(assessment, reliability).call

      if policy_result[:blocked]
        assessment.domain_scores.update_all(policy_blocked: true)
        assessment.fail!
        return
      end

      # Step 7: Compose profile
      Profiles::Composer.new(assessment, type_code: classification[:type_code]).call

      # Step 8: Generate insights for all contexts
      assessment.reload
      Insight::CONTEXTS.each do |context|
        Insights::ContextEngine.new(assessment.profile, context).call
      end

      assessment.complete!
    end
  rescue StandardError => e
    Rails.logger.error("[ScoringPipeline] Failed for Assessment##{assessment.id}: #{e.message}")
    assessment.fail! unless assessment.status == "failed"
    redirect_to root_path, alert: "결과 생성 중 오류가 발생했습니다. 다시 시도해주세요."
  end
end
