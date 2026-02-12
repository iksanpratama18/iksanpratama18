-- =====================================================
-- E-Learning Platform: Assessment Schema
-- Version: V004
-- Description: Quizzes, assignments, submissions, grading, and progress tracking
-- =====================================================

-- Create assessment schema
CREATE SCHEMA IF NOT EXISTS assessment;

-- Set search path for this migration
SET search_path TO assessment, course_management, user_management, public;

-- =====================================================
-- QUESTION BANKS
-- =====================================================

CREATE TABLE assessment.question_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    subject VARCHAR(100),
    difficulty_level VARCHAR(20) DEFAULT 'medium',
    
    -- Access Control
    is_public BOOLEAN DEFAULT false,
    shared_with JSONB DEFAULT '[]',
    
    -- Statistics
    total_questions INTEGER DEFAULT 0,
    
    -- Metadata
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT question_banks_difficulty_valid CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'expert')),
    CONSTRAINT question_banks_total_questions_positive CHECK (total_questions >= 0)
);

-- =====================================================
-- QUESTIONS
-- =====================================================

CREATE TABLE assessment.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_bank_id UUID NOT NULL REFERENCES assessment.question_banks(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    -- Question Content
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL,
    difficulty_level VARCHAR(20) DEFAULT 'medium',
    points INTEGER DEFAULT 1,
    
    -- Question Data (answers, options, etc.)
    question_data JSONB NOT NULL DEFAULT '{}',
    correct_answer JSONB,
    explanation TEXT,
    
    -- Media
    image_url VARCHAR(500),
    audio_url VARCHAR(500),
    video_url VARCHAR(500),
    
    -- Metadata
    subject VARCHAR(100),
    topic VARCHAR(100),
    learning_objective VARCHAR(255),
    bloom_taxonomy_level VARCHAR(50),
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Usage Statistics
    usage_count INTEGER DEFAULT 0,
    correct_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    reviewed_by UUID REFERENCES user_management.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT questions_type_valid CHECK (
        question_type IN ('multiple_choice', 'true_false', 'short_answer', 'essay', 'fill_blank', 
                         'matching', 'ordering', 'numeric', 'file_upload', 'code')
    ),
    CONSTRAINT questions_difficulty_valid CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'expert')),
    CONSTRAINT questions_points_positive CHECK (points > 0),
    CONSTRAINT questions_usage_count_positive CHECK (usage_count >= 0),
    CONSTRAINT questions_correct_rate_range CHECK (correct_rate >= 0 AND correct_rate <= 100),
    CONSTRAINT questions_bloom_taxonomy_valid CHECK (
        bloom_taxonomy_level IN ('remember', 'understand', 'apply', 'analyze', 'evaluate', 'create')
    )
);

-- =====================================================
-- ASSESSMENTS (QUIZZES/EXAMS)
-- =====================================================

