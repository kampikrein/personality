# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_22_000005) do
  create_table "alerts", force: :cascade do |t|
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.text "message"
    t.json "metadata", default: {}
    t.text "notes"
    t.datetime "resolved_at"
    t.string "severity", default: "medium", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["severity"], name: "index_alerts_on_severity"
    t.index ["status"], name: "index_alerts_on_status"
  end

  create_table "anonymous_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_fingerprint"
    t.string "ip_hash"
    t.string "session_token", null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.string "user_agent_hash"
    t.integer "user_id"
    t.index ["session_token"], name: "index_anonymous_sessions_on_session_token", unique: true
    t.index ["user_id"], name: "index_anonymous_sessions_on_user_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.integer "anonymous_session_id", null: false
    t.datetime "completed_at"
    t.float "completion_rate"
    t.datetime "created_at", null: false
    t.integer "current_question_index"
    t.float "extreme_response_rate"
    t.float "non_response_rate"
    t.integer "question_set_id", null: false
    t.string "retry_token"
    t.datetime "started_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["anonymous_session_id"], name: "index_assessments_on_anonymous_session_id"
    t.index ["question_set_id"], name: "index_assessments_on_question_set_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.string "actor_type"
    t.datetime "created_at", null: false
    t.json "metadata", default: {}
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_audit_logs_on_actor_type_and_actor_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
  end

  create_table "consents", force: :cascade do |t|
    t.integer "anonymous_session_id"
    t.text "consent_text_snapshot"
    t.string "consent_type"
    t.string "consent_version"
    t.datetime "created_at", null: false
    t.boolean "granted"
    t.datetime "granted_at"
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["anonymous_session_id"], name: "index_consents_on_anonymous_session_id"
    t.index ["user_id"], name: "index_consents_on_user_id"
  end

  create_table "deletion_requests", force: :cascade do |t|
    t.integer "anonymous_session_id", null: false
    t.datetime "created_at", null: false
    t.string "request_token", null: false
    t.datetime "sla_deadline"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["anonymous_session_id"], name: "index_deletion_requests_on_anonymous_session_id"
    t.index ["request_token"], name: "index_deletion_requests_on_request_token", unique: true
    t.index ["sla_deadline"], name: "index_deletion_requests_on_sla_deadline"
  end

  create_table "domain_scores", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.float "consistency_index"
    t.datetime "created_at", null: false
    t.string "domain"
    t.float "normalized_score"
    t.boolean "policy_blocked"
    t.float "raw_score"
    t.float "reliability_coefficient"
    t.boolean "speed_flag"
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "domain"], name: "index_domain_scores_on_assessment_id_and_domain", unique: true
    t.index ["assessment_id"], name: "index_domain_scores_on_assessment_id"
  end

  create_table "insights", force: :cascade do |t|
    t.string "context", null: false
    t.datetime "created_at", null: false
    t.text "explanation"
    t.integer "profile_id", null: false
    t.json "suggestions", default: []
    t.datetime "updated_at", null: false
    t.index ["profile_id", "context"], name: "index_insights_on_profile_id_and_context", unique: true
    t.index ["profile_id"], name: "index_insights_on_profile_id"
  end

  create_table "personality_types", force: :cascade do |t|
    t.text "career_hints"
    t.json "caution_patterns", default: []
    t.string "character_name_en", null: false
    t.string "character_name_ko", null: false
    t.string "code", null: false
    t.text "collaboration_style"
    t.text "conflict_style"
    t.datetime "created_at", null: false
    t.text "learning_style"
    t.text "recovery_style"
    t.json "strengths", default: []
    t.text "summary_en"
    t.text "summary_ko"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_personality_types_on_code", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "anonymous_session_id", null: false
    t.integer "assessment_id", null: false
    t.json "caution_patterns", default: []
    t.datetime "created_at", null: false
    t.text "fallback_message"
    t.integer "personality_type_id", null: false
    t.boolean "policy_blocked", default: false
    t.json "score_vector", default: {}
    t.json "strengths", default: []
    t.json "suggested_actions", default: []
    t.string "type_code", null: false
    t.datetime "updated_at", null: false
    t.index ["anonymous_session_id"], name: "index_profiles_on_anonymous_session_id"
    t.index ["assessment_id"], name: "index_profiles_on_assessment_id", unique: true
    t.index ["personality_type_id"], name: "index_profiles_on_personality_type_id"
    t.index ["type_code"], name: "index_profiles_on_type_code"
  end

  create_table "question_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "version_code"
    t.index ["version_code"], name: "index_question_sets_on_version_code", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "body_en"
    t.text "body_ko", null: false
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "polarity", default: "positive", null: false
    t.integer "position", null: false
    t.integer "question_set_id", null: false
    t.datetime "updated_at", null: false
    t.index ["question_set_id", "domain", "position"], name: "index_questions_on_question_set_id_and_domain_and_position", unique: true
    t.index ["question_set_id"], name: "index_questions_on_question_set_id"
  end

  create_table "responses", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.integer "response_time_ms"
    t.integer "sequence_number"
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["assessment_id", "question_id"], name: "index_responses_on_assessment_id_and_question_id", unique: true
    t.index ["assessment_id"], name: "index_responses_on_assessment_id"
    t.index ["question_id"], name: "index_responses_on_question_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "display_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "anonymous_sessions", "users"
  add_foreign_key "assessments", "anonymous_sessions"
  add_foreign_key "assessments", "question_sets"
  add_foreign_key "consents", "anonymous_sessions"
  add_foreign_key "consents", "users"
  add_foreign_key "deletion_requests", "anonymous_sessions"
  add_foreign_key "domain_scores", "assessments"
  add_foreign_key "insights", "profiles"
  add_foreign_key "profiles", "anonymous_sessions"
  add_foreign_key "profiles", "assessments"
  add_foreign_key "profiles", "personality_types"
  add_foreign_key "questions", "question_sets"
  add_foreign_key "responses", "assessments"
  add_foreign_key "responses", "questions"
end
