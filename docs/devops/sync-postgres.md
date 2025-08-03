# PostgreSQL 数据同步脚本

## 📋 概述

这个脚本用于在不同环境之间同步 PostgreSQL 数据库数据。

## 🚀 主同步脚本

```bash
#!/bin/bash

# PostgreSQL 数据同步脚本
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 环境变量配置
SOURCE_HOST="${SOURCE_HOST:-localhost}"
SOURCE_PORT="${SOURCE_PORT:-5432}"
SOURCE_DB="${SOURCE_DB:-source_db}"
SOURCE_USER="${SOURCE_USER:-postgres}"
SOURCE_PASSWORD="${SOURCE_PASSWORD:-}"

TARGET_HOST="${TARGET_HOST:-localhost}"
TARGET_PORT="${TARGET_PORT:-5432}"
TARGET_DB="${TARGET_DB:-target_db}"
TARGET_USER="${TARGET_USER:-postgres}"
TARGET_PASSWORD="${TARGET_PASSWORD:-}"

BACKUP_DIR="${BACKUP_DIR:-/tmp/postgres_backup}"
LOG_FILE="${LOG_FILE:-/var/log/postgres-sync.log}"

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
    
    log_success "依赖检查完成"
}

# 测试数据库连接
test_connections() {
    log_info "测试数据库连接..."
    
    # 测试源数据库连接
    if ! PGPASSWORD="$SOURCE_PASSWORD" psql -h "$SOURCE_HOST" -p "$SOURCE_PORT" -U "$SOURCE_USER" -d "$SOURCE_DB" -c "SELECT 1;" &> /dev/null; then
        log_error "无法连接到源数据库"
        exit 1
    fi
    
    # 测试目标数据库连接
    if ! PGPASSWORD="$TARGET_PASSWORD" psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d "$TARGET_DB" -c "SELECT 1;" &> /dev/null; then
        log_error "无法连接到目标数据库"
        exit 1
    fi
    
    log_success "数据库连接测试通过"
}

# 执行备份
perform_backup() {
    log_info "开始备份源数据库..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${SOURCE_DB}_${timestamp}.sql"
    
    mkdir -p "$BACKUP_DIR"
    
    # 执行备份
    if PGPASSWORD="$SOURCE_PASSWORD" pg_dump \
        -h "$SOURCE_HOST" \
        -p "$SOURCE_PORT" \
        -U "$SOURCE_USER" \
        -d "$SOURCE_DB" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --no-owner \
        --no-privileges \
        > "$backup_file"; then
        
        log_success "备份完成: $backup_file"
        echo "$backup_file"
    else
        log_error "备份失败"
        exit 1
    fi
}

# 执行恢复
perform_restore() {
    local backup_file=$1
    log_info "开始恢复数据到目标数据库..."
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "备份文件不存在: $backup_file"
        exit 1
    fi
    
    PGPASSWORD="$TARGET_PASSWORD" psql \
        -h "$TARGET_HOST" \
        -p "$TARGET_PORT" \
        -U "$TARGET_USER" \
        -d "$TARGET_DB" \
        --verbose \
        < "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "数据恢复完成"
    else
        log_error "数据恢复失败"
        exit 1
    fi
}

# 验证同步结果
verify_sync() {
    log_info "验证同步结果..."
    
    # 比较表数量
    local source_tables=$(PGPASSWORD="$SOURCE_PASSWORD" psql -h "$SOURCE_HOST" -p "$SOURCE_PORT" -U "$SOURCE_USER" -d "$SOURCE_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
    " | xargs)
    
    local target_tables=$(PGPASSWORD="$TARGET_PASSWORD" psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d "$TARGET_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
    " | xargs)
    
    if [[ "$source_tables" == "$target_tables" ]]; then
        log_success "表数量验证通过: $source_tables 个表"
    else
        log_error "表数量不匹配: 源=$source_tables, 目标=$target_tables"
        exit 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
    log_success "旧备份清理完成"
}

# 主函数
main() {
    log_info "开始 PostgreSQL 数据同步..."
    
    check_dependencies
    test_connections
    
    # 执行备份
    local backup_file=$(perform_backup)
    
    # 执行恢复
    perform_restore "$backup_file"
    
    # 验证同步
    verify_sync
    
    # 清理旧备份
    cleanup_old_backups
    
    log_success "PostgreSQL 数据同步完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🔧 使用方法

### 1. 设置环境变量

```bash
# 源数据库配置
export SOURCE_HOST="source-db.example.com"
export SOURCE_PORT="5432"
export SOURCE_DB="source_database"
export SOURCE_USER="source_user"
export SOURCE_PASSWORD="source_password"

# 目标数据库配置
export TARGET_HOST="target-db.example.com"
export TARGET_PORT="5432"
export TARGET_DB="target_database"
export TARGET_USER="target_user"
export TARGET_PASSWORD="target_password"
```

### 2. 执行同步

```bash
chmod +x sync-postgres.sh
./sync-postgres.sh
```

### 3. 定时同步

```bash
# 每天凌晨2点执行
0 2 * * * /path/to/sync-postgres.sh >> /var/log/postgres-sync.log 2>&1
```

## 📊 监控

```bash
# 查看同步日志
tail -f /var/log/postgres-sync.log

# 检查同步状态
grep "SUCCESS.*同步完成" /var/log/postgres-sync.log | tail -1
``` 