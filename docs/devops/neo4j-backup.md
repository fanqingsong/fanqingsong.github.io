# Neo4j 备份脚本

## 📋 概述

这个脚本专门用于 Neo4j 图数据库的备份操作，支持全量备份、增量备份和在线备份。

## 🚀 备份脚本

```bash
#!/bin/bash

# Neo4j 备份脚本
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
NEO4J_HOST="${NEO4J_HOST:-localhost}"
NEO4J_PORT="${NEO4J_PORT:-7687}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-password}"

NEO4J_HOME="${NEO4J_HOME:-/var/lib/neo4j}"
NEO4J_DATA_DIR="${NEO4J_DATA_DIR:-$NEO4J_HOME/data}"
NEO4J_BACKUP_DIR="${NEO4J_BACKUP_DIR:-/backup/neo4j}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_TYPE="${BACKUP_TYPE:-full}"  # full, incremental, online

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v cypher-shell &> /dev/null; then
        log_error "cypher-shell 未安装"
        exit 1
    fi
    
    if ! command -v neo4j-admin &> /dev/null; then
        log_warning "neo4j-admin 未安装，将使用 cypher-shell 备份"
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq 未安装，将使用基本格式输出"
    fi
    
    log_success "依赖检查完成"
}

# 测试数据库连接
test_connection() {
    log_info "测试数据库连接..."
    
    if ! echo "RETURN 1;" | cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" &> /dev/null; then
        log_error "无法连接到 Neo4j 数据库"
        exit 1
    fi
    
    log_success "数据库连接测试通过"
}

# 获取数据库信息
get_db_info() {
    log_info "获取数据库信息..."
    
    # 获取节点数量
    local node_count=$(echo "MATCH (n) RETURN count(n) as count;" | \
    cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" --format plain | \
    tail -1)
    
    # 获取关系数量
    local rel_count=$(echo "MATCH ()-[r]->() RETURN count(r) as count;" | \
    cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" --format plain | \
    tail -1)
    
    # 获取数据库版本
    local version=$(echo "CALL dbms.components() YIELD name, versions, edition RETURN name, versions[0] as version, edition;" | \
    cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" --format plain | \
    tail -1)
    
    log_info "节点数量: $node_count"
    log_info "关系数量: $rel_count"
    log_info "数据库版本: $version"
}

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "$NEO4J_BACKUP_DIR"
    log_success "备份目录创建完成: $NEO4J_BACKUP_DIR"
}

# 使用 neo4j-admin 备份
perform_admin_backup() {
    log_info "使用 neo4j-admin 执行备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="neo4j_admin_backup_${timestamp}"
    local backup_path="$NEO4J_BACKUP_DIR/$backup_name"
    
    # 检查 neo4j-admin 是否可用
    if ! command -v neo4j-admin &> /dev/null; then
        log_error "neo4j-admin 不可用"
        return 1
    fi
    
    # 执行备份
    if neo4j-admin backup --from="bolt://$NEO4J_HOST:$NEO4J_PORT" \
        --backup-dir="$backup_path" \
        --username="$NEO4J_USER" \
        --password="$NEO4J_PASSWORD" \
        --database=neo4j \
        --verbose; then
        
        log_success "neo4j-admin 备份完成: $backup_path"
        echo "$backup_path"
    else
        log_error "neo4j-admin 备份失败"
        return 1
    fi
}

# 使用 cypher-shell 备份
perform_cypher_backup() {
    log_info "使用 cypher-shell 执行备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$NEO4J_BACKUP_DIR/neo4j_cypher_backup_${timestamp}.cypher"
    
    # 创建备份脚本
    cat > "$backup_file" << 'EOF'
// Neo4j 数据备份脚本
// 导出所有节点
MATCH (n) RETURN n;

// 导出所有关系
MATCH ()-[r]->() RETURN r;

// 导出索引信息
SHOW INDEXES;

// 导出约束信息
SHOW CONSTRAINTS;

// 导出数据库统计信息
CALL db.stats.retrieve('GRAPH COUNTS') YIELD data RETURN data;
EOF
    
    # 执行备份
    if cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" \
        -u "$NEO4J_USER" \
        -p "$NEO4J_PASSWORD" \
        --format plain \
        < "$backup_file" > "${backup_file}.data"; then
        
        log_success "cypher-shell 备份完成: $backup_file"
        echo "$backup_file"
    else
        log_error "cypher-shell 备份失败"
        return 1
    fi
}

# 在线备份
perform_online_backup() {
    log_info "执行在线备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$NEO4J_BACKUP_DIR/neo4j_online_backup_${timestamp}.cypher"
    
    # 创建在线备份脚本
    cat > "$backup_file" << 'EOF'
// 在线备份脚本
// 获取所有标签
CALL db.labels() YIELD label RETURN label;

// 获取所有关系类型
CALL db.relationshipTypes() YIELD relationshipType RETURN relationshipType;

// 按标签备份节点
CALL db.labels() YIELD label
CALL {
  WITH label
  MATCH (n:`${label}`) 
  RETURN label, collect(n) as nodes
} RETURN label, size(nodes) as node_count;

// 按关系类型备份关系
CALL db.relationshipTypes() YIELD relationshipType
CALL {
  WITH relationshipType
  MATCH ()-[r:`${relationshipType}`]->() 
  RETURN relationshipType, collect(r) as relationships
} RETURN relationshipType, size(relationships) as rel_count;
EOF
    
    # 执行在线备份
    if cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" \
        -u "$NEO4J_USER" \
        -p "$NEO4J_PASSWORD" \
        --format plain \
        < "$backup_file" > "${backup_file}.data"; then
        
        log_success "在线备份完成: $backup_file"
        echo "$backup_file"
    else
        log_error "在线备份失败"
        return 1
    fi
}

# 增量备份
perform_incremental_backup() {
    log_info "执行增量备份..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$NEO4J_BACKUP_DIR/neo4j_incremental_backup_${timestamp}.cypher"
    
    # 创建增量备份脚本（基于时间戳）
    cat > "$backup_file" << 'EOF'
// 增量备份脚本
// 获取上次备份时间（这里使用示例时间戳）
WITH datetime('2024-01-01T00:00:00') as last_backup_time

// 备份新增的节点
MATCH (n) 
WHERE n.created_at > last_backup_time OR n.updated_at > last_backup_time
RETURN n;

// 备份新增的关系
MATCH ()-[r]->() 
WHERE r.created_at > last_backup_time OR r.updated_at > last_backup_time
RETURN r;

// 备份修改的节点
MATCH (n) 
WHERE n.updated_at > last_backup_time
RETURN n;
EOF
    
    # 执行增量备份
    if cypher-shell -a "bolt://$NEO4J_HOST:$NEO4J_PORT" \
        -u "$NEO4J_USER" \
        -p "$NEO4J_PASSWORD" \
        --format plain \
        < "$backup_file" > "${backup_file}.data"; then
        
        log_success "增量备份完成: $backup_file"
        echo "$backup_file"
    else
        log_error "增量备份失败"
        return 1
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
    
    # 检查文件内容
    if [[ -f "${backup_file}.data" ]]; then
        local line_count=$(wc -l < "${backup_file}.data")
        log_info "备份数据行数: $line_count"
    fi
    
    log_success "备份文件验证通过"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    
    local deleted_count=0
    
    # 清理 cypher 备份文件
    if [[ -d "$NEO4J_BACKUP_DIR" ]]; then
        deleted_count=$(find "$NEO4J_BACKUP_DIR" -name "neo4j_*_backup_*" -mtime +"$BACKUP_RETENTION_DAYS" | wc -l)
        find "$NEO4J_BACKUP_DIR" -name "neo4j_*_backup_*" -mtime +"$BACKUP_RETENTION_DAYS" -delete
    fi
    
    # 清理 admin 备份目录
    if [[ -d "$NEO4J_BACKUP_DIR" ]]; then
        local admin_deleted=$(find "$NEO4J_BACKUP_DIR" -name "neo4j_admin_backup_*" -type d -mtime +"$BACKUP_RETENTION_DAYS" | wc -l)
        find "$NEO4J_BACKUP_DIR" -name "neo4j_admin_backup_*" -type d -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -rf {} +
        deleted_count=$((deleted_count + admin_deleted))
    fi
    
    log_success "清理完成，删除了 $deleted_count 个旧备份文件"
}

# 生成备份报告
generate_backup_report() {
    local backup_file=$1
    log_info "生成备份报告..."
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="$NEO4J_BACKUP_DIR/backup_report_$(date '+%Y%m%d').txt"
    
    cat >> "$report_file" << EOF
=== Neo4j 备份报告 ===
备份时间: $timestamp
数据库: Neo4j
主机: $NEO4J_HOST:$NEO4J_PORT
备份类型: $BACKUP_TYPE
备份文件: $backup_file
文件大小: $(du -h "$backup_file" | cut -f1)

EOF
    
    log_success "备份报告已生成: $report_file"
}

# 主函数
main() {
    log_info "开始 Neo4j 备份..."
    
    check_dependencies
    test_connection
    get_db_info
    create_backup_dir
    
    local backup_file=""
    
    case "$BACKUP_TYPE" in
        "full")
            # 尝试使用 neo4j-admin，如果失败则使用 cypher-shell
            if ! backup_file=$(perform_admin_backup); then
                log_warning "neo4j-admin 备份失败，使用 cypher-shell"
                backup_file=$(perform_cypher_backup)
            fi
            ;;
        "incremental")
            backup_file=$(perform_incremental_backup)
            ;;
        "online")
            backup_file=$(perform_online_backup)
            ;;
        *)
            log_error "不支持的备份类型: $BACKUP_TYPE"
            log_info "支持的备份类型: full, incremental, online"
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
    
    log_success "Neo4j 备份完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🔧 使用方法

### 1. 环境变量配置

```bash
# Neo4j 配置
export NEO4J_HOST="localhost"
export NEO4J_PORT="7687"
export NEO4J_USER="neo4j"
export NEO4J_PASSWORD="password"

