# PostgreSQL 备份脚本

## 📋 概述

这个脚本专门用于 PostgreSQL 数据库的备份操作，支持全量备份、增量备份和压缩备份。

## 🚀 备份脚本

```bash
#!/bin/bash

# PostgreSQL 备份脚本
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 环境变量配置
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"

BACKUP_DIR="${BACKUP_DIR:-/backup/postgres}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
COMPRESS_BACKUP="${COMPRESS_BACKUP:-true}"
BACKUP_TYPE="${BACKUP_TYPE:-full}"  # full, schema, data

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v pg_dump &> /dev/null; then
        log_error "pg_dump 未安装"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        log_error "psql 未安装"
        exit 1
    fi
    
    if [[ "$COMPRESS_BACKUP" == "true" ]] && ! command -v gzip &> /dev/null; then
        log_warning "gzip 未安装，将跳过压缩"
        COMPRESS_BACKUP=false
    fi
    
    log_success "依赖检查完成"
}

# 测试数据库连接
test_connection() {
    log_info "测试数据库连接..."
    
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        log_error "无法连接到数据库"
        exit 1
    fi
    
    log_success "数据库连接测试通过"
}

# 获取数据库信息
get_db_info() {
    log_info "获取数据库信息..."
    
    local db_size=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT pg_size_pretty(pg_database_size('$DB_NAME'));
    " | xargs)
    
    local table_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
    " | xargs)
    
    log_info "数据库大小: $db_size"
    log_info "表数量: $table_count"
}

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "$BACKUP_DIR"
    log_success "备份目录创建完成: $BACKUP_DIR"
}

# 全量备份
perform_full_backup() {
    log_info "执行全量备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${DB_NAME}_full_${timestamp}.sql"
    
    local pg_dump_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$DB_NAME"
        --verbose
        --clean
        --if-exists
        --create
        --no-owner
        --no-privileges
        --format=custom
        -f "$backup_file"
    )
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump "${pg_dump_args[@]}"; then
        log_success "全量备份完成: $backup_file"
        
        # 压缩备份文件
        if [[ "$COMPRESS_BACKUP" == "true" ]]; then
            log_info "压缩备份文件..."
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
            log_success "压缩完成: $backup_file"
        fi
        
        echo "$backup_file"
    else
        log_error "全量备份失败"
        exit 1
    fi
}

# Schema 备份
perform_schema_backup() {
    log_info "执行 Schema 备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${DB_NAME}_schema_${timestamp}.sql"
    
    local pg_dump_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$DB_NAME"
        --verbose
        --schema-only
        --no-owner
        --no-privileges
        -f "$backup_file"
    )
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump "${pg_dump_args[@]}"; then
        log_success "Schema 备份完成: $backup_file"
        
        # 压缩备份文件
        if [[ "$COMPRESS_BACKUP" == "true" ]]; then
            log_info "压缩备份文件..."
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
            log_success "压缩完成: $backup_file"
        fi
        
        echo "$backup_file"
    else
        log_error "Schema 备份失败"
        exit 1
    fi
}

# 数据备份
perform_data_backup() {
    log_info "执行数据备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${DB_NAME}_data_${timestamp}.sql"
    
    local pg_dump_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$DB_NAME"
        --verbose
        --data-only
        --no-owner
        --no-privileges
        -f "$backup_file"
    )
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump "${pg_dump_args[@]}"; then
        log_success "数据备份完成: $backup_file"
        
        # 压缩备份文件
        if [[ "$COMPRESS_BACKUP" == "true" ]]; then
            log_info "压缩备份文件..."
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
            log_success "压缩完成: $backup_file"
        fi
        
        echo "$backup_file"
    else
        log_error "数据备份失败"
        exit 1
    fi
}

# 增量备份（基于 WAL）
perform_incremental_backup() {
    log_info "执行增量备份..."
    
    # 检查是否启用了 WAL 归档
    local wal_archive_mode=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SHOW wal_level;
    " | xargs)
    
    if [[ "$wal_archive_mode" != "replica" && "$wal_archive_mode" != "logical" ]]; then
        log_warning "WAL 级别不是 replica 或 logical，无法执行增量备份"
        log_info "建议在 postgresql.conf 中设置: wal_level = replica"
        return 1
    fi
    
    # 执行 pg_basebackup
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$BACKUP_DIR/${DB_NAME}_incremental_${timestamp}"
    
    if PGPASSWORD="$DB_PASSWORD" pg_basebackup \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -D "$backup_dir" \
        --verbose \
        --progress; then
        
        log_success "增量备份完成: $backup_dir"
        echo "$backup_dir"
    else
        log_error "增量备份失败"
        exit 1
    fi
}

# 验证备份文件
verify_backup() {
    local backup_file=$1
    log_info "验证备份文件: $backup_file"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "备份文件不存在"
        return 1
    fi
    
    # 检查文件大小
    local file_size=$(du -h "$backup_file" | cut -f1)
    log_info "备份文件大小: $file_size"
    
    # 如果是压缩文件，检查完整性
    if [[ "$backup_file" == *.gz ]]; then
        if gzip -t "$backup_file"; then
            log_success "压缩文件完整性验证通过"
        else
            log_error "压缩文件损坏"
            return 1
        fi
    fi
    
    log_success "备份文件验证通过"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    
    local deleted_count=0
    
    # 清理 SQL 备份文件
    if [[ -d "$BACKUP_DIR" ]]; then
        deleted_count=$(find "$BACKUP_DIR" -name "*.sql*" -mtime +"$BACKUP_RETENTION_DAYS" | wc -l)
        find "$BACKUP_DIR" -name "*.sql*" -mtime +"$BACKUP_RETENTION_DAYS" -delete
    fi
    
    # 清理增量备份目录
    if [[ -d "$BACKUP_DIR" ]]; then
        local incremental_deleted=$(find "$BACKUP_DIR" -name "*_incremental_*" -type d -mtime +"$BACKUP_RETENTION_DAYS" | wc -l)
        find "$BACKUP_DIR" -name "*_incremental_*" -type d -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -rf {} +
        deleted_count=$((deleted_count + incremental_deleted))
    fi
    
    log_success "清理完成，删除了 $deleted_count 个旧备份文件"
}

# 生成备份报告
generate_backup_report() {
    local backup_file=$1
    log_info "生成备份报告..."
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="$BACKUP_DIR/backup_report_$(date '+%Y%m%d').txt"
    
    cat >> "$report_file" << EOF
=== PostgreSQL 备份报告 ===
备份时间: $timestamp
数据库: $DB_NAME
主机: $DB_HOST:$DB_PORT
备份类型: $BACKUP_TYPE
备份文件: $backup_file
文件大小: $(du -h "$backup_file" | cut -f1)
压缩: $COMPRESS_BACKUP

EOF
    
    log_success "备份报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始 PostgreSQL 备份..."
    
    check_dependencies
    test_connection
    get_db_info
    create_backup_dir
    
    local backup_file=""
    
    case "$BACKUP_TYPE" in
        "full")
            backup_file=$(perform_full_backup)
            ;;
        "schema")
            backup_file=$(perform_schema_backup)
            ;;
        "data")
            backup_file=$(perform_data_backup)
            ;;
        "incremental")
            backup_file=$(perform_incremental_backup)
            ;;
        *)
            log_error "不支持的备份类型: $BACKUP_TYPE"
            log_info "支持的备份类型: full, schema, data, incremental"
            exit 1
            ;;
    esac
    
    # 验证备份
    if [[ -n "$backup_file" ]]; then
        verify_backup "$backup_file"
        generate_backup_report "$backup_file"
    fi
    
    # 清理旧备份
    cleanup_old_backups
    
    log_success "PostgreSQL 备份完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🔧 使用方法

### 1. 环境变量配置

```bash
# 数据库配置
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="my_database"
export DB_USER="postgres"
export DB_PASSWORD="password"

