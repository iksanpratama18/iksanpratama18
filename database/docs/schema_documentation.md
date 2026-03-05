# E-Learning Gamification Platform - Database Schema Documentation

## Overview

This document provides comprehensive documentation for the PostgreSQL database schema of the e-learning gamification platform. The schema is designed to support a multi-tenant, scalable learning management system with advanced gamification features.

## Schema Architecture

### Multi-Schema Organization

The database is organized into logical schemas for better maintainability and security:

- **user_management** - User accounts, organizations, roles, and authentication
- **course_management** - Courses, modules, lessons, and learning paths
- **content_management** - Educational content and media management
- **gamification** - Points, badges, levels, achievements, and leaderboards
- **assessment** - Quizzes, assignments, submissions, and grading
- **social** - Forums, discussions, and social interactions (planned)
- **analytics** - Learning analytics and reporting (planned)

### Key Design Principles

1. **Multi-tenancy**: Organization-based data isolation with row-level security
2. **Scalability**: Optimized indexes and query patterns for large datasets
3. **Flexibility**: JSONB columns for extensible metadata and configuration
4. **Auditability**: Comprehensive audit trails and change tracking
5. **Performance**: Strategic indexing and materialized views for analytics

## Core Entities and Relationships

### User Management Schema

#### Organizations
- **Purpose**: Multi-tenant isolation and subscription management
- **Key Features**: Subscription plans, settings, contact information
- **Relationships**: One-to-many with users, courses, and all content

#### Users
- **Purpose**: User accounts with authentication and profile data
- **Key Features**: Email/phone verification, 2FA, login tracking, suspension
- **Security**: Password hashing, session management, failed login protection

#### Roles and Permissions
- **Purpose**: Flexible role-based access control (RBAC)
- **Key Features**: System and custom roles, granular permissions
- **Design**: Many-to-many relationship between users and roles

### Course Management Schema

#### Courses
- **Purpose**: Main learning content containers
- **Key Features**: Pricing, access control, progress tracking, reviews
- **Metadata**: Tags, difficulty levels, prerequisites, learning objectives

#### Modules and Lessons
- **Purpose**: Hierarchical content organization
- **Key Features**: Sequential unlocking, completion tracking, points rewards
- **Content Types**: Video, text, audio, interactive, quiz, assignment, SCORM

#### Learning Paths
- **Purpose**: Curated course sequences for specific learning goals
- **Key Features**: Sequential/non-sequential progression, prerequisites
- **Analytics**: Enrollment and completion tracking

#### Enrollments and Progress
- **Purpose**: Student enrollment and detailed progress tracking
- **Key Features**: Access expiration, completion certificates, last accessed tracking
- **Granularity**: Course-level and lesson-level progress

### Content Management Schema

#### Content Items
- **Purpose**: Reusable educational content and media
- **Key Features**: Versioning, access control, metadata, file management
- **Content Types**: Video, audio, images, documents, presentations, interactive content

### Gamification Schema

#### Point Systems
- **Purpose**: Configurable point economies for different contexts
- **Key Features**: Base points, multipliers, rules engine
- **Flexibility**: Multiple point systems per organization

#### User Points and Transactions
- **Purpose**: Point balance tracking and transaction history
- **Key Features**: Available/spent balance, streak tracking, lifetime statistics
- **Audit Trail**: Complete transaction history with source tracking

#### Experience Levels
- **Purpose**: User progression system based on points
- **Key Features**: Level requirements, rewards, unlocked features
- **Progression**: Automatic level advancement with point thresholds

#### Badges and Achievements
- **Purpose**: Recognition system for accomplishments
- **Key Features**: Rarity levels, criteria engine, evidence tracking
- **Types**: Course completion, streaks, social, skill mastery, time-based

#### Leaderboards
- **Purpose**: Competitive rankings and social motivation
- **Key Features**: Multiple leaderboard types, time periods, filtering
- **Performance**: Cached rankings with configurable refresh rates

#### Rewards System
- **Purpose**: Point redemption marketplace
- **Key Features**: Digital/physical rewards, stock management, fulfillment tracking
- **Economics**: Point-based pricing with optional currency integration

### Assessment Schema

#### Question Banks and Questions
- **Purpose**: Reusable question repository for assessments
- **Key Features**: Multiple question types, difficulty levels, usage analytics
- **Question Types**: Multiple choice, true/false, short answer, essay, fill-in-blank, matching, ordering, numeric, file upload, code

#### Assessments (Quizzes/Exams)
- **Purpose**: Formal evaluation instruments
- **Key Features**: Time limits, attempt limits, randomization, security features
- **Grading**: Multiple grading methods, passing scores, immediate feedback

#### Assessment Attempts and Responses
- **Purpose**: Student attempt tracking and response storage
- **Key Features**: Timing tracking, security monitoring, detailed scoring
- **Analytics**: Performance analysis and question effectiveness

#### Assignments
- **Purpose**: Project-based assessments with file submissions
- **Key Features**: File uploads, peer review, rubric grading, late penalties
- **Collaboration**: Peer review assignments with anonymous options

#### Grading Rubrics
- **Purpose**: Standardized grading criteria for consistent evaluation
- **Key Features**: Reusable rubrics, detailed criteria, point allocation
- **Usage**: Assignments and manual assessment grading

