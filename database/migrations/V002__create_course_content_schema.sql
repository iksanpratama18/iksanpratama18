-- =====================================================
-- E-Learning Platform: Course and Content Management Schema
-- Version: V002
-- Description: Courses, modules, lessons, learning paths, and content management
-- =====================================================

-- Create schemas
CREATE SCHEMA IF NOT EXISTS course_management;
CREATE SCHEMA IF NOT EXISTS content_management;

-- Set search path for this migration
SET search_path TO course_management, content_management, user_management, public;

-- =====================================================
-- COURSE CATEGORIES
-- =====================================================

CREATE TABLE course_management.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES course_management.categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT categories_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT categories_color_format CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT categories_no_self_reference CHECK (id != parent_id)
);

-- =====================================================
-- COURSES
-- =====================================================

CREATE TABLE course_management.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    category_id UUID REFERENCES course_management.categories(id) ON DELETE SET NULL,
    instructor_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    thumbnail_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    trailer_video_url VARCHAR(500),
    
    -- Course Details
    level VARCHAR(20) DEFAULT 'beginner',
    language VARCHAR(10) DEFAULT 'en',
    duration_minutes INTEGER,
    estimated_completion_hours DECIMAL(5,2),
    prerequisites TEXT[],
    learning_objectives TEXT[],
    target_audience TEXT,
    
    -- Pricing and Access
    price DECIMAL(10,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    is_free BOOLEAN DEFAULT true,
    access_type VARCHAR(20) DEFAULT 'public',
    enrollment_limit INTEGER,
    
    -- Status and Visibility
    status VARCHAR(20) DEFAULT 'draft',
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT false,
    
    -- Metadata
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    
    -- Statistics (updated by triggers)
    enrollment_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT courses_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT courses_level_valid CHECK (level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    CONSTRAINT courses_access_type_valid CHECK (access_type IN ('public', 'private', 'restricted')),
    CONSTRAINT courses_status_valid CHECK (status IN ('draft', 'review', 'published', 'archived')),
    CONSTRAINT courses_price_positive CHECK (price >= 0),
    CONSTRAINT courses_rating_range CHECK (average_rating >= 0 AND average_rating <= 5),
    CONSTRAINT courses_enrollment_limit_positive CHECK (enrollment_limit IS NULL OR enrollment_limit > 0)
);

-- =====================================================
-- COURSE MODULES
-- =====================================================

CREATE TABLE course_management.modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES course_management.courses(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES course_management.modules(id) ON DELETE CASCADE,
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    duration_minutes INTEGER,
    
    -- Access Control
    is_locked BOOLEAN DEFAULT false,
    unlock_conditions JSONB DEFAULT '{}',
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT modules_no_self_reference CHECK (id != parent_id)
);

-- =====================================================
-- LESSONS
-- =====================================================

CREATE TABLE course_management.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID NOT NULL REFERENCES course_management.modules(id) ON DELETE CASCADE,
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_type VARCHAR(50) NOT NULL,
    content_data JSONB NOT NULL DEFAULT '{}',
    sort_order INTEGER DEFAULT 0,
    duration_minutes INTEGER,
    
    -- Access Control
    is_preview BOOLEAN DEFAULT false,
    is_locked BOOLEAN DEFAULT false,
    unlock_conditions JSONB DEFAULT '{}',
    
    -- Completion Tracking
    completion_criteria JSONB DEFAULT '{}',
    points_reward INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT lessons_content_type_valid CHECK (
        content_type IN ('video', 'text', 'audio', 'interactive', 'quiz', 'assignment', 'scorm', 'external_link')
    ),
    CONSTRAINT lessons_points_positive CHECK (points_reward >= 0)
);

-- =====================================================
-- CONTENT MANAGEMENT
-- =====================================================

CREATE TABLE content_management.content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    -- Content Identification
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(100),
    content_type VARCHAR(50) NOT NULL,
    mime_type VARCHAR(100),
    
    -- Content Data
    content_data JSONB NOT NULL DEFAULT '{}',
    file_url VARCHAR(500),
    file_size BIGINT,
    duration_seconds INTEGER,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    parent_version_id UUID REFERENCES content_management.content_items(id),
    
    -- Metadata
    description TEXT,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Access Control
    visibility VARCHAR(20) DEFAULT 'private',
    license VARCHAR(100),
    copyright_info TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'draft',
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(organization_id, slug) WHERE slug IS NOT NULL,
    CONSTRAINT content_items_slug_format CHECK (slug IS NULL OR slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT content_items_content_type_valid CHECK (
        content_type IN ('video', 'audio', 'image', 'document', 'presentation', 'interactive', 'scorm', 'h5p')
    ),
    CONSTRAINT content_items_visibility_valid CHECK (visibility IN ('public', 'private', 'restricted')),
    CONSTRAINT content_items_status_valid CHECK (status IN ('draft', 'review', 'published', 'archived')),
    CONSTRAINT content_items_file_size_positive CHECK (file_size IS NULL OR file_size > 0),
    CONSTRAINT content_items_duration_positive CHECK (duration_seconds IS NULL OR duration_seconds > 0)
);

