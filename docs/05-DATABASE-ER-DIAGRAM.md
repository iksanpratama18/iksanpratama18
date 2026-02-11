# 🗺️ Entity Relationship Diagram - E-Learning Gamification Platform

## 📋 OVERVIEW

Dokumen ini menjelaskan relasi antar tabel dalam database platform e-learning gamification.

## 🔗 RELATIONSHIP SUMMARY

### 1. USER & ORGANIZATION RELATIONSHIPS

```
t_organizations (1) ----< (N) t_departments
t_organizations (1) ----< (N) t_teams
t_organizations (1) ----< (N) t_users
t_departments (1) ----< (N) t_users
t_teams (1) ----< (N) t_users
t_departments (1) ----< (N) t_departments (self-referencing for hierarchy)
t_users (1) ----< (N) t_users (self-referencing for manager)
config_roles (1) ----< (N) t_user_roles
t_users (1) ----< (N) t_user_roles
```

**Key Points:**
- Organization memiliki banyak departments, teams, dan users
- Department bisa memiliki sub-departments (hierarchical)
- User bisa memiliki manager (juga user)
- User bisa memiliki multiple roles (many-to-many via t_user_roles)

### 2. COURSE & CONTENT RELATIONSHIPS

```
t_organizations (1) ----< (N) t_courses
config_course_categories (1) ----< (N) t_courses
config_course_difficulty (1) ----< (N) t_courses
config_course_status (1) ----< (N) t_courses
t_users (1) ----< (N) t_courses (as instructor)
t_courses (1) ----< (N) t_course_modules
t_course_modules (1) ----< (N) t_lessons
config_lesson_types (1) ----< (N) t_lessons
t_courses (1) ----< (N) t_quizzes
t_lessons (1) ----< (N) t_quizzes
t_quizzes (1) ----< (N) t_questions
config_question_types (1) ----< (N) t_questions
t_questions (1) ----< (N) t_question_options
```

**Key Points:**
- Course structure: Course → Modules → Lessons
- Quiz bisa attached ke Course atau Lesson
- Questions memiliki multiple options
- Semua menggunakan config tables untuk standardisasi

### 3. ENROLLMENT & PROGRESS RELATIONSHIPS

```
t_users (1) ----< (N) m_course_enrollments
t_courses (1) ----< (N) m_course_enrollments
config_enrollment_status (1) ----< (N) m_course_enrollments
m_course_enrollments (1) ----< (N) m_lesson_progress
t_lessons (1) ----< (N) m_lesson_progress
t_users (1) ----< (N) m_quiz_attempts
t_quizzes (1) ----< (N) m_quiz_attempts
m_course_enrollments (1) ----< (N) m_quiz_attempts
m_quiz_attempts (1) ----< (N) m_quiz_answers
t_questions (1) ----< (N) m_quiz_answers
t_question_options (1) ----< (N) m_quiz_answers
```

**Key Points:**
- Enrollment adalah junction antara User dan Course
- Lesson progress tracked per enrollment
- Quiz attempts tracked dengan history
- Quiz answers stored untuk review

### 4. GAMIFICATION RELATIONSHIPS

```
t_users (1) ----< (N) m_user_points
config_point_actions (1) ----< (N) m_user_points
t_users (1) ---- (1) t_user_gamification_stats (one-to-one)
config_levels (1) ----< (N) t_user_gamification_stats
config_badge_categories (1) ----< (N) t_badges
config_badge_rarity (1) ----< (N) t_badges
t_users (1) ----< (N) m_user_badges
t_badges (1) ----< (N) m_user_badges
```

**Key Points:**
- User points tracked dengan detail per action
- User gamification stats adalah aggregate table (one-to-one dengan user)
- Badges earned tracked dalam m_user_badges
- Level system menggunakan config_levels

### 5. LEADERBOARD & RANKING RELATIONSHIPS

```
config_leaderboard_types (1) ----< (N) m_leaderboard_snapshots
config_leaderboard_types (1) ----< (N) m_user_rankings
t_users (1) ----< (N) m_user_rankings
```

**Key Points:**
- Leaderboard snapshots untuk historical data
- User rankings calculated periodically
- Support multiple leaderboard types (global, department, team, course)

### 6. QUEST & CHALLENGE RELATIONSHIPS

```
config_quest_types (1) ----< (N) t_quests
t_badges (1) ----< (N) t_quests (optional reward)
t_users (1) ----< (N) m_user_quests
t_quests (1) ----< (N) m_user_quests
t_users (1) ----< (N) t_challenges (as creator)
t_challenges (1) ----< (N) m_challenge_participants
t_users (1) ----< (N) m_challenge_participants
t_teams (1) ----< (N) m_challenge_participants (for team challenges)
```