## Data Types and Conventions

### UUID Primary Keys
All tables use UUID primary keys for:
- Global uniqueness across distributed systems
- Security (non-sequential, non-guessable)
- Easier data migration and replication

### JSONB Usage
JSONB columns are used for:
- **Metadata**: Extensible properties without schema changes
- **Settings**: Configuration data with flexible structure
- **Content Data**: Rich content with varying structures
- **Criteria**: Complex rule definitions for gamification

### Timestamp Conventions
- **created_at**: Record creation timestamp (immutable)
- **updated_at**: Last modification timestamp (auto-updated via triggers)
- **deleted_at**: Soft deletion timestamp (NULL = not deleted)

### Naming Conventions
- **Tables**: Plural nouns (users, courses, assessments)
- **Columns**: Snake_case (first_name, created_at, is_active)
- **Indexes**: Prefixed with idx_ (idx_users_email, idx_courses_organization)
- **Foreign Keys**: Referenced table + _id (user_id, course_id)

## Performance Optimizations

### Strategic Indexing

#### User Management
- Email and username lookups
- Organization-based queries
- Role and permission checks
- Session and token validation

#### Course Management
- Course search and filtering
- Enrollment queries
- Progress tracking
- Full-text search on course content

#### Gamification
- Leaderboard calculations
- Point transaction queries
- Badge and achievement lookups
- User ranking operations

#### Assessment
- Question bank searches
- Assessment attempt queries
- Grading workflows
- Analytics aggregations

### Query Optimization Patterns

#### Pagination
```sql
-- Efficient pagination with cursor-based approach
SELECT * FROM courses 
WHERE created_at > $cursor 
ORDER BY created_at 
LIMIT $page_size;
```

#### Aggregation Queries
```sql
-- Materialized views for expensive aggregations
CREATE MATERIALIZED VIEW course_statistics AS
SELECT 
    course_id,
    COUNT(*) as enrollment_count,
    AVG(progress_percentage) as avg_progress,
    COUNT(*) FILTER (WHERE is_completed) as completion_count
FROM enrollments 
GROUP BY course_id;
```

#### Full-Text Search
```sql
-- GIN indexes for full-text search
CREATE INDEX idx_courses_search ON courses 
USING GIN(to_tsvector('english', title || ' ' || description));
```

## Security Features

### Row-Level Security (RLS)
- Organization-based data isolation
- User-specific data access
- Role-based content filtering

### Audit Logging
- Comprehensive audit trail in audit_log table
- User action tracking
- Data change history
- Security event logging

### Authentication Security
- Password hashing (application-level)
- Session token management
- Failed login attempt tracking
- Account lockout protection
- Two-factor authentication support

### Data Validation
- Check constraints for data integrity
- Foreign key constraints for referential integrity
- Custom validation functions
- Input sanitization (application-level)

## Scalability Considerations

### Horizontal Scaling
- Organization-based sharding potential
- Read replica support
- Connection pooling with PgPool-II

### Vertical Scaling
- Optimized PostgreSQL configuration
- Memory and CPU tuning
- Storage optimization

### Caching Strategy
- Redis for session management
- Materialized views for analytics
- Application-level caching for frequently accessed data

### Archive Strategy
- Soft deletion for audit compliance
- Data retention policies
- Archive table patterns for historical data

## Monitoring and Maintenance

### Performance Monitoring
```sql
-- Query performance analysis
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC;

-- Index usage monitoring
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Maintenance Tasks
- Regular VACUUM and ANALYZE
- Index maintenance and rebuilding
- Statistics updates
- Backup verification

### Health Checks
- Connection pool monitoring
- Query performance tracking
- Storage usage monitoring
- Replication lag monitoring

## Migration Strategy

### Version Control
- Flyway for migration management
- Sequential versioning (V001, V002, etc.)
- Rollback procedures for critical changes

### Deployment Process
1. Backup current database
2. Run migration in transaction
3. Verify data integrity
4. Update application configuration
5. Monitor performance post-deployment

### Testing Strategy
- Migration testing on staging environment
- Data validation scripts
- Performance regression testing
- Rollback procedure testing

## Future Enhancements

### Planned Features
1. **Social Schema**: Forums, discussions, messaging
2. **Analytics Schema**: Advanced learning analytics
3. **Notification System**: Real-time notifications
4. **Integration APIs**: External system connectors
5. **Mobile Optimization**: Offline sync capabilities

### Scalability Improvements
1. **Partitioning**: Time-based partitioning for large tables
2. **Sharding**: Organization-based horizontal sharding
3. **Caching**: Advanced caching strategies
4. **Search**: Elasticsearch integration for advanced search

### Security Enhancements
1. **Encryption**: Column-level encryption for sensitive data
2. **Compliance**: GDPR and FERPA compliance features
3. **Monitoring**: Advanced security monitoring
4. **Access Control**: Fine-grained permission system

## Conclusion

This database schema provides a robust foundation for a comprehensive e-learning gamification platform. The design emphasizes scalability, security, and flexibility while maintaining performance and data integrity. Regular monitoring and maintenance will ensure optimal performance as the platform grows.

