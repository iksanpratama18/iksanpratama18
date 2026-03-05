-- =====================================================
-- E-Learning Platform: Gamification Schema
-- Version: V003
-- Description: Points, badges, levels, achievements, and leaderboards
-- =====================================================

-- Create gamification schema
CREATE SCHEMA IF NOT EXISTS gamification;

-- Set search path for this migration
SET search_path TO gamification, course_management, user_management, public;

-- =====================================================
-- POINT SYSTEMS
-- =====================================================

CREATE TABLE gamification.point_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7),
    
    -- Point Configuration
    base_points_per_lesson INTEGER DEFAULT 10,
    base_points_per_quiz INTEGER DEFAULT 20,
    base_points_per_assignment INTEGER DEFAULT 50,
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.00,
    
    -- Rules and Settings
    rules JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT point_systems_slug_format CHECK (slug ~ '^[a-z0-9_]+$'),
    CONSTRAINT point_systems_color_format CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT point_systems_base_points_positive CHECK (
        base_points_per_lesson >= 0 AND 
        base_points_per_quiz >= 0 AND 
        base_points_per_assignment >= 0
    ),
    CONSTRAINT point_systems_multiplier_positive CHECK (bonus_multiplier >= 0)
);

-- =====================================================
-- USER POINTS
-- =====================================================

CREATE TABLE gamification.user_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    point_system_id UUID NOT NULL REFERENCES gamification.point_systems(id) ON DELETE CASCADE,
    
    -- Point Totals
    total_points INTEGER DEFAULT 0,
    available_points INTEGER DEFAULT 0,
    spent_points INTEGER DEFAULT 0,
    
    -- Lifetime Statistics
    lifetime_earned INTEGER DEFAULT 0,
    lifetime_spent INTEGER DEFAULT 0,
    
    -- Streaks and Bonuses
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    last_activity_date DATE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, point_system_id),
    CONSTRAINT user_points_totals_positive CHECK (
        total_points >= 0 AND 
        available_points >= 0 AND 
        spent_points >= 0 AND
        lifetime_earned >= 0 AND
        lifetime_spent >= 0
    ),
    CONSTRAINT user_points_balance_valid CHECK (total_points = available_points + spent_points),
    CONSTRAINT user_points_streaks_positive CHECK (current_streak_days >= 0 AND longest_streak_days >= 0)
);

-- =====================================================
-- POINT TRANSACTIONS
-- =====================================================

CREATE TABLE gamification.point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    point_system_id UUID NOT NULL REFERENCES gamification.point_systems(id) ON DELETE CASCADE,
    
    -- Transaction Details
    transaction_type VARCHAR(20) NOT NULL,
    points INTEGER NOT NULL,
    description TEXT,
    
    -- Source Information
    source_type VARCHAR(50),
    source_id UUID,
    reference_data JSONB DEFAULT '{}',
    
    -- Processing
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_by UUID REFERENCES user_management.users(id),
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT point_transactions_type_valid CHECK (transaction_type IN ('earned', 'spent', 'bonus', 'penalty', 'adjustment', 'refund')),
    CONSTRAINT point_transactions_source_type_valid CHECK (
        source_type IN ('lesson_completion', 'quiz_completion', 'assignment_submission', 
                       'course_completion', 'badge_earned', 'streak_bonus', 'manual', 'purchase', 'reward_redemption')
    )
);

-- =====================================================
-- EXPERIENCE LEVELS
-- =====================================================

CREATE TABLE gamification.experience_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    point_system_id UUID NOT NULL REFERENCES gamification.point_systems(id) ON DELETE CASCADE,
    
    level_number INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7),
    
    -- Level Requirements
    points_required INTEGER NOT NULL,
    points_to_next_level INTEGER,
    
    -- Rewards
    rewards JSONB DEFAULT '{}',
    unlocked_features JSONB DEFAULT '[]',
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, point_system_id, level_number),
    CONSTRAINT experience_levels_number_positive CHECK (level_number > 0),
    CONSTRAINT experience_levels_points_positive CHECK (points_required >= 0),
    CONSTRAINT experience_levels_color_format CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$')
);

-- =====================================================
-- USER LEVELS
-- =====================================================