**Key Points:**
- Quests assigned ke users
- Challenges bisa individual atau team-based
- Progress tracked dalam JSONB untuk flexibility

### 7. STREAK SYSTEM RELATIONSHIPS

```
t_users (1) ----< (N) m_user_streaks
t_users (1) ----< (N) m_streak_freezes
```

**Key Points:**
- Daily activity tracked dalam m_user_streaks
- Streak freezes tracked separately
- Streak calculation done via query

### 8. SOCIAL & FORUM RELATIONSHIPS

```
t_forum_categories (1) ----< (N) t_forum_threads
t_courses (1) ----< (N) t_forum_threads (optional)
t_users (1) ----< (N) t_forum_threads
t_forum_threads (1) ----< (N) t_forum_replies
t_users (1) ----< (N) t_forum_replies
t_forum_replies (1) ----< (N) t_forum_replies (self-referencing for nested replies)
t_users (1) ----< (N) m_forum_upvotes
t_forum_replies (1) ----< (N) m_forum_upvotes
```

**Key Points:**
- Forum threads bisa general atau course-specific
- Replies bisa nested (parent_reply_id)
- Upvotes tracked separately

### 9. NOTIFICATION RELATIONSHIPS

```
config_notification_types (1) ----< (N) m_notifications
t_users (1) ----< (N) m_notifications
```

**Key Points:**
- Notifications sent ke individual users
- Type determines notification behavior

### 10. CERTIFICATE RELATIONSHIPS

```
t_users (1) ----< (N) t_certificates
t_courses (1) ----< (N) t_certificates
m_course_enrollments (1) ----< (N) t_certificates
```

**Key Points:**
- Certificate issued per user per course
- Linked to enrollment untuk tracking

### 11. ANALYTICS RELATIONSHIPS

```
t_users (1) ----< (N) m_user_activity_logs
t_organizations (1) ----< (N) m_daily_engagement_stats
```

**Key Points:**
- Activity logs untuk detailed tracking
- Daily stats untuk aggregate metrics

## 📊 CARDINALITY LEGEND

- **(1)** = One
- **(N)** = Many
- **----<** = One-to-Many relationship
- **----** = One-to-One relationship
- **>----<** = Many-to-Many relationship (via junction table)

## 🔑 KEY DESIGN DECISIONS

### 1. Config Tables
Semua lookup values (status, types, categories) disimpan dalam config tables untuk:
- Easy maintenance
- Referential integrity
- Consistent data
- Easy to add new values

### 2. JSONB Fields
Digunakan untuk:
- Flexible data structures (criteria, progress, unlocks)
- Avoid schema changes untuk new features
- Store complex nested data

### 3. Soft Deletes
Menggunakan `is_active` flag instead of hard deletes untuk:
- Data integrity
- Audit trail
- Ability to restore

### 4. Timestamps
Semua tables memiliki:
- `created_at` untuk tracking creation
- `updated_at` untuk tracking modifications (where applicable)

### 5. Indexes
Strategic indexes pada:
- Foreign keys
- Frequently queried columns
- Composite indexes untuk common query patterns

## 🎯 NORMALIZATION LEVEL

Database ini menggunakan **3rd Normal Form (3NF)** dengan beberapa denormalization untuk performance:

**Denormalized Fields:**
- `t_user_gamification_stats`: Aggregate data untuk quick access
- `progress_percentage` dalam `m_course_enrollments`: Calculated field
- `reply_count`, `view_count` dalam forum tables: Counter cache

**Justification:**
- Mengurangi complex joins untuk common queries
- Improve read performance
- Trade-off: Slightly more complex write logic

## 🔄 DATA FLOW EXAMPLES

### Example 1: User Completes a Lesson

```
1. User watches lesson → m_lesson_progress.is_completed = true
2. Trigger calculates course progress → m_course_enrollments.progress_percentage updated
3. Points awarded → INSERT into m_user_points
4. Trigger updates → t_user_gamification_stats.total_points
5. Check for badges → INSERT into m_user_badges (if criteria met)
6. Check for level up → t_user_gamification_stats.current_level updated
7. Notification sent → INSERT into m_notifications
8. Activity logged → INSERT into m_user_activity_logs
```

### Example 2: Daily Quest Completion

```
1. User completes quest criteria → m_user_quests.is_completed = true
2. Points awarded → INSERT into m_user_points
3. Badge awarded (if applicable) → INSERT into m_user_badges
4. Streak updated → INSERT/UPDATE m_user_streaks
5. Leaderboard recalculated → UPDATE m_user_rankings
6. Notification sent → INSERT into m_notifications
```