CREATE TABLE assessment.assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    course_id UUID REFERENCES course_management.courses(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES course_management.lessons(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructions TEXT,
    assessment_type VARCHAR(50) NOT NULL,
    
    -- Timing
    time_limit_minutes INTEGER,
    available_from TIMESTAMP WITH TIME ZONE,
    available_until TIMESTAMP WITH TIME ZONE,
    
    -- Attempt Settings
    max_attempts INTEGER DEFAULT 1,
    allow_review BOOLEAN DEFAULT true,
    show_correct_answers BOOLEAN DEFAULT false,
    show_score_immediately BOOLEAN DEFAULT true,
    
    -- Grading
    total_points INTEGER DEFAULT 0,
    passing_score DECIMAL(5,2) DEFAULT 60.00,
    grading_method VARCHAR(20) DEFAULT 'highest',
    
    -- Randomization
    randomize_questions BOOLEAN DEFAULT false,
    randomize_answers BOOLEAN DEFAULT false,
    questions_per_page INTEGER DEFAULT 1,
    
    -- Security
    require_lockdown_browser BOOLEAN DEFAULT false,
    prevent_backtracking BOOLEAN DEFAULT false,
    require_webcam BOOLEAN DEFAULT false,
    
    -- Status
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT assessments_type_valid CHECK (
        assessment_type IN ('quiz', 'exam', 'assignment', 'survey', 'practice', 'certification')
    ),
    CONSTRAINT assessments_time_limit_positive CHECK (time_limit_minutes IS NULL OR time_limit_minutes > 0),
    CONSTRAINT assessments_max_attempts_positive CHECK (max_attempts > 0),
    CONSTRAINT assessments_total_points_positive CHECK (total_points >= 0),
    CONSTRAINT assessments_passing_score_range CHECK (passing_score >= 0 AND passing_score <= 100),
    CONSTRAINT assessments_grading_method_valid CHECK (grading_method IN ('highest', 'latest', 'average', 'first')),
    CONSTRAINT assessments_questions_per_page_positive CHECK (questions_per_page > 0)
);

-- =====================================================
-- ASSESSMENT QUESTIONS
-- =====================================================

CREATE TABLE assessment.assessment_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES assessment.assessments(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES assessment.questions(id) ON DELETE CASCADE,
    
    sort_order INTEGER DEFAULT 0,
    points_override INTEGER,
    is_required BOOLEAN DEFAULT true,
    
    -- Question-specific settings
    settings JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(assessment_id, question_id),
    CONSTRAINT assessment_questions_points_override_positive CHECK (points_override IS NULL OR points_override > 0)
);

-- =====================================================
-- ASSESSMENT ATTEMPTS
-- =====================================================

CREATE TABLE assessment.assessment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES assessment.assessments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Attempt Details
    attempt_number INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'in_progress',
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP WITH TIME ZONE,
    time_spent_seconds INTEGER DEFAULT 0,
    
    -- Scoring
    total_score DECIMAL(8,2) DEFAULT 0.00,
    percentage_score DECIMAL(5,2) DEFAULT 0.00,
    passed BOOLEAN DEFAULT false,
    
    -- Grading
    graded_by UUID REFERENCES user_management.users(id),
    graded_at TIMESTAMP WITH TIME ZONE,
    feedback TEXT,
    
    -- Security and Monitoring
    ip_address INET,
    user_agent TEXT,
    browser_info JSONB,
    security_flags JSONB DEFAULT '{}',
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    CONSTRAINT assessment_attempts_attempt_number_positive CHECK (attempt_number > 0),
    CONSTRAINT assessment_attempts_status_valid CHECK (
        status IN ('in_progress', 'submitted', 'graded', 'abandoned', 'flagged')
    ),
    CONSTRAINT assessment_attempts_time_spent_positive CHECK (time_spent_seconds >= 0),
    CONSTRAINT assessment_attempts_total_score_positive CHECK (total_score >= 0),
    CONSTRAINT assessment_attempts_percentage_range CHECK (percentage_score >= 0 AND percentage_score <= 100)
);

-- =====================================================
-- QUESTION RESPONSES
-- =====================================================

CREATE TABLE assessment.question_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES assessment.assessment_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES assessment.questions(id) ON DELETE CASCADE,
    
    -- Response Data
    response_data JSONB NOT NULL DEFAULT '{}',
    response_text TEXT,
    file_uploads JSONB DEFAULT '[]',
    
    -- Scoring
    points_earned DECIMAL(8,2) DEFAULT 0.00,
    is_correct BOOLEAN,
    
    -- Timing
    time_spent_seconds INTEGER DEFAULT 0,
    answered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Grading (for manual grading)
    graded_by UUID REFERENCES user_management.users(id),
    graded_at TIMESTAMP WITH TIME ZONE,
    grader_feedback TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(attempt_id, question_id),
    CONSTRAINT question_responses_points_earned_positive CHECK (points_earned >= 0),
    CONSTRAINT question_responses_time_spent_positive CHECK (time_spent_seconds >= 0)
);

-- =====================================================
-- ASSIGNMENTS
-- =====================================================

CREATE TABLE assessment.assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    course_id UUID REFERENCES course_management.courses(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES course_management.lessons(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT,
    
    -- Submission Requirements
    submission_type VARCHAR(50) NOT NULL,
    max_file_size_mb INTEGER DEFAULT 10,
    allowed_file_types TEXT[],
    max_files INTEGER DEFAULT 1,
    
    -- Timing
    available_from TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    late_submission_allowed BOOLEAN DEFAULT false,
    late_penalty_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    -- Grading
    total_points INTEGER NOT NULL,
    grading_rubric JSONB,
    auto_grading_enabled BOOLEAN DEFAULT false,
    
    -- Peer Review
    peer_review_enabled BOOLEAN DEFAULT false,
    peer_reviews_required INTEGER DEFAULT 0,
    
    -- Status
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT assignments_submission_type_valid CHECK (
        submission_type IN ('file_upload', 'text_entry', 'url_submission', 'media_recording')
    ),
    CONSTRAINT assignments_max_file_size_positive CHECK (max_file_size_mb > 0),
    CONSTRAINT assignments_max_files_positive CHECK (max_files > 0),
    CONSTRAINT assignments_total_points_positive CHECK (total_points > 0),
    CONSTRAINT assignments_late_penalty_range CHECK (late_penalty_percentage >= 0 AND late_penalty_percentage <= 100),
    CONSTRAINT assignments_peer_reviews_positive CHECK (peer_reviews_required >= 0)
);

-- =====================================================
-- ASSIGNMENT SUBMISSIONS
-- =====================================================

CREATE TABLE assessment.assignment_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES assessment.assignments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Submission Content
    submission_text TEXT,
    file_uploads JSONB DEFAULT '[]',
    submission_url VARCHAR(500),
    
    -- Submission Details
    submission_type VARCHAR(50) NOT NULL,
    is_late BOOLEAN DEFAULT false,
    late_penalty_applied DECIMAL(5,2) DEFAULT 0.00,
    
    -- Grading
    score DECIMAL(8,2),
    percentage_score DECIMAL(5,2),
    graded_by UUID REFERENCES user_management.users(id),
    graded_at TIMESTAMP WITH TIME ZONE,
    feedback TEXT,
    rubric_scores JSONB,
    
    -- Status
    status VARCHAR(20) DEFAULT 'submitted',
    
    -- Timestamps
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(assignment_id, user_id),
    CONSTRAINT assignment_submissions_submission_type_valid CHECK (
        submission_type IN ('file_upload', 'text_entry', 'url_submission', 'media_recording')
    ),
    CONSTRAINT assignment_submissions_score_positive CHECK (score IS NULL OR score >= 0),
    CONSTRAINT assignment_submissions_percentage_range CHECK (percentage_score IS NULL OR (percentage_score >= 0 AND percentage_score <= 100)),
    CONSTRAINT assignment_submissions_late_penalty_range CHECK (late_penalty_applied >= 0 AND late_penalty_applied <= 100),
    CONSTRAINT assignment_submissions_status_valid CHECK (
        status IN ('draft', 'submitted', 'graded', 'returned', 'resubmitted')
    )
);