CREATE TABLE gamification.user_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    point_system_id UUID NOT NULL REFERENCES gamification.point_systems(id) ON DELETE CASCADE,
    experience_level_id UUID NOT NULL REFERENCES gamification.experience_levels(id) ON DELETE CASCADE,
    
    -- Level Progress
    current_level_points INTEGER DEFAULT 0,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    -- Timestamps
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, point_system_id),
    CONSTRAINT user_levels_points_positive CHECK (current_level_points >= 0),
    CONSTRAINT user_levels_progress_range CHECK (progress_percentage >= 0 AND progress_percentage <= 100)
);

-- =====================================================
-- BADGE CATEGORIES
-- =====================================================

CREATE TABLE gamification.badge_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(7),
    sort_order INTEGER DEFAULT 0,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT badge_categories_slug_format CHECK (slug ~ '^[a-z0-9_]+$'),
    CONSTRAINT badge_categories_color_format CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$')
);

-- =====================================================
-- BADGES
-- =====================================================

CREATE TABLE gamification.badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    category_id UUID REFERENCES gamification.badge_categories(id) ON DELETE SET NULL,
    
    -- Badge Information
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    image_url VARCHAR(500),
    
    -- Badge Properties
    rarity VARCHAR(20) DEFAULT 'common',
    points_reward INTEGER DEFAULT 0,
    
    -- Earning Criteria
    criteria JSONB NOT NULL DEFAULT '{}',
    requirements JSONB DEFAULT '{}',
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    is_hidden BOOLEAN DEFAULT false,
    available_from TIMESTAMP WITH TIME ZONE,
    available_until TIMESTAMP WITH TIME ZONE,
    max_awards INTEGER,
    
    -- Statistics
    total_awarded INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT badges_slug_format CHECK (slug ~ '^[a-z0-9_]+$'),
    CONSTRAINT badges_rarity_valid CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    CONSTRAINT badges_points_positive CHECK (points_reward >= 0),
    CONSTRAINT badges_max_awards_positive CHECK (max_awards IS NULL OR max_awards > 0),
    CONSTRAINT badges_total_awarded_positive CHECK (total_awarded >= 0)
);

-- =====================================================
-- USER BADGES
-- =====================================================

CREATE TABLE gamification.user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES gamification.badges(id) ON DELETE CASCADE,
    
    -- Award Details
    awarded_by UUID REFERENCES user_management.users(id),
    award_reason TEXT,
    evidence JSONB DEFAULT '{}',
    
    -- Display
    is_featured BOOLEAN DEFAULT false,
    display_order INTEGER,
    
    -- Timestamps
    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, badge_id),
    CONSTRAINT user_badges_display_order_positive CHECK (display_order IS NULL OR display_order >= 0)
);

-- =====================================================
-- ACHIEVEMENTS
-- =====================================================

CREATE TABLE gamification.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    
    -- Achievement Information
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    
    -- Achievement Type
    achievement_type VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    
    -- Criteria and Rewards
    criteria JSONB NOT NULL DEFAULT '{}',
    points_reward INTEGER DEFAULT 0,
    badge_reward_id UUID REFERENCES gamification.badges(id),
    other_rewards JSONB DEFAULT '{}',
    
    -- Progress Tracking
    is_progressive BOOLEAN DEFAULT false,
    max_progress INTEGER,
    progress_unit VARCHAR(50),
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    is_secret BOOLEAN DEFAULT false,
    available_from TIMESTAMP WITH TIME ZONE,
    available_until TIMESTAMP WITH TIME ZONE,
    
    -- Statistics
    total_completed INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT achievements_slug_format CHECK (slug ~ '^[a-z0-9_]+$'),
    CONSTRAINT achievements_type_valid CHECK (
        achievement_type IN ('course_completion', 'streak', 'social', 'skill_mastery', 'time_based', 'custom')
    ),
    CONSTRAINT achievements_points_positive CHECK (points_reward >= 0),
    CONSTRAINT achievements_max_progress_positive CHECK (max_progress IS NULL OR max_progress > 0),
    CONSTRAINT achievements_total_completed_positive CHECK (total_completed >= 0)
);

