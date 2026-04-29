CREATE TABLE `alerts` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`alert_type` text NOT NULL,
	`severity` text DEFAULT 'medium' NOT NULL,
	`status` text DEFAULT 'open' NOT NULL,
	`message` text,
	`notes` text,
	`metadata` text DEFAULT '{}' NOT NULL,
	`resolved_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE TABLE `anonymous_sessions` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`user_id` integer,
	`session_token` text NOT NULL,
	`ip_hash` text,
	`ip_fingerprint` text,
	`user_agent_hash` text,
	`started_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE UNIQUE INDEX `anonymous_sessions_session_token_unique` ON `anonymous_sessions` (`session_token`);--> statement-breakpoint
CREATE TABLE `assessments` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`anonymous_session_id` integer NOT NULL,
	`question_set_id` integer NOT NULL,
	`status` text,
	`current_question_index` integer,
	`completion_rate` real,
	`non_response_rate` real,
	`extreme_response_rate` real,
	`retry_token` text,
	`started_at` text,
	`completed_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`anonymous_session_id`) REFERENCES `anonymous_sessions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`question_set_id`) REFERENCES `question_sets`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `audit_logs` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`action` text NOT NULL,
	`actor_id` integer,
	`actor_type` text,
	`resource_id` integer,
	`resource_type` text,
	`metadata` text DEFAULT '{}' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE TABLE `consents` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`anonymous_session_id` integer,
	`user_id` integer,
	`consent_type` text,
	`consent_version` text,
	`consent_text_snapshot` text,
	`granted` integer,
	`granted_at` text,
	`revoked_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`anonymous_session_id`) REFERENCES `anonymous_sessions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `deletion_requests` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`anonymous_session_id` integer NOT NULL,
	`request_token` text NOT NULL,
	`status` text DEFAULT 'pending' NOT NULL,
	`sla_deadline` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`anonymous_session_id`) REFERENCES `anonymous_sessions`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `deletion_requests_request_token_unique` ON `deletion_requests` (`request_token`);--> statement-breakpoint
CREATE TABLE `domain_scores` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`assessment_id` integer NOT NULL,
	`domain` text,
	`raw_score` real,
	`normalized_score` real,
	`consistency_index` real,
	`reliability_coefficient` real,
	`speed_flag` integer,
	`policy_blocked` integer,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`assessment_id`) REFERENCES `assessments`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_domain_scores_on_assessment_id_and_domain` ON `domain_scores` (`assessment_id`,`domain`);--> statement-breakpoint
CREATE TABLE `insights` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`profile_id` integer NOT NULL,
	`context` text NOT NULL,
	`explanation` text,
	`suggestions` text DEFAULT '[]' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`profile_id`) REFERENCES `profiles`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_insights_on_profile_id_and_context` ON `insights` (`profile_id`,`context`);--> statement-breakpoint
CREATE TABLE `personality_types` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`code` text NOT NULL,
	`character_name_ko` text NOT NULL,
	`character_name_en` text NOT NULL,
	`summary_ko` text,
	`summary_en` text,
	`strengths` text DEFAULT '[]' NOT NULL,
	`caution_patterns` text DEFAULT '[]' NOT NULL,
	`collaboration_style` text,
	`conflict_style` text,
	`learning_style` text,
	`career_hints` text,
	`recovery_style` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `personality_types_code_unique` ON `personality_types` (`code`);--> statement-breakpoint
CREATE TABLE `profiles` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`anonymous_session_id` integer NOT NULL,
	`assessment_id` integer NOT NULL,
	`personality_type_id` integer NOT NULL,
	`type_code` text NOT NULL,
	`score_vector` text DEFAULT '{}' NOT NULL,
	`strengths` text DEFAULT '[]' NOT NULL,
	`caution_patterns` text DEFAULT '[]' NOT NULL,
	`suggested_actions` text DEFAULT '[]' NOT NULL,
	`policy_blocked` integer DEFAULT false,
	`fallback_message` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`anonymous_session_id`) REFERENCES `anonymous_sessions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`assessment_id`) REFERENCES `assessments`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`personality_type_id`) REFERENCES `personality_types`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_profiles_on_assessment_id` ON `profiles` (`assessment_id`);--> statement-breakpoint
CREATE TABLE `question_sets` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`version_code` text,
	`status` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `question_sets_version_code_unique` ON `question_sets` (`version_code`);--> statement-breakpoint
CREATE TABLE `questions` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`question_set_id` integer NOT NULL,
	`domain` text NOT NULL,
	`position` integer NOT NULL,
	`body_ko` text NOT NULL,
	`body_en` text,
	`polarity` text DEFAULT 'positive' NOT NULL,
	`active` integer DEFAULT true NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`question_set_id`) REFERENCES `question_sets`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_questions_on_question_set_id_and_domain_and_position` ON `questions` (`question_set_id`,`domain`,`position`);--> statement-breakpoint
CREATE TABLE `responses` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`assessment_id` integer NOT NULL,
	`question_id` integer NOT NULL,
	`value` integer,
	`sequence_number` integer,
	`response_time_ms` integer,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`assessment_id`) REFERENCES `assessments`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `index_responses_on_assessment_id_and_question_id` ON `responses` (`assessment_id`,`question_id`);--> statement-breakpoint
CREATE TABLE `users` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`email_hash` text NOT NULL,
	`email_enc` text NOT NULL,
	`encryption_version` integer DEFAULT 1 NOT NULL,
	`display_name` text,
	`password_digest` text,
	`deleted_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_hash_unique` ON `users` (`email_hash`);