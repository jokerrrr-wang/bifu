# MySQL 初始化脚本说明

本目录包含 MySQL 数据库的初始化脚本，在 MySQL 容器首次启动时自动执行。

## 脚本执行顺序

MySQL 容器会按照文件名的字母顺序执行 `/docker-entrypoint-initdb.d` 目录中的脚本：

1. **01-init-databases.sql** - 创建所有必需的数据库
   - `bifu` - 主业务数据库
   - `xxl_job` - XXL-Job 调度系统数据库
   - `activity` - 活动服务数据库
   - `unimargin_history_server_0` - History Server 分片 0
   - `unimargin_history_server_1` - History Server 分片 1

2. **02-xxl-job-tables.sql** - 创建 XXL-Job 的表结构
   - 来源: `unimargin-history-server/.local_test/mysql/sql/tables_xxl_job.sql`
   - 包含所有 XXL-Job 调度需要的表

3. **03-activity-tables.sql** - 创建 Activity Server 的表结构
   - 来源: `unimargin-activity-server/docs/init.sql`
   - 包含活动、邀请、助力等表

4. **04-history-server-tables.sql** - 创建 History Server 的表结构
   - 来源: `unimargin-history-server/src/main/resources/db/migration/unimargin-history-server-dev.sql`
   - 包含账户、订单、持仓、资金等历史数据表（2个分片）

## 使用说明

### 首次启动
```bash
# 删除旧的 MySQL 数据（如果需要重新初始化）
docker compose down -v
docker volume rm bifu-projects_mysql-data

# 启动服务，MySQL 会自动执行初始化脚本
docker compose up -d mysql
```

### 验证初始化
```bash
# 查看 MySQL 日志确认初始化成功
docker compose logs mysql | grep -i "database initialization"

# 连接 MySQL 查看数据库列表
docker compose exec mysql mysql -uroot -proot -e "SHOW DATABASES;"
```

## 注意事项

1. **仅在首次启动时执行**：初始化脚本只在 MySQL 数据目录为空时执行
2. **数据持久化**：MySQL 数据存储在 Docker volume `mysql-data` 中
3. **重新初始化**：如需重新初始化，必须删除 volume（见上方命令）
4. **密码配置**：
   - MySQL root 密码: `root`
   - 所有服务配置需使用此密码连接数据库

## 脚本来源

- XXL-Job 表结构: 官方 v2.4.0 版本
- Activity 表结构: `unimargin-activity-server` 项目
- History Server 表结构: `unimargin-history-server` 项目（dev 环境配置）

## 添加新的初始化脚本

如需添加新的数据库或表结构：

1. 在本目录创建新的 `.sql` 文件
2. 使用数字前缀控制执行顺序（如 `05-xxx.sql`）
3. 脚本中使用 `CREATE DATABASE IF NOT EXISTS` 避免重复创建
4. 脚本中使用 `USE database_name` 切换到目标数据库
5. 重新启动 MySQL 容器（需删除 volume）

## 环境区分

- **localtest/dev**: 使用本配置（2个分片）
- **prod**: 需要更多分片时，替换为 `unimargin-history-server-prod.sql`（15个分片）