-- =====================================================
-- USER ACHIEVEMENTS
-- =====================================================

CREATE TABLE gamification.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES gamification.achievements(id) ON DELETE CASCADE,
    
    -- Progress
    current_progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Evidence and Context
    evidence JSONB DEFAULT '{}',
    completion_data JSONB DEFAULT '{}',
    
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, achievement_id),
    CONSTRAINT user_achievements_progress_positive CHECK (current_progress >= 0)
);

-- =====================================================
-- LEADERBOARDS
-- =====================================================

CREATE TABLE gamification.leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    
    -- Leaderboard Configuration
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Leaderboard Type and Scope
    leaderboard_type VARCHAR(50) NOT NULL,
    scope VARCHAR(50) DEFAULT 'global',
    time_period VARCHAR(50) DEFAULT 'all_time',
    
    -- Filtering and Grouping
    filters JSONB DEFAULT '{}',
    grouping JSONB DEFAULT '{}',
    
    -- Display Settings
    max_entries INTEGER DEFAULT 100,
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
    -- Refresh Settings
    refresh_frequency VARCHAR(20) DEFAULT 'daily',
    last_refreshed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, slug),
    CONSTRAINT leaderboards_slug_format CHECK (slug ~ '^[a-z0-9_]+$'),
    CONSTRAINT leaderboards_type_valid CHECK (
        leaderboard_type IN ('points', 'badges', 'course_completions', 'streak', 'custom')
    ),
    CONSTRAINT leaderboards_scope_valid CHECK (scope IN ('global', 'course', 'category', 'group', 'custom')),
    CONSTRAINT leaderboards_time_period_valid CHECK (
        time_period IN ('all_time', 'yearly', 'monthly', 'weekly', 'daily')
    ),
    CONSTRAINT leaderboards_max_entries_positive CHECK (max_entries > 0),
    CONSTRAINT leaderboards_refresh_frequency_valid CHECK (
        refresh_frequency IN ('real_time', 'hourly', 'daily', 'weekly', 'manual')
    )
);

-- =====================================================
-- LEADERBOARD ENTRIES
-- =====================================================

CREATE TABLE gamification.leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leaderboard_id UUID NOT NULL REFERENCES gamification.leaderboards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Ranking
    rank_position INTEGER NOT NULL,
    score DECIMAL(15,2) NOT NULL,
    previous_rank INTEGER,
    rank_change INTEGER DEFAULT 0,
    
    -- Additional Data
    additional_data JSONB DEFAULT '{}',
    
    -- Timestamps
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(leaderboard_id, user_id),
    CONSTRAINT leaderboard_entries_rank_positive CHECK (rank_position > 0),
    CONSTRAINT leaderboard_entries_score_positive CHECK (score >= 0)
);

-- =====================================================
-- REWARDS AND REDEMPTIONS
-- =====================================================

CREATE TABLE gamification.rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES user_management.organizations(id) ON DELETE CASCADE,
    
    -- Reward Information
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    
    -- Reward Type and Cost
    reward_type VARCHAR(50) NOT NULL,
    cost_points INTEGER NOT NULL,
    cost_currency VARCHAR(3),
    cost_amount DECIMAL(10,2),
    
    -- Availability
    is_active BOOLEAN DEFAULT true,
    stock_quantity INTEGER,
    max_per_user INTEGER,
    
    -- Validity
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    
    -- Redemption Data
    redemption_instructions TEXT,
    redemption_data JSONB DEFAULT '{}',
    
    -- Statistics
    total_redeemed INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT rewards_type_valid CHECK (
        reward_type IN ('digital_content', 'physical_item', 'discount', 'access', 'custom')
    ),
    CONSTRAINT rewards_cost_positive CHECK (cost_points > 0),
    CONSTRAINT rewards_stock_positive CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
    CONSTRAINT rewards_max_per_user_positive CHECK (max_per_user IS NULL OR max_per_user > 0),
    CONSTRAINT rewards_total_redeemed_positive CHECK (total_redeemed >= 0)
);

