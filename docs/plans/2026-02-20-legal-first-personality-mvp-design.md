# Legal-First Personality Service MVP Design

Date: 2026-02-20
Owner: Project team
Status: Approved draft for planning

## 1) Goal and Product Positioning

### Goal
Build an MVP that prioritizes legal stability and brand trust before growth optimization.

### Product Positioning
- Not a clinical diagnostic product
- A self-understanding and relationship insight service
- Uses behavior guidance and context-based recommendations instead of fixed identity labeling

### Legal Boundary Principles
- Do not use official MBTI/Enneagram test items, report text, or protected brand expressions
- Use original question bank, original scale labels, and original report wording
- Keep transparent notices: "reference insight" and "not a diagnosis"

## 2) MVP Scope

### Core Components
1. Explore: personality tendency questionnaire flow
2. Profile: user tendency profile card
3. Insight: actionable suggestions by context (work, collaboration, conflict, recovery)

### Non-Goals (MVP)
- No AI-generated diagnosis narrative
- No social feed or viral sharing features
- No complex recommendation marketplace

## 3) Component Design

### A. Question Engine
- Domain-based question bank (energy, decision-making, relationship, recovery)
- Versioned sets (`qset_v1`, `qset_v2`)
- Mostly neutral Likert-style questions (1-5)
- Quality checks: non-response rate, extreme-response rate, item clarity

### B. Scoring Engine
- Domain scores normalized to 0-100
- Reliability adjustment using consistency and abnormal response-speed checks
- Output stored as profile vector (not hard type lock-in)
- Policy block for sensitive or clinically suggestive outputs

### C. Profile Composer
- Converts score vectors into user-facing cards:
  - strengths
  - caution patterns
  - suggested actions
- Uses original naming conventions
- Content tone policy: no stigma, no deterministic claims, action-oriented phrasing

### D. Insight Modules
- Context modules: collaboration, conflict, learning, career, recovery
- Start with rules + templates, expand personalization later
- Include "why this suggestion appears" explanation block

### E. Trust and Compliance Layer
- Minimal personal data collection, anonymous default option
- Always-visible notice for product scope and limitation
- Data lifecycle policy: purpose, retention period, deletion request flow
- Text policy filtering for restricted expressions

### F. Quality Operations
- Dashboard: completion rate, drop-off rate, satisfaction, report/complaint rate
- Alerts: bot-like response patterns, abnormal traffic, specific item complaint spikes
- Release gate: regression checks for question text and report text changes

## 4) Data Flow

1. `start` -> create anonymous session ID
2. load question set -> save step-by-step answers
3. submit -> score computation
4. profile + insight generation
5. result render with trust notice
6. optional account linking with explicit consent

### Storage Separation
- Separate PII data and response data stores
- Encrypt at rest
- Keep consent history with versioning
- Support cascade deletion for user deletion requests

## 5) Error Handling and Safety

### Failures and Fallbacks
- Question load failure: retry, then cached set fallback
- Submit failure: local temporary save + retry token
- Scoring failure: delayed processing queue + user-visible pending state
- Policy violation detection: block output and show safe fallback text

### Security and Audit
- Role-based access for operators
- Separate audit logs for sensitive operations
- Access logging for data review and deletion workflows

## 6) Testing Strategy

### Unit Tests
- Question parser
- Scoring formulas and normalization
- Reliability adjustment rules
- Policy filter behavior

### Integration / E2E
- Full flow: answer -> score -> profile -> insight render
- Failure paths for network/compute/policy filter

### Trust / Content QA
- Edge-case answer simulation (random, extreme, very fast)
- Restricted-language snapshot tests
- Manual quality checklist for user-facing wording

### Release Criteria
- Policy-violation exposure: 0
- Core flow error rate <= 1%
- Deletion SLA compliance >= 95%

## 7) 8-Week Roadmap

### Week 1-2: Foundation
- Finalize domains, label dictionary, and restricted-expression rules v1
- Define schema for answers, scores, consent, and deletion requests
- Build anonymous session flow baseline

### Week 3-4: Core Build
- Implement Question Engine, Scoring Engine, Profile Composer
- Build result page with trust disclosure
- Complete internal end-to-end MVP

### Week 5-6: Trust and Quality
- Add policy filters, access controls, deletion workflow, and fallback handling
- Pilot with small users and refine questions/text
- Produce trust and compliance check report

### Week 7-8: Pilot Release
- Controlled beta launch
- Monitor dashboard and alerts
- Final legal/content review and release decision

## 8) KPI Framework (Trust-First)

### Trust / Legal
- policy violation exposure: 0
- deletion SLA compliance: >= 95%

### Product Quality
- test completion rate: >= 70%
- result-page immediate drop-off: <= 30%

### User Value
- "helpful" response rate: >= 60%
- 7-day return rate: >= 20%

### Operational Stability
- critical path failure rate: <= 1%

## 9) Open Decisions for Planning Phase

- Final public naming strategy for profile labels
- Minimum set of contexts for MVP insight modules
- Legal review checklist ownership and sign-off process

---

This document is the approved design baseline for legal-first MVP planning.
