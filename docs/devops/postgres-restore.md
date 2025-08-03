# PostgreSQL 恢复脚本

## 📋 概述

这个脚本专门用于 PostgreSQL 数据库的恢复操作，支持从不同类型的备份文件中恢复数据。

## 🚀 恢复脚本

```bash
#!/bin/bash

# PostgreSQL 恢复脚本
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

BACKUP_FILE="${BACKUP_FILE:-}"
BACKUP_DIR="${BACKUP_DIR:-/backup/postgres}"
RESTORE_TYPE="${RESTORE_TYPE:-full}"  # full, schema, data
DROP_EXISTING="${DROP_EXISTING:-false}"
VERIFY_RESTORE="${VERIFY_RESTORE:-true}"

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v pg_restore &> /dev/null; then
        log_error "pg_restore 未安装"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        log_error "psql 未安装"
        exit 1
    fi
    
    if ! command -v gunzip &> /dev/null; then
        log_warning "gunzip 未安装，可能无法处理压缩文件"
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

# 验证备份文件
validate_backup_file() {
    log_info "验证备份文件..."
    
    if [[ -z "$BACKUP_FILE" ]]; then
        log_error "未指定备份文件"
        log_info "请设置 BACKUP_FILE 环境变量"
        exit 1
    fi
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_error "备份文件不存在: $BACKUP_FILE"
        exit 1
    fi
    
    # 检查文件大小
    local file_size=$(du -h "$BACKUP_FILE" | cut -f1)
    log_info "备份文件大小: $file_size"
    
    # 检查文件类型
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        log_info "检测到压缩文件，将自动解压"
        if ! gzip -t "$BACKUP_FILE"; then
            log_error "压缩文件损坏"
            exit 1
        fi
    fi
    
    log_success "备份文件验证通过"
}

# 获取备份文件信息
get_backup_info() {
    local backup_file=$1
    log_info "获取备份文件信息..."
    
    if [[ "$backup_file" == *.gz ]]; then
        # 压缩文件，使用 gunzip -c 查看内容
        local first_line=$(gunzip -c "$backup_file" | head -1)
    else
        local first_line=$(head -1 "$backup_file")
    fi
    
    if [[ "$first_line" == *"-- PostgreSQL database dump"* ]]; then
        log_info "备份文件类型: PostgreSQL SQL 转储"
        echo "sql"
    elif [[ "$first_line" == *"PGDMP"* ]]; then
        log_info "备份文件类型: PostgreSQL 自定义格式"
        echo "custom"
    else
        log_warning "未知的备份文件格式"
        echo "unknown"
    fi
}

# 创建临时数据库（用于测试恢复）
create_temp_database() {
    local temp_db="temp_restore_$(date +%s)"
    log_info "创建临时数据库: $temp_db"
    
    if PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$temp_db"; then
        log_success "临时数据库创建成功: $temp_db"
        echo "$temp_db"
    else
        log_error "临时数据库创建失败"
        exit 1
    fi
}

# 删除临时数据库
drop_temp_database() {
    local temp_db=$1
    if [[ -n "$temp_db" ]]; then
        log_info "删除临时数据库: $temp_db"
        PGPASSWORD="$DB_PASSWORD" dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$temp_db" || true
    fi
}

# 全量恢复
perform_full_restore() {
    local backup_file=$1
    local target_db=$2
    log_info "执行全量恢复..."
    
    local restore_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$target_db"
        --verbose
        --clean
        --if-exists
        --no-owner
        --no-privileges
    )
    
    if [[ "$backup_file" == *.gz ]]; then
        log_info "解压并恢复压缩文件..."
        gunzip -c "$backup_file" | PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}"
    else
        PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}" "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "全量恢复完成"
    else
        log_error "全量恢复失败"
        exit 1
    fi
}

# Schema 恢复
perform_schema_restore() {
    local backup_file=$1
    local target_db=$2
    log_info "执行 Schema 恢复..."
    
    local restore_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$target_db"
        --verbose
        --schema-only
        --clean
        --if-exists
        --no-owner
        --no-privileges
    )
    
    if [[ "$backup_file" == *.gz ]]; then
        log_info "解压并恢复 Schema..."
        gunzip -c "$backup_file" | PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}"
    else
        PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}" "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Schema 恢复完成"
    else
        log_error "Schema 恢复失败"
        exit 1
    fi
}

# 数据恢复
perform_data_restore() {
    local backup_file=$1
    local target_db=$2
    log_info "执行数据恢复..."
    
    local restore_args=(
        -h "$DB_HOST"
        -p "$DB_PORT"
        -U "$DB_USER"
        -d "$target_db"
        --verbose
        --data-only
        --no-owner
        --no-privileges
    )
    
    if [[ "$backup_file" == *.gz ]]; then
        log_info "解压并恢复数据..."
        gunzip -c "$backup_file" | PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}"
    else
        PGPASSWORD="$DB_PASSWORD" pg_restore "${restore_args[@]}" "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "数据恢复完成"
    else
        log_error "数据恢复失败"
        exit 1
    fi
}

# SQL 格式恢复
perform_sql_restore() {
    local backup_file=$1
    local target_db=$2
    log_info "执行 SQL 格式恢复..."
    
    if [[ "$backup_file" == *.gz ]]; then
        log_info "解压并执行 SQL 恢复..."
        gunzip -c "$backup_file" | PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" --verbose
    else
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" --verbose < "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "SQL 恢复完成"
    else
        log_error "SQL 恢复失败"
        exit 1
    fi
}

# 验证恢复结果
verify_restore() {
    local target_db=$1
    log_info "验证恢复结果..."
    
    # 检查表数量
    local table_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" -t -c "
        SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
    " | xargs)
    
    if [[ "$table_count" -gt 0 ]]; then
        log_success "恢复验证通过: $table_count 个表"
    else
        log_warning "恢复后没有找到表"
    fi
    
    # 检查数据库大小
    local db_size=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$target_db" -t -c "
        SELECT pg_size_pretty(pg_database_size('$target_db'));
    " | xargs)
    
    log_info "恢复后数据库大小: $db_size"
}

# 备份现有数据库
backup_existing_database() {
    local db_name=$1
    log_info "备份现有数据库: $db_name"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${db_name}_before_restore_${timestamp}.sql"
    
    if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" --verbose > "$backup_file"; then
        log_success "现有数据库备份完成: $backup_file"
    else
        log_warning "现有数据库备份失败"
    fi
}

# 主函数
main() {
    log_info "开始 PostgreSQL 恢复..."
    
    check_dependencies
    test_connection
    validate_backup_file
    
    local backup_type=$(get_backup_info "$BACKUP_FILE")
    local temp_db=""
    
    # 如果启用测试模式，创建临时数据库
    if [[ "${TEST_RESTORE:-false}" == "true" ]]; then
        temp_db=$(create_temp_database)
        local target_db="$temp_db"
    else
        local target_db="$DB_NAME"
        
        # 如果启用删除现有数据库，先备份
        if [[ "$DROP_EXISTING" == "true" ]]; then
            backup_existing_database "$target_db"
            
            log_info "删除现有数据库: $target_db"
            PGPASSWORD="$DB_PASSWORD" dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db" || true
            
            log_info "创建新数据库: $target_db"
            PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db"
        fi
    fi
    
    # 根据备份类型和恢复类型执行恢复
    case "$backup_type" in
        "sql")
            perform_sql_restore "$BACKUP_FILE" "$target_db"
            ;;
        "custom")
            case "$RESTORE_TYPE" in
                "full")
                    perform_full_restore "$BACKUP_FILE" "$target_db"
                    ;;
                "schema")
                    perform_schema_restore "$BACKUP_FILE" "$target_db"
                    ;;
                "data")
                    perform_data_restore "$BACKUP_FILE" "$target_db"
                    ;;
                *)
                    log_error "不支持的恢复类型: $RESTORE_TYPE"
                    exit 1
                    ;;
            esac
            ;;
        *)
            log_warning "未知备份类型，尝试 SQL 恢复"
            perform_sql_restore "$BACKUP_FILE" "$target_db"
            ;;
    esac
    
    # 验证恢复结果
    if [[ "$VERIFY_RESTORE" == "true" ]]; then
        verify_restore "$target_db"
    fi
    
    # 清理临时数据库
    if [[ -n "$temp_db" ]]; then
        log_info "测试恢复完成，清理临时数据库"
        drop_temp_database "$temp_db"
    fi
    
    log_success "PostgreSQL 恢复完成！"
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

# 恢复配置
export BACKUP_FILE="/backup/postgres/my_database_full_20240101_120000.sql.gz"
export RESTORE_TYPE="full"  # full, schema, data
export DROP_EXISTING="false"
export VERIFY_RESTORE="true"
export TEST_RESTORE="false"  # 测试模式，使用临时数据库
```