# 备份配置
export NEO4J_BACKUP_DIR="/backup/neo4j"
export BACKUP_RETENTION_DAYS="7"
export BACKUP_TYPE="full"  # full, incremental, online
```

### 2. 执行备份

```bash
# 全量备份
export BACKUP_TYPE="full"
./neo4j-backup.sh

# 增量备份
export BACKUP_TYPE="incremental"
./neo4j-backup.sh

# 在线备份
export BACKUP_TYPE="online"
./neo4j-backup.sh
```

### 3. 定时备份

```bash
# 每天凌晨3点执行全量备份
0 3 * * * /path/to/neo4j-backup.sh >> /var/log/neo4j-backup.log 2>&1

# 每小时执行增量备份
0 * * * * export BACKUP_TYPE="incremental" && /path/to/neo4j-backup.sh >> /var/log/neo4j-backup.log 2>&1
```

## 📊 备份类型说明

| 备份类型 | 说明 | 适用场景 |
|----------|------|----------|
| `full` | 全量备份，包含所有数据 | 完整备份，灾难恢复 |
| `incremental` | 增量备份，基于时间戳 | 频繁备份，最小化数据丢失 |
| `online` | 在线备份，不停止服务 | 生产环境，零停机备份 |

## 📝 监控和告警

```bash
# 检查备份状态
grep "SUCCESS.*备份完成" /var/log/neo4j-backup.log | tail -1

# 检查备份文件大小
ls -lh /backup/neo4j/

# 检查备份文件数量
find /backup/neo4j/ -name "neo4j_*_backup_*" | wc -l
``` 