-- ====================================================
-- MySQL 数据库初始化脚本
-- 创建所有必需的数据库和用户权限
-- ====================================================

-- 主业务数据库
CREATE DATABASE IF NOT EXISTS `bifu` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- XXL-Job 调度数据库
CREATE DATABASE IF NOT EXISTS `xxl_job` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Activity Server 数据库
CREATE DATABASE IF NOT EXISTS `activity` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- History Server 分片数据库 (dev 环境使用 2 个分片)
CREATE DATABASE IF NOT EXISTS `unimargin_history_server_0` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `unimargin_history_server_1` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 授权所有数据库访问权限给 root 用户（Docker 环境）
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

SELECT 'Database initialization completed!' AS status;
