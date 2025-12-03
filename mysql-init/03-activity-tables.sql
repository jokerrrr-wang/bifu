CREATE SCHEMA IF NOT EXISTS activity
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

use activity;

-- auto-generated definition
create table activity
(
    id          bigint auto_increment
        primary key,
    create_time datetime    default CURRENT_TIMESTAMP not null comment '创建时间',
    update_time datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    name        varchar(50)                           not null comment '活动名称',
    start_time  datetime                              not null comment '活动开始时间',
    end_time    datetime                              not null comment '活动结束时间',
    type        varchar(16)                           not null comment '活动类型',
    config      json                                  not null comment '任务配置',
    tasks       json                                  not null comment '任务配置',
    rewards     json                                  not null comment '奖励',
    status      varchar(16) default 'NOT_ONLINE'      not null comment '状态, NOT_ONLINE-未上线, ONLINE-已上线, OFFLINE-已下线',
    enabled      tinyint(1)  default 1                 not null comment '是否启用,0-禁用,1-启用',
    INDEX idx_status_time (status, create_time) COMMENT '状态时间复合索引',
    INDEX idx_type_time (type, create_time) COMMENT '类型时间复合索引'
)
    comment '活动';

-- Referral activity tables from feature branch
DROP TABLE IF EXISTS referral_records;
CREATE TABLE referral_records
(
    id                        BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id                   BIGINT      NOT NULL COMMENT '参与用户ID',
    activity_id               BIGINT      NOT NULL COMMENT '活动ID', -- activity表的id字段
    referral_code             VARCHAR(32) NOT NULL COMMENT '邀请码(8位字母数字组合)',
    email                     VARCHAR(200) NOT NULL COMMENT '用户邮箱',

    -- 状态管理
    status                    TINYINT              DEFAULT 1 COMMENT '状态：1-进行中，2-未完成，3-已完成',
    referral_time             DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '活动参与时间',
    completion_time           DATETIME    NULL COMMENT '完成时间',

    -- 用户参与次数
    referral_count            INT         NOT NULL DEFAULT 1 COMMENT '用户参与活动的累计次数(跨所有活动的参与次数,从1开始)',

    -- 助力进度统计
    required_assistance_count INT                  DEFAULT 2 COMMENT '所需助力人数',
    current_assistance_count  INT                  DEFAULT 0 COMMENT '当前助力人数',
    valid_assistance_count    INT                  DEFAULT 0 COMMENT '有效助力人数(完成所有条件)',

    create_time               DATETIME             DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time               DATETIME             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    UNIQUE KEY uk_user_activity (user_id, activity_id) COMMENT '同一用户只有一个邀请码',
    UNIQUE KEY uk_user_referral_count (user_id, referral_count) COMMENT '同一用户参与次数唯一',
    INDEX idx_referral_code (referral_code) COMMENT '邀请码索引',
    INDEX idx_create_time (create_time) COMMENT '创建时间索引-支持时间范围查询',
    INDEX idx_user_referral_count (user_id, referral_count) COMMENT '用户参与次数索引-支持查询用户参与历史',
    INDEX idx_activity_time (activity_id, referral_time) COMMENT '活动时间索引-支持按活动查询参与记录'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
    COMMENT ='参与记录表-记录用户参与活动的历史，referral_count表示用户累计参与次数';


DROP TABLE IF EXISTS assistance_progress;
CREATE TABLE assistance_progress
(
    id                    BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',

    referral_code         VARCHAR(32) NOT NULL COMMENT '邀请码',
    assistant_user_id     BIGINT      NOT NULL COMMENT '助力用户ID(被邀请用户)',
    inviter_user_id       BIGINT      NOT NULL COMMENT '邀请人用户ID',
    activity_id           BIGINT      NOT NULL COMMENT '活动ID',
    assistance_status     TINYINT        DEFAULT 1 COMMENT '助力状态：1-已注册，2-已入金，3-已交易',
    register_time         DATETIME    NULL COMMENT '注册完成时间',
    deposit_time          DATETIME    NULL COMMENT '首次入金时间',
    trade_time            DATETIME    NULL COMMENT '首次交易时间',
    completion_time       DATETIME    NULL COMMENT '所有任务完成时间',
    assistant_finish_time DATE        NULL COMMENT '邀请用户完成时间',
    deposit_amount        DECIMAL(20, 8) DEFAULT 0 COMMENT '入金金额',
    deposit_currency      VARCHAR(10)    DEFAULT 'USDT' COMMENT '充值币种',
    trade_volume          DECIMAL(20, 8) DEFAULT 0 COMMENT '合约交易金额',
    trade_currency        VARCHAR(10)    DEFAULT 'USDT' COMMENT '合约交易币种',
    message_id            VARCHAR(64) NULL COMMENT '消息ID',
    create_time           DATETIME       DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time           DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    UNIQUE KEY uk_invite_assistant (referral_code, assistant_user_id) COMMENT '邀请码-助力用户唯一约束',
    INDEX idx_assistant_user_id (assistant_user_id) COMMENT '助力用户索引',
    INDEX idx_inviter_user_id (inviter_user_id) COMMENT '邀请人索引',
    INDEX idx_activity_id (activity_id) COMMENT '活动ID索引',
    INDEX idx_referral_code (referral_code) COMMENT '邀请码索引',
    INDEX idx_status_time (assistance_status, create_time) COMMENT '状态时间复合索引',
    INDEX idx_completion_time (completion_time) COMMENT '完成时间索引'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='助力进度表';

-- Activity reward and task tables from main branch
-- auto-generated definition
create table activity_reward_distribution_record
(
    id                bigint auto_increment
        primary key,
    create_time       datetime    default CURRENT_TIMESTAMP not null comment '创建时间',
    update_time       datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    activity_id       bigint                                not null comment '活动id',
    activity_name     varchar(50)                           not null comment '活动名称',
    activity_type     varchar(16)                           not null comment '活动类型',
    transaction_type  varchar(16)                           not null comment '流水类型',
    distribution_type varchar(16)                           not null comment '发放类型',
    currency          varchar(16)                           not null comment '币种',
    amount            decimal(12, 4)                        not null comment '金额',
    uid               bigint                                not null comment 'uid',
    email             varchar(256)                          not null comment 'email',
    status            varchar(16) default 'PROCESSING'      not null comment '状态',
    INDEX idx_create_time_status (create_time DESC, status) COMMENT '创建时间状态复合索引',
    INDEX idx_uid_create_time (uid, create_time DESC) COMMENT '用户创建时间复合索引',
    INDEX idx_activity_id_create_time (activity_id, create_time DESC) COMMENT '活动创建时间复合索引',
    INDEX idx_currency_create_time (currency, create_time DESC) COMMENT '币种创建时间复合索引',
    INDEX idx_activity_type_create_time (activity_type, create_time DESC) COMMENT '活动类型创建时间复合索引',
    INDEX idx_uid_time_range (uid, create_time DESC, status) COMMENT '用户时间范围复合索引',
    INDEX idx_activity_time_range (activity_id, create_time DESC, status) COMMENT '活动时间范围复合索引'
)
    comment '活动奖励发放记录';

-- auto-generated definition
DROP TABLE IF EXISTS activity_task_progress;
create table activity_task_progress
(
    id             bigint auto_increment
        primary key,
    create_time    datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    update_time    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    activity_id    bigint                             not null comment '活动id',
    uid            bigint                             not null comment 'uid',
    task_type       varchar(32)                        not null comment '任务类型',
    value          decimal(12, 4)                     not null comment '任务进度',
    status         varchar(16)                        not null comment '任务状态',
    completed_date date                               null comment '完成时间',
    deadline       datetime                           not null comment '截止日期',
    INDEX idx_activity_uid (activity_id, uid) COMMENT '活动用户复合索引',
    INDEX idx_uid_status (uid, status) COMMENT '用户状态复合索引',
    INDEX idx_task_type_status (task_type, status) COMMENT '任务类型状态复合索引',
    INDEX idx_deadline (deadline) COMMENT '截止日期索引'
)
    comment '活动任务进度';

-- auto-generated definition
create table user_activity_record
(
    id          bigint auto_increment
        primary key,
    create_time datetime default CURRENT_TIMESTAMP not null comment '创建时间',
    update_time datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '修改时间',
    uid         bigint                             not null comment 'uid',
    task_type    varchar(32)                        not null comment '任务类型',
    value       decimal(12, 4)                     not null comment '活动量',
    unit_value  varchar(32)                        not null comment '单位值',
    biz_id      varchar(255)                       not null comment '业务id',
    index_id    varchar(512)                       not null comment '引用id',
    INDEX idx_uid_task_type (uid, task_type) COMMENT '用户任务类型复合索引',
    INDEX idx_create_time (create_time) COMMENT '创建时间索引',
    INDEX idx_biz_id (biz_id) COMMENT '业务ID索引'
)
    comment '用户活动记录';

-- 创建活动统计表
CREATE TABLE `activity_statistics` (
                                       `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
                                       `activity_id` bigint(20) NOT NULL COMMENT '活动ID',
                                       `activity_name` varchar(255) NOT NULL COMMENT '活动名称',
                                       `start_time` datetime NOT NULL COMMENT '活动开始时间(UTC+8)',
                                       `end_time` datetime NOT NULL COMMENT '活动结束时间(UTC+8)',
                                       `participant_count` int(11) NOT NULL DEFAULT '0' COMMENT '参与活动人数',
                                       `registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '完成注册人数',
                                       `deposit_count` int(11) NOT NULL DEFAULT '0' COMMENT '完成入金人数',
                                       `trade_count` int(11) NOT NULL DEFAULT '0' COMMENT '完成交易人数',
                                       `one_friend_assist_count` int(11) NOT NULL DEFAULT '0' COMMENT '好友1人助力完成人数',
                                       `two_friend_assist_count` int(11) NOT NULL DEFAULT '0' COMMENT '好友2人助力完成人数',
                                       `total_count` int(11) NOT NULL DEFAULT '0' COMMENT '总计人数',
                                       `statistics_date` date NOT NULL COMMENT '统计日期(YYYY-MM-DD)',
                                       `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                       `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                                       PRIMARY KEY (`id`),
                                       UNIQUE KEY `uk_activity_date` (`activity_id`, `statistics_date`),
                                       KEY `idx_activity_id` (`activity_id`),
                                       KEY `idx_statistics_date` (`statistics_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='活动统计表';

-- 创建活动统计明细表（用于导出功能）
CREATE TABLE `activity_statistics_detail` (
                                              `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
                                              `activity_id` bigint(20) NOT NULL COMMENT '活动ID',
                                              `statistics_date` date NOT NULL COMMENT '统计日期',
                                              `time_range` varchar(50) DEFAULT NULL COMMENT '时间范围（用于导出）',
                                              `inviter_uid` bigint(20) NOT NULL COMMENT '邀请人UID',
                                              `inviter_email` varchar(255) DEFAULT NULL COMMENT '邀请人邮箱',
                                              `inviter_start_time` datetime DEFAULT NULL COMMENT '邀请人开始时间',
                                              `completion_progress` varchar(50) DEFAULT NULL COMMENT '完成进度',
                                              `friend_uid` bigint(20) DEFAULT NULL COMMENT '好友UID',
                                              `friend_register_time` datetime DEFAULT NULL COMMENT '好友注册时间',
                                              `friend_deposit_amount` decimal(20,8) DEFAULT NULL COMMENT '好友入金金额',
                                              `friend_deposit_time` datetime DEFAULT NULL COMMENT '好友入金时间',
                                              `friend_trade_amount` decimal(20,8) DEFAULT NULL COMMENT '好友交易金额',
                                              `friend_trade_type` varchar(50) DEFAULT NULL COMMENT '好友交易类型',
                                              `friend_trade_time` datetime DEFAULT NULL COMMENT '好友交易时间',
                                              `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                              `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
                                              PRIMARY KEY (`id`),
                                              KEY `idx_activity_date` (`activity_id`, `statistics_date`),
                                              KEY `idx_inviter_uid` (`inviter_uid`),
                                              KEY `idx_friend_uid` (`friend_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='活动统计明细表';

-- 创建活动统计数据同步日志表
CREATE TABLE IF NOT EXISTS `activity_statistics_sync_log` (
                                                              `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `activity_id` bigint(20) NOT NULL COMMENT '活动ID',
    `sync_date` datetime NOT NULL COMMENT '同步日期',
    `sync_type` varchar(20) NOT NULL COMMENT '同步类型：FULL-全量同步，INCREMENTAL-增量同步',
    `status` varchar(20) NOT NULL COMMENT '同步状态：RUNNING-运行中，SUCCESS-成功，FAILURE-失败',
    `start_time` datetime NOT NULL COMMENT '开始时间',
    `end_time` datetime DEFAULT NULL COMMENT '结束时间',
    `duration` bigint(20) DEFAULT NULL COMMENT '执行时长（毫秒）',
    `participant_count` int(11) DEFAULT NULL COMMENT '参与人数',
    `registered_count` int(11) DEFAULT NULL COMMENT '注册人数',
    `deposit_count` int(11) DEFAULT NULL COMMENT '入金人数',
    `trade_count` int(11) DEFAULT NULL COMMENT '交易人数',
    `one_friend_assist_count` int(11) DEFAULT NULL COMMENT '1人助力人数',
    `two_friend_assist_count` int(11) DEFAULT NULL COMMENT '2人助力人数',
    `error_message` text COMMENT '错误信息',
    `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_activity_id` (`activity_id`),
    KEY `idx_sync_date` (`sync_date`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='活动统计数据同步日志表';

-- ========================================
-- 用户参与次数功能设计说明
-- ========================================
-- 
-- 1. 参与次数概念：
--    - referral_count 字段表示用户参与活动的累计次数，从1开始递增
--    - 每个用户参与一个新活动时，referral_count 自动递增
--    - 同一用户同一活动只能参与一次
--
-- 2. 约束设计：
--    - uk_user_activity: 确保同一用户同一活动只能有一条记录
--    - referral_count 记录用户跨所有活动的参与次数
--
-- 3. 索引优化：
--    - idx_user_referral_count: 支持按用户查询参与历史，提升查询性能
--    - idx_activity_time: 支持按活动查询参与记录
--
-- 4. 业务场景：
--    - 用户首次参与任何活动：referral_count = 1
--    - 用户参与第二个活动：referral_count = 2
--    - 用户参与第三个活动：referral_count = 3
--    - 查询用户参与历史：WHERE user_id = ? ORDER BY referral_count
--    - 查询特定活动参与者：WHERE activity_id = ?
--
-- 5. 数据一致性：
--    - 插入新记录时，需要查询用户当前最大 referral_count 并 +1
--    - 确保 referral_count 的连续性和唯一性
--
-- ========================================