### Example 3: Forum Interaction

```
1. User posts reply → INSERT into t_forum_replies
2. Thread reply count updated → t_forum_threads.reply_count++
3. Points awarded → INSERT into m_user_points
4. Original poster notified → INSERT into m_notifications
5. Mentioned users notified → INSERT into m_notifications (multiple)
```

## 🛡️ DATA INTEGRITY CONSTRAINTS

### Foreign Key Constraints
- All foreign keys dengan ON DELETE CASCADE atau RESTRICT
- Ensures referential integrity

### Unique Constraints
- Prevent duplicate enrollments (user_id, course_id)
- Prevent duplicate badges (user_id, badge_id)
- Prevent duplicate upvotes (user_id, reply_id)

### Check Constraints (Recommended to Add)
```sql
ALTER TABLE m_course_enrollments 
ADD CONSTRAINT check_progress_percentage 
CHECK (progress_percentage >= 0 AND progress_percentage <= 100);

ALTER TABLE m_quiz_attempts 
ADD CONSTRAINT check_score_percentage 
CHECK (score_percentage >= 0 AND score_percentage <= 100);

ALTER TABLE t_quizzes 
ADD CONSTRAINT check_passing_score 
CHECK (passing_score_percentage >= 0 AND passing_score_percentage <= 100);
```

## 📈 SCALABILITY CONSIDERATIONS

### Partitioning Strategy (for large scale)

**Time-based Partitioning:**
```sql
-- Partition m_user_activity_logs by month
CREATE TABLE m_user_activity_logs_2024_01 PARTITION OF m_user_activity_logs
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Partition m_user_points by year
CREATE TABLE m_user_points_2024 PARTITION OF m_user_points
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

**Benefits:**
- Faster queries on recent data
- Easier archival of old data
- Better index performance

### Caching Strategy

**Redis Cache:**
- Leaderboard data (TTL: 5 minutes)
- User gamification stats (TTL: 1 minute)
- Course catalog (TTL: 1 hour)
- Badge definitions (TTL: 1 day)

**Application-level Cache:**
- Config tables (rarely change)
- User permissions
- Course structure

## 🔍 QUERY OPTIMIZATION TIPS

### 1. Use Views for Complex Queries
```sql
-- Already created: v_user_leaderboard, v_course_progress_summary
-- Add more as needed
```

### 2. Materialized Views for Heavy Aggregations
```sql
CREATE MATERIALIZED VIEW mv_department_stats AS
SELECT 
    d.department_id,
    d.department_name,
    COUNT(DISTINCT u.user_id) as total_users,
    SUM(ugs.total_points) as total_points,
    AVG(ugs.current_level) as avg_level
FROM t_departments d
LEFT JOIN t_users u ON d.department_id = u.department_id
LEFT JOIN t_user_gamification_stats ugs ON u.user_id = ugs.user_id
GROUP BY d.department_id, d.department_name;

-- Refresh periodically (e.g., hourly)
REFRESH MATERIALIZED VIEW mv_department_stats;
```

### 3. Index Usage
```sql
-- Composite index for common query pattern
CREATE INDEX idx_enrollments_user_course_status 
ON m_course_enrollments(user_id, course_id, status_id);

-- Partial index for active records only
CREATE INDEX idx_active_users 
ON t_users(user_id) WHERE is_active = true;
```

## 📝 MIGRATION STRATEGY

### Phase 1: Core Tables
1. Organizations & Users
2. Roles & Permissions
3. Courses & Content

### Phase 2: Learning Features
1. Enrollments & Progress
2. Quizzes & Assessments
3. Certificates

### Phase 3: Gamification
1. Points & Levels
2. Badges
3. Leaderboards

### Phase 4: Social & Advanced
1. Quests & Challenges
2. Streaks
3. Forum
4. Notifications

### Phase 5: Analytics
1. Activity Logs
2. Engagement Stats
3. Reporting Views

## 🎯 SUMMARY

Database ini dirancang untuk:
- ✅ Scalability (handle millions of users)
- ✅ Performance (optimized indexes & queries)
- ✅ Flexibility (JSONB for dynamic data)
- ✅ Integrity (foreign keys & constraints)
- ✅ Maintainability (clear structure & naming)
- ✅ Extensibility (easy to add new features)

**Total Tables:** 50+ tables
**Total Indexes:** 30+ indexes
**Total Views:** 2+ views (more can be added)
**Total Functions:** 2+ functions