# 备份配置
export BACKUP_DIR="/backup/postgres"
export BACKUP_RETENTION_DAYS="7"
export COMPRESS_BACKUP="true"
export BACKUP_TYPE="full"  # full, schema, data, incremental
```

### 2. 执行备份

```bash
# 全量备份
export BACKUP_TYPE="full"
./postgres-backup.sh

# Schema 备份
export BACKUP_TYPE="schema"
./postgres-backup.sh

# 数据备份
export BACKUP_TYPE="data"
./postgres-backup.sh

# 增量备份
export BACKUP_TYPE="incremental"
./postgres-backup.sh
```

### 3. 定时备份

```bash
# 每天凌晨2点执行全量备份
0 2 * * * /path/to/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1

# 每小时执行增量备份
0 * * * * export BACKUP_TYPE="incremental" && /path/to/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1
```

## 📊 备份类型说明

| 备份类型 | 说明 | 适用场景 |
|----------|------|----------|
| `full` | 全量备份，包含所有数据和结构 | 完整备份，灾难恢复 |
| `schema` | 仅备份数据库结构 | 部署新环境，结构迁移 |
| `data` | 仅备份数据，不包含结构 | 数据迁移，数据恢复 |
| `incremental` | 基于 WAL 的增量备份 | 频繁备份，最小化数据丢失 |

## 📝 监控和告警

```bash
# 检查备份状态
grep "SUCCESS.*备份完成" /var/log/postgres-backup.log | tail -1

# 检查备份文件大小
ls -lh /backup/postgres/

# 检查备份文件数量
find /backup/postgres/ -name "*.sql*" | wc -l
``` 