CREATE TABLE gamification.reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_id UUID NOT NULL REFERENCES gamification.rewards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
    
    -- Redemption Details
    points_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    
    -- Fulfillment
    fulfillment_data JSONB DEFAULT '{}',
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    fulfilled_by UUID REFERENCES user_management.users(id),
    
    -- Timestamps
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT reward_redemptions_points_positive CHECK (points_spent > 0),
    CONSTRAINT reward_redemptions_status_valid CHECK (
        status IN ('pending', 'processing', 'fulfilled', 'cancelled', 'refunded')
    )
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Point Systems
CREATE INDEX idx_point_systems_organization ON gamification.point_systems(organization_id);
CREATE INDEX idx_point_systems_active ON gamification.point_systems(is_active);

-- User Points
CREATE INDEX idx_user_points_user ON gamification.user_points(user_id);
CREATE INDEX idx_user_points_system ON gamification.user_points(point_system_id);
CREATE INDEX idx_user_points_total ON gamification.user_points(total_points);
CREATE INDEX idx_user_points_streak ON gamification.user_points(current_streak_days);
CREATE INDEX idx_user_points_activity_date ON gamification.user_points(last_activity_date);

-- Point Transactions
CREATE INDEX idx_point_transactions_user ON gamification.point_transactions(user_id);
CREATE INDEX idx_point_transactions_system ON gamification.point_transactions(point_system_id);
CREATE INDEX idx_point_transactions_type ON gamification.point_transactions(transaction_type);
CREATE INDEX idx_point_transactions_source ON gamification.point_transactions(source_type, source_id);
CREATE INDEX idx_point_transactions_processed_at ON gamification.point_transactions(processed_at);

-- Experience Levels
CREATE INDEX idx_experience_levels_organization ON gamification.experience_levels(organization_id);
CREATE INDEX idx_experience_levels_system ON gamification.experience_levels(point_system_id);
CREATE INDEX idx_experience_levels_number ON gamification.experience_levels(level_number);
CREATE INDEX idx_experience_levels_points ON gamification.experience_levels(points_required);

-- User Levels
CREATE INDEX idx_user_levels_user ON gamification.user_levels(user_id);
CREATE INDEX idx_user_levels_system ON gamification.user_levels(point_system_id);
CREATE INDEX idx_user_levels_level ON gamification.user_levels(experience_level_id);

-- Badge Categories
CREATE INDEX idx_badge_categories_organization ON gamification.badge_categories(organization_id);
CREATE INDEX idx_badge_categories_active ON gamification.badge_categories(is_active);
CREATE INDEX idx_badge_categories_sort_order ON gamification.badge_categories(sort_order);

-- Badges
CREATE INDEX idx_badges_organization ON gamification.badges(organization_id);
CREATE INDEX idx_badges_category ON gamification.badges(category_id);
CREATE INDEX idx_badges_rarity ON gamification.badges(rarity);
CREATE INDEX idx_badges_active ON gamification.badges(is_active);
CREATE INDEX idx_badges_hidden ON gamification.badges(is_hidden);
CREATE INDEX idx_badges_availability ON gamification.badges(available_from, available_until);

-- User Badges
CREATE INDEX idx_user_badges_user ON gamification.user_badges(user_id);
CREATE INDEX idx_user_badges_badge ON gamification.user_badges(badge_id);
CREATE INDEX idx_user_badges_featured ON gamification.user_badges(is_featured);
CREATE INDEX idx_user_badges_awarded_at ON gamification.user_badges(awarded_at);

-- Achievements
CREATE INDEX idx_achievements_organization ON gamification.achievements(organization_id);
CREATE INDEX idx_achievements_type ON gamification.achievements(achievement_type);
CREATE INDEX idx_achievements_category ON gamification.achievements(category);
CREATE INDEX idx_achievements_active ON gamification.achievements(is_active);
CREATE INDEX idx_achievements_secret ON gamification.achievements(is_secret);
CREATE INDEX idx_achievements_progressive ON gamification.achievements(is_progressive);

-- User Achievements
CREATE INDEX idx_user_achievements_user ON gamification.user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement ON gamification.user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_completed ON gamification.user_achievements(is_completed);
CREATE INDEX idx_user_achievements_progress ON gamification.user_achievements(current_progress);
CREATE INDEX idx_user_achievements_last_updated ON gamification.user_achievements(last_updated_at);

