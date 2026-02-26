module Admin
  class DashboardController < BaseController
    # GET /admin
    # Main admin dashboard showing high-level stats: total assessments,
    # completion rate, average score, active sessions, etc.
    def index
      @total_assessments = Assessment.count
      @completed_assessments = Assessment.where(status: :completed).count
      @completion_rate = @total_assessments.zero? ? 0 : ((@completed_assessments.to_f / @total_assessments) * 100).round(1)
      @active_sessions = AnonymousSession.where("started_at > ?", 24.hours.ago).count
      @pending_deletions = DeletionRequest.where(status: :pending).count
    end

    # GET /admin/dashboard/completion_rates
    # Analytics endpoint showing assessment completion rates over time,
    # broken down by question set version.
    def completion_rates
      @rates = Assessment
        .group(:question_set_id)
        .select(
          "question_set_id",
          "COUNT(*) as total",
          "SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed"
        )
    end

    # GET /admin/dashboard/drop_off_analysis
    # Analytics endpoint showing where users abandon their assessments,
    # helping identify problematic questions or UX issues.
    def drop_off_analysis
      @drop_offs = Assessment
        .where(status: :in_progress)
        .group(:current_question_index)
        .count
        .sort_by { |index, _count| index }
    end
  end
end
