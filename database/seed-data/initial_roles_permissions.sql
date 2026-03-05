-- =====================================================
-- E-Learning Platform: Initial Roles and Permissions Seed Data
-- Description: Default system roles and permissions for the platform
-- =====================================================

SET search_path TO user_management, public;

-- =====================================================
-- SYSTEM PERMISSIONS
-- =====================================================

INSERT INTO permissions (name, slug, description, category, is_system_permission) VALUES
-- User Management Permissions
('View Users', 'view_users', 'View user profiles and basic information', 'user_management', true),
('Create Users', 'create_users', 'Create new user accounts', 'user_management', true),
('Edit Users', 'edit_users', 'Edit user profiles and information', 'user_management', true),
('Delete Users', 'delete_users', 'Delete user accounts', 'user_management', true),
('Manage User Roles', 'manage_user_roles', 'Assign and revoke user roles', 'user_management', true),
('View Organization', 'view_organization', 'View organization information', 'user_management', true),
('Edit Organization', 'edit_organization', 'Edit organization settings', 'user_management', true),

-- Course Management Permissions
('View Courses', 'view_courses', 'View course listings and details', 'course_management', true),
('Create Courses', 'create_courses', 'Create new courses', 'course_management', true),
('Edit Courses', 'edit_courses', 'Edit course content and settings', 'course_management', true),
('Delete Courses', 'delete_courses', 'Delete courses', 'course_management', true),
('Publish Courses', 'publish_courses', 'Publish and unpublish courses', 'course_management', true),
('Manage Enrollments', 'manage_enrollments', 'Enroll and unenroll students', 'course_management', true),
('View Course Analytics', 'view_course_analytics', 'View course performance analytics', 'course_management', true),

-- Content Management Permissions
('View Content', 'view_content', 'View content library', 'content_management', true),
('Create Content', 'create_content', 'Upload and create new content', 'content_management', true),
('Edit Content', 'edit_content', 'Edit existing content', 'content_management', true),
('Delete Content', 'delete_content', 'Delete content items', 'content_management', true),
('Manage Content Library', 'manage_content_library', 'Organize and manage content library', 'content_management', true),

-- Assessment Permissions
('View Assessments', 'view_assessments', 'View assessments and quizzes', 'assessment', true),
('Create Assessments', 'create_assessments', 'Create new assessments and quizzes', 'assessment', true),
('Edit Assessments', 'edit_assessments', 'Edit assessment content and settings', 'assessment', true),
('Delete Assessments', 'delete_assessments', 'Delete assessments', 'assessment', true),
('Grade Assessments', 'grade_assessments', 'Grade student submissions', 'assessment', true),
('View Assessment Results', 'view_assessment_results', 'View assessment results and analytics', 'assessment', true),
('Manage Question Banks', 'manage_question_banks', 'Create and manage question banks', 'assessment', true),

-- Gamification Permissions
('View Gamification', 'view_gamification', 'View points, badges, and leaderboards', 'gamification', true),
('Manage Gamification', 'manage_gamification', 'Configure gamification settings', 'gamification', true),
('Award Points', 'award_points', 'Manually award points to users', 'gamification', true),
('Award Badges', 'award_badges', 'Manually award badges to users', 'gamification', true),
('View Leaderboards', 'view_leaderboards', 'View leaderboard rankings', 'gamification', true),
('Manage Rewards', 'manage_rewards', 'Create and manage reward catalog', 'gamification', true),

-- Analytics Permissions
('View Analytics', 'view_analytics', 'View learning analytics and reports', 'analytics', true),
('View Advanced Analytics', 'view_advanced_analytics', 'View detailed analytics and insights', 'analytics', true),
('Export Data', 'export_data', 'Export analytics data and reports', 'analytics', true),
('View User Progress', 'view_user_progress', 'View individual user progress', 'analytics', true),