-- =====================================================
-- LEARNING PATHS
-- =====================================================

CREATE TABLE course_management.learning_paths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
    
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    thumbnail_url VARCHAR(500),
    
    -- Path Configuration
    is_sequential BOOLEAN DEFAULT true,
    estimated_duration_hours DECIMAL(5,2),
    difficulty_level VARCHAR(20) DEFAULT 'beginner',
    
    -- Access Control
    is_public BOOLEAN DEFAULT false,
    enrollment_limit INTEGER,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    
    -- Statistics
    enrollment_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    
    -- Metadata
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT learning_paths_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT learning_paths_difficulty_valid CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    CONSTRAINT learning_paths_enrollment_limit_positive CHECK (enrollment_limit IS NULL OR enrollment_limit > 0)
);

CREATE TABLE course_management.learning_path_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learning_path_id UUID NOT NULL REFERENCES course_management.learning_paths(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES course_management.courses(id) ON DELETE CASCADE,
    
    sort_order INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT true,
    unlock_conditions JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(learning_path_id, course_id)
);

-- =====================================================
-- COURSE ENROLLMENTS
-- =====================================================

CREATE TABLE course_management.enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES course_management.courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Enrollment Details
    enrollment_type VARCHAR(20) DEFAULT 'self',
    enrolled_by UUID REFERENCES user_management.users(id),
    enrollment_source VARCHAR(50),
    
    -- Progress Tracking
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    completed_lessons INTEGER DEFAULT 0,
    total_lessons INTEGER DEFAULT 0,
    last_accessed_lesson_id UUID REFERENCES course_management.lessons(id),
    
    -- Completion
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    completion_certificate_url VARCHAR(500),
    
    -- Access Control
    access_expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(course_id, user_id),
    CONSTRAINT enrollments_enrollment_type_valid CHECK (enrollment_type IN ('self', 'admin', 'bulk', 'invitation')),
    CONSTRAINT enrollments_progress_range CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT enrollments_completed_lessons_positive CHECK (completed_lessons >= 0),
    CONSTRAINT enrollments_total_lessons_positive CHECK (total_lessons >= 0),
    CONSTRAINT enrollments_completed_lessons_valid CHECK (completed_lessons <= total_lessons)
);

-- =====================================================
-- LESSON PROGRESS
-- =====================================================

CREATE TABLE course_management.lesson_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES course_management.enrollments(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES course_management.lessons(id) ON DELETE CASCADE,
    
    -- Progress Details
    status VARCHAR(20) DEFAULT 'not_started',
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    time_spent_seconds INTEGER DEFAULT 0,
    
    -- Completion
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Interaction Data
    interaction_data JSONB DEFAULT '{}',
    bookmarks JSONB DEFAULT '[]',
    notes TEXT,
    
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(enrollment_id, lesson_id),
    CONSTRAINT lesson_progress_status_valid CHECK (status IN ('not_started', 'in_progress', 'completed', 'skipped')),
    CONSTRAINT lesson_progress_percentage_range CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT lesson_progress_time_positive CHECK (time_spent_seconds >= 0)
);

-- =====================================================
-- COURSE REVIEWS AND RATINGS
-- =====================================================

CREATE TABLE course_management.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES course_management.courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    rating INTEGER NOT NULL,
    title VARCHAR(255),
    review_text TEXT,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES user_management.users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Helpfulness
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(course_id, user_id),
    CONSTRAINT reviews_rating_range CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT reviews_helpful_counts_positive CHECK (helpful_count >= 0 AND not_helpful_count >= 0)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Categories
CREATE INDEX idx_categories_organization ON course_management.categories(organization_id);
CREATE INDEX idx_categories_parent ON course_management.categories(parent_id);
CREATE INDEX idx_categories_active ON course_management.categories(is_active);
CREATE INDEX idx_categories_sort_order ON course_management.categories(sort_order);

-- Courses
CREATE INDEX idx_courses_organization ON course_management.courses(organization_id);
CREATE INDEX idx_courses_category ON course_management.courses(category_id);
CREATE INDEX idx_courses_instructor ON course_management.courses(instructor_id);
CREATE INDEX idx_courses_status ON course_management.courses(status);
CREATE INDEX idx_courses_published ON course_management.courses(is_published);
CREATE INDEX idx_courses_featured ON course_management.courses(is_featured);
CREATE INDEX idx_courses_level ON course_management.courses(level);
CREATE INDEX idx_courses_price ON course_management.courses(price);
CREATE INDEX idx_courses_created_at ON course_management.courses(created_at);
CREATE INDEX idx_courses_tags ON course_management.courses USING GIN(tags);
CREATE INDEX idx_courses_search ON course_management.courses USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Modules and Lessons
CREATE INDEX idx_modules_course ON course_management.modules(course_id);
CREATE INDEX idx_modules_parent ON course_management.modules(parent_id);
CREATE INDEX idx_modules_sort_order ON course_management.modules(sort_order);