### 2. 执行恢复

```bash
# 全量恢复
export RESTORE_TYPE="full"
./postgres-restore.sh

# Schema 恢复
export RESTORE_TYPE="schema"
./postgres-restore.sh

# 数据恢复
export RESTORE_TYPE="data"
./postgres-restore.sh

# 测试恢复（使用临时数据库）
export TEST_RESTORE="true"
./postgres-restore.sh
```

### 3. 安全恢复

```bash
# 先备份现有数据库，然后恢复
export DROP_EXISTING="true"
export BACKUP_FILE="/backup/postgres/production_backup.sql.gz"
./postgres-restore.sh
```

## 📊 恢复类型说明

| 恢复类型 | 说明 | 适用场景 |
|----------|------|----------|
| `full` | 全量恢复，包含所有数据和结构 | 完整恢复，灾难恢复 |
| `schema` | 仅恢复数据库结构 | 结构迁移，部署新环境 |
| `data` | 仅恢复数据，不包含结构 | 数据迁移，数据恢复 |

## 🔍 故障排除

### 常见问题

1. **权限不足**
   ```bash
   # 确保用户有足够权限
   GRANT ALL PRIVILEGES ON DATABASE my_database TO my_user;
   ```

2. **数据库已存在**
   ```bash
   # 删除现有数据库
   export DROP_EXISTING="true"
   ```

3. **备份文件损坏**
   ```bash
   # 验证备份文件
   gzip -t backup_file.sql.gz
   ```

### 恢复验证

```bash
# 检查恢复后的表数量
psql -d my_database -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

# 检查数据库大小
psql -d my_database -c "SELECT pg_size_pretty(pg_database_size('my_database'));"

# 检查特定表的数据
psql -d my_database -c "SELECT COUNT(*) FROM users;"
``` 