-- =====================================================
-- PEER REVIEWS
-- =====================================================

CREATE TABLE assessment.peer_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES assessment.assignments(id) ON DELETE CASCADE,
    submission_id UUID NOT NULL REFERENCES assessment.assignment_submissions(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Review Content
    review_score DECIMAL(8,2),
    review_feedback TEXT,
    rubric_scores JSONB,
    
    -- Review Status
    status VARCHAR(20) DEFAULT 'assigned',
    is_anonymous BOOLEAN DEFAULT true,
    
    -- Timestamps
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(submission_id, reviewer_id),
    CONSTRAINT peer_reviews_score_positive CHECK (review_score IS NULL OR review_score >= 0),
    CONSTRAINT peer_reviews_status_valid CHECK (
        status IN ('assigned', 'in_progress', 'submitted', 'overdue')
    )
);

-- =====================================================
-- GRADING RUBRICS
-- =====================================================

CREATE TABLE assessment.grading_rubrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Rubric Structure
    criteria JSONB NOT NULL DEFAULT '[]',
    total_points INTEGER NOT NULL,
    
    -- Usage
    is_public BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT grading_rubrics_total_points_positive CHECK (total_points > 0),
    CONSTRAINT grading_rubrics_usage_count_positive CHECK (usage_count >= 0)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Question Banks
CREATE INDEX idx_question_banks_organization ON assessment.question_banks(organization_id);
CREATE INDEX idx_question_banks_created_by ON assessment.question_banks(created_by);
CREATE INDEX idx_question_banks_public ON assessment.question_banks(is_public);
CREATE INDEX idx_question_banks_subject ON assessment.question_banks(subject);
CREATE INDEX idx_question_banks_difficulty ON assessment.question_banks(difficulty_level);

-- Questions
CREATE INDEX idx_questions_question_bank ON assessment.questions(question_bank_id);
CREATE INDEX idx_questions_created_by ON assessment.questions(created_by);
CREATE INDEX idx_questions_type ON assessment.questions(question_type);
CREATE INDEX idx_questions_difficulty ON assessment.questions(difficulty_level);
CREATE INDEX idx_questions_subject ON assessment.questions(subject);
CREATE INDEX idx_questions_topic ON assessment.questions(topic);
CREATE INDEX idx_questions_active ON assessment.questions(is_active);
CREATE INDEX idx_questions_tags ON assessment.questions USING GIN(tags);
CREATE INDEX idx_questions_search ON assessment.questions USING GIN(to_tsvector('english', question_text));

-- Assessments
CREATE INDEX idx_assessments_organization ON assessment.assessments(organization_id);
CREATE INDEX idx_assessments_course ON assessment.assessments(course_id);
CREATE INDEX idx_assessments_lesson ON assessment.assessments(lesson_id);
CREATE INDEX idx_assessments_created_by ON assessment.assessments(created_by);
CREATE INDEX idx_assessments_type ON assessment.assessments(assessment_type);
CREATE INDEX idx_assessments_published ON assessment.assessments(is_published);
CREATE INDEX idx_assessments_availability ON assessment.assessments(available_from, available_until);