CREATE INDEX idx_lessons_module ON course_management.lessons(module_id);
CREATE INDEX idx_lessons_content_type ON course_management.lessons(content_type);
CREATE INDEX idx_lessons_sort_order ON course_management.lessons(sort_order);
CREATE INDEX idx_lessons_preview ON course_management.lessons(is_preview);

-- Content Items
CREATE INDEX idx_content_items_organization ON content_management.content_items(organization_id);
CREATE INDEX idx_content_items_created_by ON content_management.content_items(created_by);
CREATE INDEX idx_content_items_content_type ON content_management.content_items(content_type);
CREATE INDEX idx_content_items_status ON content_management.content_items(status);
CREATE INDEX idx_content_items_published ON content_management.content_items(is_published);
CREATE INDEX idx_content_items_tags ON content_management.content_items USING GIN(tags);
CREATE INDEX idx_content_items_search ON content_management.content_items USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Learning Paths
CREATE INDEX idx_learning_paths_organization ON course_management.learning_paths(organization_id);
CREATE INDEX idx_learning_paths_created_by ON course_management.learning_paths(created_by);
CREATE INDEX idx_learning_paths_public ON course_management.learning_paths(is_public);
CREATE INDEX idx_learning_paths_active ON course_management.learning_paths(is_active);
CREATE INDEX idx_learning_paths_featured ON course_management.learning_paths(is_featured);

CREATE INDEX idx_learning_path_items_path ON course_management.learning_path_items(learning_path_id);
CREATE INDEX idx_learning_path_items_course ON course_management.learning_path_items(course_id);
CREATE INDEX idx_learning_path_items_sort_order ON course_management.learning_path_items(sort_order);

-- Enrollments and Progress
CREATE INDEX idx_enrollments_course ON course_management.enrollments(course_id);
CREATE INDEX idx_enrollments_user ON course_management.enrollments(user_id);
CREATE INDEX idx_enrollments_active ON course_management.enrollments(is_active);
CREATE INDEX idx_enrollments_completed ON course_management.enrollments(is_completed);
CREATE INDEX idx_enrollments_enrolled_at ON course_management.enrollments(enrolled_at);
CREATE INDEX idx_enrollments_last_accessed ON course_management.enrollments(last_accessed_at);

CREATE INDEX idx_lesson_progress_enrollment ON course_management.lesson_progress(enrollment_id);
CREATE INDEX idx_lesson_progress_lesson ON course_management.lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_status ON course_management.lesson_progress(status);
CREATE INDEX idx_lesson_progress_completed ON course_management.lesson_progress(is_completed);
CREATE INDEX idx_lesson_progress_last_accessed ON course_management.lesson_progress(last_accessed_at);

-- Reviews
CREATE INDEX idx_reviews_course ON course_management.reviews(course_id);
CREATE INDEX idx_reviews_user ON course_management.reviews(user_id);
CREATE INDEX idx_reviews_rating ON course_management.reviews(rating);
CREATE INDEX idx_reviews_approved ON course_management.reviews(is_approved);
CREATE INDEX idx_reviews_created_at ON course_management.reviews(created_at);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON course_management.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON course_management.courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON course_management.modules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON course_management.lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_items_updated_at BEFORE UPDATE ON content_management.content_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_paths_updated_at BEFORE UPDATE ON course_management.learning_paths
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON course_management.reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON SCHEMA course_management IS 'Course management schema containing courses, modules, lessons, and learning paths';
COMMENT ON SCHEMA content_management IS 'Content management schema for educational content and media';

COMMENT ON TABLE course_management.categories IS 'Hierarchical categories for organizing courses';
COMMENT ON TABLE course_management.courses IS 'Main courses offered in the platform';
COMMENT ON TABLE course_management.modules IS 'Course modules for organizing lessons hierarchically';
COMMENT ON TABLE course_management.lessons IS 'Individual lessons within course modules';
COMMENT ON TABLE content_management.content_items IS 'Reusable content items (videos, documents, etc.)';
COMMENT ON TABLE course_management.learning_paths IS 'Curated sequences of courses for specific learning goals';
COMMENT ON TABLE course_management.learning_path_items IS 'Courses included in learning paths';
COMMENT ON TABLE course_management.enrollments IS 'User enrollments in courses';
COMMENT ON TABLE course_management.lesson_progress IS 'Individual lesson progress tracking';
COMMENT ON TABLE course_management.reviews IS 'Course reviews and ratings by users';

-- Reset search path
SET search_path TO public;

