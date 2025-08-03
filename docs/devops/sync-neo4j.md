# Neo4j 数据同步脚本

## 📋 概述

这个脚本用于在不同环境之间同步 Neo4j 图数据库数据。

## 🚀 主同步脚本

```bash
#!/bin/bash

# Neo4j 数据同步脚本
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
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
SOURCE_PORT="${SOURCE_PORT:-7687}"
SOURCE_USER="${SOURCE_USER:-neo4j}"
SOURCE_PASSWORD="${SOURCE_PASSWORD:-password}"

TARGET_HOST="${TARGET_HOST:-localhost}"
TARGET_PORT="${TARGET_PORT:-7687}"
TARGET_USER="${TARGET_USER:-neo4j}"
TARGET_PASSWORD="${TARGET_PASSWORD:-password}"

BACKUP_DIR="${BACKUP_DIR:-/tmp/neo4j_backup}"

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v cypher-shell &> /dev/null; then
        log_error "cypher-shell 未安装"
        exit 1
    fi
    
    log_success "依赖检查完成"
}

# 测试数据库连接
test_connections() {
    log_info "测试数据库连接..."
    
    # 测试源数据库连接
    if ! echo "RETURN 1;" | cypher-shell -a "bolt://$SOURCE_HOST:$SOURCE_PORT" -u "$SOURCE_USER" -p "$SOURCE_PASSWORD" &> /dev/null; then
        log_error "无法连接到源数据库"
        exit 1
    fi
    
    # 测试目标数据库连接
    if ! echo "RETURN 1;" | cypher-shell -a "bolt://$TARGET_HOST:$TARGET_PORT" -u "$TARGET_USER" -p "$TARGET_PASSWORD" &> /dev/null; then
        log_error "无法连接到目标数据库"
        exit 1
    fi
    
    log_success "数据库连接测试通过"
}

# 执行备份
perform_backup() {
    log_info "开始备份源数据库..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/neo4j_backup_${timestamp}.cypher"
    
    mkdir -p "$BACKUP_DIR"
    
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
EOF
    
    log_success "备份脚本创建完成: $backup_file"
    echo "$backup_file"
}

# 执行恢复
perform_restore() {
    local backup_file=$1
    log_info "开始恢复数据到目标数据库..."
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "备份文件不存在: $backup_file"
        exit 1
    fi
    
    # 清空目标数据库
    echo "MATCH (n) DETACH DELETE n;" | \
    cypher-shell -a "bolt://$TARGET_HOST:$TARGET_PORT" -u "$TARGET_USER" -p "$TARGET_PASSWORD"
    
    # 执行恢复脚本
    cypher-shell -a "bolt://$TARGET_HOST:$TARGET_PORT" -u "$TARGET_USER" -p "$TARGET_PASSWORD" < "$backup_file"
    
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
    
    # 比较节点数量
    local source_nodes=$(echo "MATCH (n) RETURN count(n) as count;" | \
    cypher-shell -a "bolt://$SOURCE_HOST:$SOURCE_PORT" -u "$SOURCE_USER" -p "$SOURCE_PASSWORD" --format plain | \
    tail -1)
    
    local target_nodes=$(echo "MATCH (n) RETURN count(n) as count;" | \
    cypher-shell -a "bolt://$TARGET_HOST:$TARGET_PORT" -u "$TARGET_USER" -p "$TARGET_PASSWORD" --format plain | \
    tail -1)
    
    if [[ "$source_nodes" == "$target_nodes" ]]; then
        log_success "节点数量验证通过: $source_nodes 个节点"
    else
        log_error "节点数量不匹配: 源=$source_nodes, 目标=$target_nodes"
        exit 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    find "$BACKUP_DIR" -name "neo4j_backup_*" -mtime +7 -delete
    log_success "旧备份清理完成"
}

# 主函数
main() {
    log_info "开始 Neo4j 数据同步..."
    
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
    
    log_success "Neo4j 数据同步完成！"
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
export SOURCE_HOST="source-neo4j.example.com"
export SOURCE_PORT="7687"
export SOURCE_USER="neo4j"
export SOURCE_PASSWORD="source_password"

# 目标数据库配置
export TARGET_HOST="target-neo4j.example.com"
export TARGET_PORT="7687"
export TARGET_USER="neo4j"
export TARGET_PASSWORD="target_password"
```

### 2. 执行同步

```bash
chmod +x sync-neo4j.sh
./sync-neo4j.sh
```

### 3. 定时同步

```bash
# 每天凌晨3点执行
0 3 * * * /path/to/sync-neo4j.sh >> /var/log/neo4j-sync.log 2>&1
```

## 📊 监控

```bash
# 查看同步日志
tail -f /var/log/neo4j-sync.log

# 检查同步状态
grep "SUCCESS.*同步完成" /var/log/neo4j-sync.log | tail -1

# 检查数据库连接
cypher-shell -a "bolt://localhost:7687" -u "neo4j" -p "password" -c "RETURN 1;"
``` 