-- Leaderboards
CREATE INDEX idx_leaderboards_organization ON gamification.leaderboards(organization_id);
CREATE INDEX idx_leaderboards_type ON gamification.leaderboards(leaderboard_type);
CREATE INDEX idx_leaderboards_scope ON gamification.leaderboards(scope);
CREATE INDEX idx_leaderboards_time_period ON gamification.leaderboards(time_period);
CREATE INDEX idx_leaderboards_public ON gamification.leaderboards(is_public);
CREATE INDEX idx_leaderboards_active ON gamification.leaderboards(is_active);

-- Leaderboard Entries
CREATE INDEX idx_leaderboard_entries_leaderboard ON gamification.leaderboard_entries(leaderboard_id);
CREATE INDEX idx_leaderboard_entries_user ON gamification.leaderboard_entries(user_id);
CREATE INDEX idx_leaderboard_entries_rank ON gamification.leaderboard_entries(rank_position);
CREATE INDEX idx_leaderboard_entries_score ON gamification.leaderboard_entries(score);
CREATE INDEX idx_leaderboard_entries_calculated_at ON gamification.leaderboard_entries(calculated_at);

-- Rewards
CREATE INDEX idx_rewards_organization ON gamification.rewards(organization_id);
CREATE INDEX idx_rewards_type ON gamification.rewards(reward_type);
CREATE INDEX idx_rewards_active ON gamification.rewards(is_active);
CREATE INDEX idx_rewards_cost ON gamification.rewards(cost_points);
CREATE INDEX idx_rewards_validity ON gamification.rewards(valid_from, valid_until);

-- Reward Redemptions
CREATE INDEX idx_reward_redemptions_reward ON gamification.reward_redemptions(reward_id);
CREATE INDEX idx_reward_redemptions_user ON gamification.reward_redemptions(user_id);
CREATE INDEX idx_reward_redemptions_status ON gamification.reward_redemptions(status);
CREATE INDEX idx_reward_redemptions_redeemed_at ON gamification.reward_redemptions(redeemed_at);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE TRIGGER update_point_systems_updated_at BEFORE UPDATE ON gamification.point_systems
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_points_updated_at BEFORE UPDATE ON gamification.user_points
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_experience_levels_updated_at BEFORE UPDATE ON gamification.experience_levels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_badge_categories_updated_at BEFORE UPDATE ON gamification.badge_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_badges_updated_at BEFORE UPDATE ON gamification.badges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_achievements_updated_at BEFORE UPDATE ON gamification.achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_achievements_last_updated_at BEFORE UPDATE ON gamification.user_achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leaderboards_updated_at BEFORE UPDATE ON gamification.leaderboards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rewards_updated_at BEFORE UPDATE ON gamification.rewards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON SCHEMA gamification IS 'Gamification schema containing points, badges, levels, achievements, and leaderboards';

COMMENT ON TABLE gamification.point_systems IS 'Point systems configuration for different gamification contexts';
COMMENT ON TABLE gamification.user_points IS 'User point balances and statistics';
COMMENT ON TABLE gamification.point_transactions IS 'All point earning and spending transactions';
COMMENT ON TABLE gamification.experience_levels IS 'Experience levels based on points earned';
COMMENT ON TABLE gamification.user_levels IS 'Current user levels and progress';
COMMENT ON TABLE gamification.badge_categories IS 'Categories for organizing badges';
COMMENT ON TABLE gamification.badges IS 'Available badges that users can earn';
COMMENT ON TABLE gamification.user_badges IS 'Badges earned by users';
COMMENT ON TABLE gamification.achievements IS 'Achievements that users can complete';
COMMENT ON TABLE gamification.user_achievements IS 'User progress on achievements';
COMMENT ON TABLE gamification.leaderboards IS 'Leaderboard configurations';
COMMENT ON TABLE gamification.leaderboard_entries IS 'Current leaderboard rankings';
COMMENT ON TABLE gamification.rewards IS 'Rewards that can be purchased with points';
COMMENT ON TABLE gamification.reward_redemptions IS 'User reward redemption history';

-- Reset search path
SET search_path TO public;

