-- History Server 基础数据库初始化
-- 只创建数据库，表结构由应用程序自动创建或手动执行

-- 创建分片数据库（dev 环境使用 2 个分片）
USE `unimargin_history_server_0`;
USE `unimargin_history_server_1`;

-- 数据库创建完成
SELECT 'History Server databases initialized. Tables will be created by application.' AS status;