-- Assessment Questions
CREATE INDEX idx_assessment_questions_assessment ON assessment.assessment_questions(assessment_id);
CREATE INDEX idx_assessment_questions_question ON assessment.assessment_questions(question_id);
CREATE INDEX idx_assessment_questions_sort_order ON assessment.assessment_questions(sort_order);

-- Assessment Attempts
CREATE INDEX idx_assessment_attempts_assessment ON assessment.assessment_attempts(assessment_id);
CREATE INDEX idx_assessment_attempts_user ON assessment.assessment_attempts(user_id);
CREATE INDEX idx_assessment_attempts_status ON assessment.assessment_attempts(status);
CREATE INDEX idx_assessment_attempts_started_at ON assessment.assessment_attempts(started_at);
CREATE INDEX idx_assessment_attempts_submitted_at ON assessment.assessment_attempts(submitted_at);
CREATE INDEX idx_assessment_attempts_graded_by ON assessment.assessment_attempts(graded_by);

-- Question Responses
CREATE INDEX idx_question_responses_attempt ON assessment.question_responses(attempt_id);
CREATE INDEX idx_question_responses_question ON assessment.question_responses(question_id);
CREATE INDEX idx_question_responses_graded_by ON assessment.question_responses(graded_by);
CREATE INDEX idx_question_responses_answered_at ON assessment.question_responses(answered_at);

-- Assignments
CREATE INDEX idx_assignments_organization ON assessment.assignments(organization_id);
CREATE INDEX idx_assignments_course ON assessment.assignments(course_id);
CREATE INDEX idx_assignments_lesson ON assessment.assignments(lesson_id);
CREATE INDEX idx_assignments_created_by ON assessment.assignments(created_by);
CREATE INDEX idx_assignments_published ON assessment.assignments(is_published);
CREATE INDEX idx_assignments_due_date ON assessment.assignments(due_date);
CREATE INDEX idx_assignments_peer_review ON assessment.assignments(peer_review_enabled);

-- Assignment Submissions
CREATE INDEX idx_assignment_submissions_assignment ON assessment.assignment_submissions(assignment_id);
CREATE INDEX idx_assignment_submissions_user ON assessment.assignment_submissions(user_id);
CREATE INDEX idx_assignment_submissions_status ON assessment.assignment_submissions(status);
CREATE INDEX idx_assignment_submissions_graded_by ON assessment.assignment_submissions(graded_by);
CREATE INDEX idx_assignment_submissions_submitted_at ON assessment.assignment_submissions(submitted_at);

-- Peer Reviews
CREATE INDEX idx_peer_reviews_assignment ON assessment.peer_reviews(assignment_id);
CREATE INDEX idx_peer_reviews_submission ON assessment.peer_reviews(submission_id);
CREATE INDEX idx_peer_reviews_reviewer ON assessment.peer_reviews(reviewer_id);
CREATE INDEX idx_peer_reviews_status ON assessment.peer_reviews(status);
CREATE INDEX idx_peer_reviews_assigned_at ON assessment.peer_reviews(assigned_at);

-- Grading Rubrics
CREATE INDEX idx_grading_rubrics_organization ON assessment.grading_rubrics(organization_id);
CREATE INDEX idx_grading_rubrics_created_by ON assessment.grading_rubrics(created_by);
CREATE INDEX idx_grading_rubrics_public ON assessment.grading_rubrics(is_public);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE TRIGGER update_question_banks_updated_at BEFORE UPDATE ON assessment.question_banks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON assessment.questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessment.assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignments_updated_at BEFORE UPDATE ON assessment.assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignment_submissions_last_modified_at BEFORE UPDATE ON assessment.assignment_submissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grading_rubrics_updated_at BEFORE UPDATE ON assessment.grading_rubrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON SCHEMA assessment IS 'Assessment schema containing quizzes, assignments, submissions, and grading';

COMMENT ON TABLE assessment.question_banks IS 'Collections of questions organized by subject or topic';
COMMENT ON TABLE assessment.questions IS 'Individual questions that can be used in assessments';
COMMENT ON TABLE assessment.assessments IS 'Quizzes, exams, and other assessments';
COMMENT ON TABLE assessment.assessment_questions IS 'Questions included in specific assessments';
COMMENT ON TABLE assessment.assessment_attempts IS 'User attempts at taking assessments';
COMMENT ON TABLE assessment.question_responses IS 'Individual question responses within assessment attempts';
COMMENT ON TABLE assessment.assignments IS 'Assignment definitions and requirements';
COMMENT ON TABLE assessment.assignment_submissions IS 'Student submissions for assignments';
COMMENT ON TABLE assessment.peer_reviews IS 'Peer review assignments and submissions';
COMMENT ON TABLE assessment.grading_rubrics IS 'Reusable grading rubrics for assessments and assignments';

-- Reset search path
SET search_path TO public;

