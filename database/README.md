# E-Learning Gamification Platform Database

This directory contains the complete PostgreSQL database schema for the e-learning gamification platform, including all tables, relationships, indexes, views, functions, triggers, and supporting infrastructure.

## 📁 Directory Structure

```
database/
├── migrations/          # Flyway migration files (versioned SQL scripts)
├── schemas/            # Schema definition files organized by domain
├── functions/          # PostgreSQL functions and stored procedures
├── views/             # Database views for common queries
├── triggers/          # Database triggers for automation
├── indexes/           # Index definitions for performance optimization
├── seed-data/         # Initial configuration and sample data
├── monitoring/        # Performance monitoring queries and scripts
├── backup/           # Backup and recovery procedures
└── docs/             # Documentation and guides
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- PostgreSQL 15+
- Flyway (for migrations)

### Setup Development Environment

1. **Start the database services:**
   ```bash
   docker-compose up -d postgres redis
   ```

2. **Run database migrations:**
   ```bash
   docker-compose --profile migration run --rm flyway migrate
   ```

3. **Load seed data:**
   ```bash
   docker-compose --profile migration run --rm flyway -locations=filesystem:/flyway/seed-data migrate
   ```

4. **Start monitoring (optional):**
   ```bash
   docker-compose --profile monitoring up -d grafana prometheus
   ```

### Connection Details

- **Direct PostgreSQL:** `localhost:5432`
- **PgPool (Connection Pooling):** `localhost:5433`
- **Redis:** `localhost:6379`
- **Grafana Dashboard:** `http://localhost:3000`
- **Prometheus Metrics:** `http://localhost:9090`

## 🏗️ Database Architecture

### Core Schemas

1. **user_management** - User accounts, organizations, roles, and permissions
2. **course_management** - Courses, modules, learning paths, and curriculum
3. **content_management** - Educational content, media, and versioning
4. **gamification** - Points, badges, levels, achievements, and leaderboards
5. **assessment** - Quizzes, assignments, submissions, and grading
6. **social** - Forums, discussions, messaging, and peer interactions
7. **analytics** - Learning analytics, reporting, and insights

### Key Features

- **🔐 Multi-tenant Architecture:** Support for multiple organizations
- **🎮 Comprehensive Gamification:** Points, badges, levels, achievements
- **📊 Advanced Analytics:** Learning progress, engagement metrics
- **🔍 Full-text Search:** PostgreSQL's built-in search capabilities
- **⚡ Performance Optimized:** Strategic indexing and query optimization
- **🔄 Real-time Updates:** Triggers for live gamification updates
- **📱 Flexible Content:** JSONB support for dynamic content types

## 📋 Migration Management

### Running Migrations

```bash
# Run all pending migrations
docker-compose --profile migration run --rm flyway migrate

# Get migration info
docker-compose --profile migration run --rm flyway info

# Validate migrations
docker-compose --profile migration run --rm flyway validate

# Baseline existing database
docker-compose --profile migration run --rm flyway baseline
```

### Migration Naming Convention

```
V{version}__{description}.sql

Examples:
V001__create_user_management_schema.sql
V002__create_course_content_schema.sql
V003__create_gamification_schema.sql
```

## 🔧 Performance Tuning

### Recommended PostgreSQL Settings

```sql
-- Connection and Memory
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

-- Query Planning
random_page_cost = 1.1
effective_io_concurrency = 200

-- Logging and Monitoring
log_statement = 'mod'
log_min_duration_statement = 1000
pg_stat_statements.track = all
```

### Key Indexes

- User lookup and authentication
- Course search and filtering
- Progress tracking queries
- Leaderboard calculations
- Full-text search on content
- Analytics aggregations

## 📊 Monitoring and Maintenance

### Performance Monitoring

```sql
-- Check slow queries
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Monitor index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Backup Strategy

- **Daily automated backups** using pg_dump
- **Point-in-time recovery** with WAL archiving
- **Cross-region backup replication** for disaster recovery
- **Regular backup testing** and restoration procedures

## 🔒 Security Considerations

- **Row-level security** for multi-tenant data isolation
- **Encrypted connections** (SSL/TLS)
- **Principle of least privilege** for database users
- **Audit logging** for sensitive operations
- **Input validation** through constraints and triggers

## 📚 Documentation

- [Schema Documentation](docs/schema_documentation.md) - Detailed table and relationship documentation
- [Deployment Guide](docs/deployment_guide.md) - Production deployment procedures
- [Performance Tuning](docs/performance_tuning.md) - Optimization guidelines
- [API Documentation](docs/api_documentation.md) - Database function and view reference

## 🤝 Contributing

1. Create feature branch for schema changes
2. Add migration files with proper versioning
3. Update documentation for new features
4. Test migrations on sample data
5. Submit pull request with detailed description

## 📞 Support

For questions about the database schema or deployment issues, please refer to the documentation or create an issue in the project repository.