-- System Permissions
('System Administration', 'system_admin', 'Full system administration access', 'system', true),
('Manage System Settings', 'manage_system_settings', 'Configure system-wide settings', 'system', true),
('View System Logs', 'view_system_logs', 'View system audit logs', 'system', true),
('Manage Integrations', 'manage_integrations', 'Configure external integrations', 'system', true);

-- =====================================================
-- SYSTEM ROLES
-- =====================================================

-- Note: These will be created for each organization, but we define the templates here
-- The actual role creation will happen when organizations are created

-- Super Admin Role (System-wide)
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Super Administrator', 'super_admin', 'Full system access across all organizations', true, 
 '["system_admin", "manage_system_settings", "view_system_logs", "manage_integrations"]');

-- Organization Admin Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Organization Administrator', 'org_admin', 'Full administrative access within organization', true,
 '["view_organization", "edit_organization", "view_users", "create_users", "edit_users", "delete_users", 
   "manage_user_roles", "view_courses", "create_courses", "edit_courses", "delete_courses", "publish_courses",
   "manage_enrollments", "view_course_analytics", "view_content", "create_content", "edit_content", 
   "delete_content", "manage_content_library", "view_assessments", "create_assessments", "edit_assessments",
   "delete_assessments", "grade_assessments", "view_assessment_results", "manage_question_banks",
   "view_gamification", "manage_gamification", "award_points", "award_badges", "view_leaderboards",
   "manage_rewards", "view_analytics", "view_advanced_analytics", "export_data", "view_user_progress"]');

-- Instructor Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Instructor', 'instructor', 'Course instructor with teaching capabilities', true,
 '["view_users", "view_courses", "create_courses", "edit_courses", "publish_courses", "manage_enrollments",
   "view_course_analytics", "view_content", "create_content", "edit_content", "manage_content_library",
   "view_assessments", "create_assessments", "edit_assessments", "grade_assessments", "view_assessment_results",
   "manage_question_banks", "view_gamification", "award_points", "award_badges", "view_leaderboards",
   "view_analytics", "view_user_progress"]');

-- Teaching Assistant Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Teaching Assistant', 'teaching_assistant', 'Assistant instructor with limited teaching capabilities', true,
 '["view_users", "view_courses", "edit_courses", "manage_enrollments", "view_course_analytics",
   "view_content", "create_content", "edit_content", "view_assessments", "grade_assessments",
   "view_assessment_results", "view_gamification", "award_points", "view_leaderboards", "view_user_progress"]');

-- Content Creator Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Content Creator', 'content_creator', 'Content development and management specialist', true,
 '["view_courses", "create_courses", "edit_courses", "view_content", "create_content", "edit_content",
   "delete_content", "manage_content_library", "view_assessments", "create_assessments", "edit_assessments",
   "manage_question_banks", "view_gamification"]');

-- Student Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Student', 'student', 'Standard student access to learning content', true,
 '["view_courses", "view_content", "view_assessments", "view_gamification", "view_leaderboards"]');

-- Guest Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Guest', 'guest', 'Limited access for trial users', true,
 '["view_courses", "view_content"]');

-- Moderator Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Moderator', 'moderator', 'Community moderation and support', true,
 '["view_users", "view_courses", "view_content", "view_assessments", "grade_assessments",
   "view_gamification", "award_points", "award_badges", "view_analytics", "view_user_progress"]');

-- Analytics Specialist Role Template
INSERT INTO roles (name, slug, description, is_system_role, permissions) VALUES
('Analytics Specialist', 'analytics_specialist', 'Learning analytics and reporting specialist', true,
 '["view_courses", "view_course_analytics", "view_assessment_results", "view_gamification",
   "view_leaderboards", "view_analytics", "view_advanced_analytics", "export_data", "view_user_progress"]');

-- =====================================================
-- ROLE-PERMISSION MAPPINGS
-- =====================================================

-- This will be handled by the application logic when roles are assigned to organizations
-- The permissions JSON in the roles table above defines the default permissions for each role

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE permissions IS 'System permissions that can be granted to roles';
COMMENT ON TABLE roles IS 'System role templates that will be instantiated for each organization';

-- Reset search path
SET search_path TO public;

