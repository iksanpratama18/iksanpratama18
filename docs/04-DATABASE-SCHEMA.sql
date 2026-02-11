-- ============================================
-- E-LEARNING GAMIFICATION PLATFORM
-- DATABASE SCHEMA (PostgreSQL)
-- ============================================

-- KONVENSI:
-- t_ = Table utama (master data)
-- m_ = Table transactional
-- config_ = Table konfigurasi/lookup

-- ============================================
-- 1. USER & ORGANIZATION TABLES
-- ============================================

CREATE TABLE t_organizations (
    organization_id BIGSERIAL PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    organization_code VARCHAR(50) UNIQUE NOT NULL,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    subscription_plan VARCHAR(50),
    sso_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_departments (
    department_id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES t_organizations(organization_id),
    parent_department_id BIGINT REFERENCES t_departments(department_id),
    department_name VARCHAR(255) NOT NULL,
    department_code VARCHAR(50) NOT NULL,
    manager_user_id BIGINT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_users (
    user_id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES t_organizations(organization_id),
    department_id BIGINT REFERENCES t_departments(department_id),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    job_title VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    last_activity_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE config_roles (
    role_id BIGSERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    role_display_name VARCHAR(100) NOT NULL,
    permissions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_user_roles (
    user_role_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES config_roles(role_id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

-- ============================================
-- 2. COURSE & CONTENT TABLES
-- ============================================

CREATE TABLE config_course_categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    parent_category_id BIGINT REFERENCES config_course_categories(category_id),
    icon_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE config_course_difficulty (
    difficulty_id SERIAL PRIMARY KEY,
    difficulty_name VARCHAR(50) UNIQUE NOT NULL,
    difficulty_level INTEGER UNIQUE NOT NULL,
    point_multiplier DECIMAL(3,2) DEFAULT 1.0
);

INSERT INTO config_course_difficulty (difficulty_name, difficulty_level, point_multiplier) VALUES
('Beginner', 1, 1.0),
('Intermediate', 2, 1.5),
('Advanced', 3, 2.0),
('Expert', 4, 2.5);

CREATE TABLE config_course_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL,
    status_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_course_status (status_name, status_code) VALUES
('Draft', 'draft'),
('Under Review', 'review'),
('Published', 'published'),
('Archived', 'archived');

CREATE TABLE t_courses (
    course_id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES t_organizations(organization_id),
    category_id BIGINT REFERENCES config_course_categories(category_id),
    difficulty_id INTEGER REFERENCES config_course_difficulty(difficulty_id),
    status_id INTEGER REFERENCES config_course_status(status_id),
    course_code VARCHAR(50) UNIQUE NOT NULL,
    course_title VARCHAR(255) NOT NULL,
    course_description TEXT,
    thumbnail_url TEXT,
    estimated_duration_minutes INTEGER,
    base_points INTEGER DEFAULT 100,
    is_mandatory BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    instructor_user_id BIGINT REFERENCES t_users(user_id),
    created_by BIGINT REFERENCES t_users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP
);

CREATE TABLE t_course_modules (
    module_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES t_courses(course_id) ON DELETE CASCADE,
    module_title VARCHAR(255) NOT NULL,
    module_description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE config_lesson_types (
    lesson_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    type_code VARCHAR(20) UNIQUE NOT NULL,
    point_multiplier DECIMAL(3,2) DEFAULT 1.0
);

INSERT INTO config_lesson_types (type_name, type_code, point_multiplier) VALUES
('Video', 'video', 1.0),
('Reading', 'reading', 0.8),
('Interactive', 'interactive', 1.5),
('Assignment', 'assignment', 2.0),
('Quiz', 'quiz', 1.2);

CREATE TABLE t_lessons (
    lesson_id BIGSERIAL PRIMARY KEY,
    module_id BIGINT NOT NULL REFERENCES t_course_modules(module_id) ON DELETE CASCADE,
    lesson_type_id INTEGER REFERENCES config_lesson_types(lesson_type_id),
    lesson_title VARCHAR(255) NOT NULL,
    lesson_description TEXT,
    content_url TEXT,
    content_data JSONB,
    estimated_duration_minutes INTEGER,
    base_points INTEGER DEFAULT 10,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. ASSESSMENT & QUIZ TABLES
-- ============================================

CREATE TABLE config_question_types (
    question_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    type_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_question_types (type_name, type_code) VALUES
('Multiple Choice', 'mcq'),
('True/False', 'truefalse'),
('Fill in the Blank', 'fillblank'),
('Essay', 'essay'),
('Matching', 'matching');

CREATE TABLE t_quizzes (
    quiz_id BIGSERIAL PRIMARY KEY,
    course_id BIGINT REFERENCES t_courses(course_id) ON DELETE CASCADE,
    lesson_id BIGINT REFERENCES t_lessons(lesson_id) ON DELETE CASCADE,
    quiz_title VARCHAR(255) NOT NULL,
    quiz_description TEXT,
    time_limit_minutes INTEGER,
    passing_score_percentage INTEGER DEFAULT 70,
    max_attempts INTEGER DEFAULT 3,
    randomize_questions BOOLEAN DEFAULT true,
    show_correct_answers BOOLEAN DEFAULT true,
    base_points INTEGER DEFAULT 50,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_questions (
    question_id BIGSERIAL PRIMARY KEY,
    quiz_id BIGINT NOT NULL REFERENCES t_quizzes(quiz_id) ON DELETE CASCADE,
    question_type_id INTEGER REFERENCES config_question_types(question_type_id),
    question_text TEXT NOT NULL,
    question_data JSONB,
    points INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_question_options (
    option_id BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL REFERENCES t_questions(question_id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0
);

-- ============================================
-- 4. ENROLLMENT & PROGRESS TABLES
-- ============================================

CREATE TABLE config_enrollment_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL,
    status_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_enrollment_status (status_name, status_code) VALUES
('Enrolled', 'enrolled'),
('In Progress', 'in_progress'),
('Completed', 'completed'),
('Dropped', 'dropped'),
('Expired', 'expired');

CREATE TABLE m_course_enrollments (
    enrollment_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    course_id BIGINT NOT NULL REFERENCES t_courses(course_id) ON DELETE CASCADE,
    status_id INTEGER REFERENCES config_enrollment_status(status_id),
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    deadline TIMESTAMP,
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    total_time_spent_minutes INTEGER DEFAULT 0,
    is_mandatory BOOLEAN DEFAULT false,
    assigned_by BIGINT REFERENCES t_users(user_id),
    UNIQUE(user_id, course_id)
);

CREATE TABLE m_lesson_progress (
    progress_id BIGSERIAL PRIMARY KEY,
    enrollment_id BIGINT NOT NULL REFERENCES m_course_enrollments(enrollment_id) ON DELETE CASCADE,
    lesson_id BIGINT NOT NULL REFERENCES t_lessons(lesson_id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT false,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    time_spent_minutes INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    last_accessed_at TIMESTAMP,
    UNIQUE(enrollment_id, lesson_id)
);

CREATE TABLE m_quiz_attempts (
    attempt_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    quiz_id BIGINT NOT NULL REFERENCES t_quizzes(quiz_id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES m_course_enrollments(enrollment_id) ON DELETE CASCADE,
    attempt_number INTEGER NOT NULL,
    score_percentage DECIMAL(5,2),
    points_earned INTEGER DEFAULT 0,
    is_passed BOOLEAN DEFAULT false,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP,
    time_taken_minutes INTEGER
);

CREATE TABLE m_quiz_answers (
    answer_id BIGSERIAL PRIMARY KEY,
    attempt_id BIGINT NOT NULL REFERENCES m_quiz_attempts(attempt_id) ON DELETE CASCADE,
    question_id BIGINT NOT NULL REFERENCES t_questions(question_id) ON DELETE CASCADE,
    selected_option_id BIGINT REFERENCES t_question_options(option_id),
    answer_text TEXT,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 5. GAMIFICATION CORE TABLES
-- ============================================

CREATE TABLE config_point_actions (
    action_id SERIAL PRIMARY KEY,
    action_name VARCHAR(100) UNIQUE NOT NULL,
    action_code VARCHAR(50) UNIQUE NOT NULL,
    base_points INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true
);

INSERT INTO config_point_actions (action_name, action_code, base_points) VALUES
('Complete Lesson', 'lesson_complete', 10),
('Pass Quiz', 'quiz_pass', 50),
('Complete Course', 'course_complete', 100),
('Daily Login', 'daily_login', 5),
('Forum Post', 'forum_post', 5),
('Forum Reply', 'forum_reply', 3),
('Upvote Received', 'upvote_received', 2),
('Best Answer', 'best_answer', 20),
('Profile Complete', 'profile_complete', 100),
('First Course', 'first_course', 100);

CREATE TABLE m_user_points (
    point_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    action_id INTEGER REFERENCES config_point_actions(action_id),
    points_earned INTEGER NOT NULL,
    multiplier DECIMAL(3,2) DEFAULT 1.0,
    final_points INTEGER NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    description TEXT,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_points_user ON m_user_points(user_id);
CREATE INDEX idx_user_points_earned_at ON m_user_points(earned_at);

CREATE TABLE t_user_gamification_stats (
    user_id BIGINT PRIMARY KEY REFERENCES t_users(user_id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    current_level_xp INTEGER DEFAULT 0,
    next_level_xp_required INTEGER DEFAULT 100,
    total_badges INTEGER DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    last_activity_date DATE,
    total_courses_completed INTEGER DEFAULT 0,
    total_lessons_completed INTEGER DEFAULT 0,
    total_quizzes_passed INTEGER DEFAULT 0,
    total_time_spent_minutes INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE config_levels (
    level_number INTEGER PRIMARY KEY,
    level_name VARCHAR(50) NOT NULL,
    xp_required INTEGER NOT NULL,
    cumulative_xp INTEGER NOT NULL,
    unlocks JSONB
);

-- Generate 100 levels
INSERT INTO config_levels (level_number, level_name, xp_required, cumulative_xp)
SELECT 
    level,
    CASE 
        WHEN level BETWEEN 1 AND 10 THEN 'Novice'
        WHEN level BETWEEN 11 AND 25 THEN 'Learner'
        WHEN level BETWEEN 26 AND 40 THEN 'Scholar'
        WHEN level BETWEEN 41 AND 60 THEN 'Expert'
        WHEN level BETWEEN 61 AND 80 THEN 'Master'
        ELSE 'Legend'
    END,
    100 * level * level + 50 * level,
    SUM(100 * level * level + 50 * level) OVER (ORDER BY level)
FROM generate_series(1, 100) AS level;

-- ============================================
-- 6. BADGE SYSTEM TABLES
-- ============================================

CREATE TABLE config_badge_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    category_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_badge_categories (category_name, category_code) VALUES
('Achievement', 'achievement'),
('Skill', 'skill'),
('Streak', 'streak'),
('Social', 'social'),
('Milestone', 'milestone'),
('Special', 'special');

CREATE TABLE config_badge_rarity (
    rarity_id SERIAL PRIMARY KEY,
    rarity_name VARCHAR(50) UNIQUE NOT NULL,
    rarity_code VARCHAR(20) UNIQUE NOT NULL,
    point_value INTEGER NOT NULL
);

INSERT INTO config_badge_rarity (rarity_name, rarity_code, point_value) VALUES
('Common', 'common', 50),
('Uncommon', 'uncommon', 100),
('Rare', 'rare', 250),
('Epic', 'epic', 500),
('Legendary', 'legendary', 1000);

CREATE TABLE t_badges (
    badge_id BIGSERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES config_badge_categories(category_id),
    rarity_id INTEGER REFERENCES config_badge_rarity(rarity_id),
    badge_name VARCHAR(100) UNIQUE NOT NULL,
    badge_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    criteria JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_user_badges (
    user_badge_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    badge_id BIGINT NOT NULL REFERENCES t_badges(badge_id),
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_showcased BOOLEAN DEFAULT false,
    UNIQUE(user_id, badge_id)
);

CREATE INDEX idx_user_badges_user ON m_user_badges(user_id);

-- ============================================
-- 7. LEADERBOARD TABLES
-- ============================================

CREATE TABLE config_leaderboard_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    type_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_leaderboard_types (type_name, type_code) VALUES
('Global', 'global'),
('Department', 'department'),
('Team', 'team'),
('Course', 'course');

CREATE TABLE m_leaderboard_snapshots (
    snapshot_id BIGSERIAL PRIMARY KEY,
    type_id INTEGER REFERENCES config_leaderboard_types(type_id),
    reference_id BIGINT,
    period_type VARCHAR(20),
    period_start DATE,
    period_end DATE,
    snapshot_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_user_rankings (
    ranking_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    type_id INTEGER REFERENCES config_leaderboard_types(type_id),
    reference_id BIGINT,
    period_type VARCHAR(20),
    current_rank INTEGER,
    previous_rank INTEGER,
    rank_change INTEGER,
    score INTEGER,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_rankings_user ON m_user_rankings(user_id);
CREATE INDEX idx_user_rankings_type ON m_user_rankings(type_id, reference_id, period_type);

-- ============================================
-- 8. QUEST & CHALLENGE TABLES
-- ============================================

CREATE TABLE config_quest_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    type_code VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO config_quest_types (type_name, type_code) VALUES
('Daily', 'daily'),
('Weekly', 'weekly'),
('Monthly', 'monthly'),
('Special Event', 'special');

CREATE TABLE t_quests (
    quest_id BIGSERIAL PRIMARY KEY,
    type_id INTEGER REFERENCES config_quest_types(type_id),
    quest_title VARCHAR(255) NOT NULL,
    quest_description TEXT,
    criteria JSONB NOT NULL,
    reward_points INTEGER NOT NULL,
    reward_badge_id BIGINT REFERENCES t_badges(badge_id),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_user_quests (
    user_quest_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    quest_id BIGINT NOT NULL REFERENCES t_quests(quest_id) ON DELETE CASCADE,
    progress JSONB,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, quest_id)
);

CREATE TABLE t_challenges (
    challenge_id BIGSERIAL PRIMARY KEY,
    challenge_title VARCHAR(255) NOT NULL,
    challenge_description TEXT,
    challenge_type VARCHAR(50),
    criteria JSONB NOT NULL,
    reward_points INTEGER NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_team_challenge BOOLEAN DEFAULT false,
    max_participants INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_by BIGINT REFERENCES t_users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_challenge_participants (
    participant_id BIGSERIAL PRIMARY KEY,
    challenge_id BIGINT NOT NULL REFERENCES t_challenges(challenge_id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES t_users(user_id) ON DELETE CASCADE,
    team_id BIGINT REFERENCES t_teams(team_id),
    progress JSONB,
    score INTEGER DEFAULT 0,
    rank INTEGER,
    is_completed BOOLEAN DEFAULT false,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 9. STREAK SYSTEM TABLES
-- ============================================

CREATE TABLE m_user_streaks (
    streak_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    activity_count INTEGER DEFAULT 1,
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, activity_date)
);

CREATE INDEX idx_user_streaks_user_date ON m_user_streaks(user_id, activity_date DESC);

CREATE TABLE m_streak_freezes (
    freeze_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    freeze_date DATE NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, freeze_date)
);

-- ============================================
-- 10. SOCIAL & FORUM TABLES
-- ============================================

CREATE TABLE t_forum_categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE t_forum_threads (
    thread_id BIGSERIAL PRIMARY KEY,
    category_id BIGINT REFERENCES t_forum_categories(category_id),
    course_id BIGINT REFERENCES t_courses(course_id),
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    thread_title VARCHAR(255) NOT NULL,
    thread_content TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT false,
    is_locked BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE t_forum_replies (
    reply_id BIGSERIAL PRIMARY KEY,
    thread_id BIGINT NOT NULL REFERENCES t_forum_threads(thread_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    parent_reply_id BIGINT REFERENCES t_forum_replies(reply_id),
    reply_content TEXT NOT NULL,
    is_best_answer BOOLEAN DEFAULT false,
    upvote_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_forum_upvotes (
    upvote_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    reply_id BIGINT NOT NULL REFERENCES t_forum_replies(reply_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, reply_id)
);

-- ============================================
-- 11. NOTIFICATION TABLES
-- ============================================

CREATE TABLE config_notification_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) UNIQUE NOT NULL,
    type_code VARCHAR(50) UNIQUE NOT NULL,
    default_enabled BOOLEAN DEFAULT true
);

CREATE TABLE m_notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    type_id INTEGER REFERENCES config_notification_types(type_id),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url TEXT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON m_notifications(user_id, is_read);

-- ============================================
-- 12. CERTIFICATE TABLES
-- ============================================

CREATE TABLE t_certificates (
    certificate_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    course_id BIGINT NOT NULL REFERENCES t_courses(course_id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES m_course_enrollments(enrollment_id),
    certificate_code VARCHAR(100) UNIQUE NOT NULL,
    certificate_url TEXT,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_valid BOOLEAN DEFAULT true,
    UNIQUE(user_id, course_id)
);

-- ============================================
-- 13. ANALYTICS TABLES
-- ============================================

CREATE TABLE m_user_activity_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES t_users(user_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    activity_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activity_logs_user ON m_user_activity_logs(user_id, created_at DESC);

CREATE TABLE m_daily_engagement_stats (
    stat_id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT REFERENCES t_organizations(organization_id),
    stat_date DATE NOT NULL,
    active_users INTEGER DEFAULT 0,
    new_enrollments INTEGER DEFAULT 0,
    completed_courses INTEGER DEFAULT 0,
    total_points_earned INTEGER DEFAULT 0,
    total_time_spent_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, stat_date)
);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

CREATE VIEW v_user_leaderboard AS
SELECT 
    u.user_id,
    u.full_name,
    u.avatar_url,
    u.department_id,
    ugs.total_points,
    ugs.current_level,
    ugs.total_badges,
    ugs.current_streak_days,
    ROW_NUMBER() OVER (ORDER BY ugs.total_points DESC, ugs.updated_at ASC) as rank
FROM t_users u
JOIN t_user_gamification_stats ugs ON u.user_id = ugs.user_id
WHERE u.is_active = true;

CREATE VIEW v_course_progress_summary AS
SELECT 
    ce.enrollment_id,
    ce.user_id,
    ce.course_id,
    c.course_title,
    ce.progress_percentage,
    ce.total_time_spent_minutes,
    COUNT(DISTINCT lp.lesson_id) as lessons_completed,
    COUNT(DISTINCT qa.attempt_id) as quizzes_attempted,
    ce.enrolled_at,
    ce.completed_at
FROM m_course_enrollments ce
JOIN t_courses c ON ce.course_id = c.course_id
LEFT JOIN m_lesson_progress lp ON ce.enrollment_id = lp.enrollment_id AND lp.is_completed = true
LEFT JOIN m_quiz_attempts qa ON ce.enrollment_id = qa.enrollment_id
GROUP BY ce.enrollment_id, ce.user_id, ce.course_id, c.course_title, 
         ce.progress_percentage, ce.total_time_spent_minutes, ce.enrolled_at, ce.completed_at;

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update user gamification stats
CREATE OR REPLACE FUNCTION update_user_gamification_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE t_user_gamification_stats
    SET 
        total_points = total_points + NEW.final_points,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gamification_stats
AFTER INSERT ON m_user_points
FOR EACH ROW
EXECUTE FUNCTION update_user_gamification_stats();

-- Function to calculate level from XP
CREATE OR REPLACE FUNCTION calculate_user_level(user_xp INTEGER)
RETURNS INTEGER AS $$
DECLARE
    user_level INTEGER;
BEGIN
    SELECT level_number INTO user_level
    FROM config_levels
    WHERE cumulative_xp <= user_xp
    ORDER BY level_number DESC
    LIMIT 1;
    
    RETURN COALESCE(user_level, 1);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_enrollments_user_status ON m_course_enrollments(user_id, status_id);
CREATE INDEX idx_enrollments_course ON m_course_enrollments(course_id);
CREATE INDEX idx_lesson_progress_enrollment ON m_lesson_progress(enrollment_id);
CREATE INDEX idx_quiz_attempts_user ON m_quiz_attempts(user_id, quiz_id);
CREATE INDEX idx_forum_threads_category ON t_forum_threads(category_id);
CREATE INDEX idx_forum_replies_thread ON t_forum_replies(thread_id);

-- ============================================
-- END OF SCHEMA
-- ============================================
