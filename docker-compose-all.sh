#!/bin/zsh
# docker-compose-all.sh - 统一的 Docker 服务构建和管理脚本
# 用法:
#   ./docker-compose-all.sh build [service]   - 构建 Docker 镜像
#   ./docker-compose-all.sh start [service]   - 启动服务
#   ./docker-compose-all.sh stop [service]    - 停止服务
#   ./docker-compose-all.sh restart [service] - 重启服务
#   ./docker-compose-all.sh status            - 查看服务状态
#   ./docker-compose-all.sh logs [service]    - 查看服务日志
#   ./docker-compose-all.sh list              - 列出所有服务
#   ./docker-compose-all.sh pull-images       - 拉取所有基础镜像

set -e

PROJECT_ROOT="$HOME/bifu-projects"
cd "$PROJECT_ROOT"

# DaoCloud 镜像加速器
DAOCLOUD_MIRROR="docker.m.daocloud.io"

# 需要预拉取的基础镜像列表
typeset -A BASE_IMAGES
BASE_IMAGES=(
    # JDK 镜像 (Maven/Gradle 项目)
    "eclipse-temurin:17.0.11_9-jdk-jammy" "library/eclipse-temurin:17.0.11_9-jdk-jammy"
    "eclipse-temurin:17-jdk-jammy" "library/eclipse-temurin:17-jdk-jammy"
    # Node.js 镜像
    "node:18.19-alpine3.19" "library/node:18.19-alpine3.19"
    "node:18-alpine" "library/node:18-alpine"
    # Go 镜像
    "golang:alpine" "library/golang:alpine"
    "golang:1.21-alpine" "library/golang:1.21-alpine"
    # Alpine 基础镜像
    "alpine:latest" "library/alpine:latest"
    "alpine:3.19" "library/alpine:3.19"
)

# 定义所有服务及其类型
# 格式: "服务名:类型" - 类型: maven, gradle, go, node
typeset -A SERVICES
SERVICES=(
    # 基础组件 (仅编译，不构建镜像)
    unimargin-protos proto
    unimargin-common maven-lib
    sofa-jraft maven-lib
    
    # Maven 项目
    decode-admin-server maven
    spot-trade-proxy maven
    spot-trade-server maven
    unimargin-funding-server maven
    unimargin-grpc-gateway maven
    unimargin-history-server maven
    unimargin-http-gateway maven
    unimargin-index-server maven
    unimargin-liquidate-server maven
    unimargin-match-server maven
    unimargin-quote-proxy maven
    unimargin-quote-server maven
    unimargin-trade-proxy maven
    unimargin-trade-server maven
    unimargin-websocket-gateway maven
    
    # Gradle 项目
    unimargin-activity-server gradle
    
    # Go 项目
    market-maker-server go
    
    # Node.js 项目
    decode-web node
    decode-web-admin node
)

# 服务构建顺序 (基础组件优先)
BUILD_ORDER=(
    "unimargin-protos"
    "unimargin-common"
    "sofa-jraft"
    "decode-admin-server"
    "spot-trade-proxy"
    "spot-trade-server"
    "unimargin-funding-server"
    "unimargin-grpc-gateway"
    "unimargin-http-gateway"
    "unimargin-history-server"
    "unimargin-index-server"
    "unimargin-liquidate-server"
    "unimargin-match-server"
    "unimargin-quote-proxy"
    "unimargin-quote-server"
    "unimargin-trade-proxy"
    "unimargin-trade-server"
    "unimargin-websocket-gateway"
    "unimargin-activity-server"
    "market-maker-server"
    "decode-web"
    "decode-web-admin"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 通过 DaoCloud 镜像拉取基础镜像
pull_image_via_daocloud() {
    local image=$1
    local daocloud_path=${BASE_IMAGES[$image]}
    
    if [ -z "$daocloud_path" ]; then
        log_warn "未找到镜像 $image 的 DaoCloud 映射，尝试直接拉取"
        docker pull "$image" 2>/dev/null && return 0
        return 1
    fi
    
    # 检查镜像是否已存在
    if docker image inspect "$image" &>/dev/null; then
        log_info "镜像已存在: $image"
        return 0
    fi
    
    log_step "通过 DaoCloud 拉取: $image"
    local daocloud_url="${DAOCLOUD_MIRROR}/${daocloud_path}"
    
    if docker pull "$daocloud_url"; then
        docker tag "$daocloud_url" "$image"
        log_info "镜像拉取成功: $image"
        return 0
    else
        log_error "镜像拉取失败: $image"
        return 1
    fi
}

# 拉取所有基础镜像
pull_all_base_images() {
    log_info "开始拉取所有基础镜像 (通过 DaoCloud 加速)..."
    echo ""
    
    local failed_images=()
    local success_count=0
    
    for image in "${(@k)BASE_IMAGES}"; do
        if pull_image_via_daocloud "$image"; then
            success_count=$((success_count + 1))
        else
            failed_images+=("$image")
        fi
        echo ""
    done
    
    echo "========================================"
    log_info "镜像拉取摘要"
    echo "========================================"
    log_info "成功: $success_count 个"
    
    if [ ${#failed_images[@]} -gt 0 ]; then
        log_error "失败: ${#failed_images[@]} 个"
        for img in "${failed_images[@]}"; do
            echo "  - $img"
        done
    fi
    
    echo ""
    log_info "当前基础镜像:"
    docker images | grep -E "(eclipse-temurin|node|golang|alpine)" | head -20 || true
}

# 检查并自动拉取缺失的基础镜像
ensure_base_images() {
    local images_to_pull=()
    
    # 检查常用基础镜像是否存在
    local required_images=(
        "eclipse-temurin:17.0.11_9-jdk-jammy"
        "node:18.19-alpine3.19"
        "golang:alpine"
        "alpine:latest"
    )
    
    for image in "${required_images[@]}"; do
        if ! docker image inspect "$image" &>/dev/null; then
            images_to_pull+=("$image")
        fi
    done
    
    if [ ${#images_to_pull[@]} -gt 0 ]; then
        log_info "检测到缺失的基础镜像，正在自动拉取..."
        for image in "${images_to_pull[@]}"; do
            pull_image_via_daocloud "$image"
        done
        echo ""
    fi
}

# 检查服务目录是否存在
check_service_dir() {
    local service=$1
    if [ ! -d "$PROJECT_ROOT/$service" ]; then
        log_error "服务目录不存在: $service"
        return 1
    fi
    return 0
}

# 构建 Proto 文件
build_proto() {
    local service=$1
    log_step "构建 Proto 文件: $service"
    cd "$PROJECT_ROOT/$service"
    
    if [ -f "Makefile" ]; then
        make generate || log_warn "Proto 生成可能失败，请检查"
    else
        log_warn "没有找到 Makefile，跳过 proto 生成"
    fi
}

# 构建 Maven 库项目 (仅 mvn install，不构建镜像)
build_maven_lib() {
    local service=$1
    log_step "构建 Maven 库: $service"
    cd "$PROJECT_ROOT/$service"
    
    mvn clean install -DskipTests -q
    log_info "Maven 库构建完成: $service"
}

# 构建 Maven 项目
build_maven() {
    local service=$1
    log_step "构建 Maven 项目: $service"
    cd "$PROJECT_ROOT/$service"
    
    # 先编译
    mvn clean package -DskipTests -q
    
    # 再构建 Docker 镜像
    if [ -f "Dockerfile" ]; then
        log_info "构建 Docker 镜像: $service"
        docker build -t "$service:latest" .
    else
        log_warn "没有找到 Dockerfile，跳过镜像构建"
    fi
}

# 构建 Gradle 项目
build_gradle() {
    local service=$1
    log_step "构建 Gradle 项目: $service"
    cd "$PROJECT_ROOT/$service"
    
    # 先编译
    ./gradlew clean build -x test --quiet
    
    # 再构建 Docker 镜像
    if [ -f "Dockerfile" ]; then
        log_info "构建 Docker 镜像: $service"
        docker build -t "$service:latest" .
    else
        log_warn "没有找到 Dockerfile，跳过镜像构建"
    fi
}

# 构建 Go 项目
build_go() {
    local service=$1
    log_step "构建 Go 项目: $service"
    cd "$PROJECT_ROOT/$service"
    
    # 先编译
    if [ -f "Makefile" ]; then
        make build || go build -o bin/server ./...
    else
        go build -o bin/server ./...
    fi
    
    # 再构建 Docker 镜像
    if [ -f "Dockerfile" ]; then
        log_info "构建 Docker 镜像: $service"
        docker build -t "$service:latest" .
    else
        log_warn "没有找到 Dockerfile，跳过镜像构建"
    fi
}

# 构建 Node.js 项目
build_node() {
    local service=$1
    log_step "构建 Node.js 项目: $service"
    cd "$PROJECT_ROOT/$service"
    
    # 安装依赖并构建
    npm install
    npm run build || log_warn "npm run build 可能失败或不存在"
    
    # 再构建 Docker 镜像
    if [ -f "Dockerfile" ]; then
        log_info "构建 Docker 镜像: $service"
        docker build -t "$service:latest" .
    else
        log_warn "没有找到 Dockerfile，跳过镜像构建"
    fi
}

# 根据类型构建服务
build_service() {
    local service=$1
    local type=${SERVICES[$service]}
    
    if [ -z "$type" ]; then
        log_error "未知服务: $service"
        return 1
    fi
    
    check_service_dir "$service" || return 1
    
    case $type in
        proto)
            build_proto "$service"
            ;;
        maven-lib)
            build_maven_lib "$service"
            ;;
        maven)
            build_maven "$service"
            ;;
        gradle)
            build_gradle "$service"
            ;;
        go)
            build_go "$service"
            ;;
        node)
            build_node "$service"
            ;;
        *)
            log_error "未知项目类型: $type"
            return 1
            ;;
    esac
}

# 构建所有服务
build_all() {
    log_info "开始构建所有服务..."
    
    # 先检查并拉取缺失的基础镜像
    ensure_base_images
    
    local failed_services=()
    local count=0
    
    for service in "${BUILD_ORDER[@]}"; do
        echo ""
        echo "========================================"
        log_info "构建 ($((++count))/${#BUILD_ORDER[@]}): $service"
        echo "========================================"
        
        if ! build_service "$service"; then
            failed_services+=("$service")
            log_error "构建失败: $service"
        fi
    done
    
    echo ""
    echo "========================================"
    log_info "构建完成摘要"
    echo "========================================"
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_info "所有服务构建成功!"
    else
        log_error "以下服务构建失败:"
        for s in "${failed_services[@]}"; do
            echo "  - $s"
        done
    fi
    
    # 显示 Docker 镜像列表
    echo ""
    log_info "当前 Docker 镜像:"
    docker images | grep -E "(unimargin|decode|spot|market|sofa)" | head -30 || true
}

# 启动服务
start_service() {
    local service=$1
    log_step "启动服务: $service"
    cd "$PROJECT_ROOT/$service"
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose up -d
    else
        # 使用默认配置启动
        docker run -d --name "$service" "$service:latest"
    fi
}

# 停止服务
stop_service() {
    local service=$1
    log_step "停止服务: $service"
    
    if [ -f "$PROJECT_ROOT/$service/docker-compose.yml" ]; then
        cd "$PROJECT_ROOT/$service"
        docker-compose down
    else
        docker stop "$service" 2>/dev/null || true
        docker rm "$service" 2>/dev/null || true
    fi
}

# 停止所有服务
stop_all() {
    log_info "停止所有服务..."
    for service in "${!SERVICES[@]}"; do
        local type=${SERVICES[$service]}
        if [ "$type" != "proto" ] && [ "$type" != "maven-lib" ]; then
            stop_service "$service"
        fi
    done
}

# 显示服务状态
status_all() {
    log_info "服务状态:"
    echo ""
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | \
        grep -E "(unimargin|decode|spot|market|sofa)" || echo "没有运行中的服务"
}

# 查看服务日志
logs_service() {
    local service=$1
    if [ -f "$PROJECT_ROOT/$service/docker-compose.yml" ]; then
        cd "$PROJECT_ROOT/$service"
        docker-compose logs -f
    else
        docker logs -f "$service"
    fi
}

# 列出所有服务
list_services() {
    echo "可用服务列表:"
    echo ""
    printf "%-30s %-15s\n" "服务名" "类型"
    printf "%-30s %-15s\n" "------" "----"
    for service in "${BUILD_ORDER[@]}"; do
        printf "%-30s %-15s\n" "$service" "${SERVICES[$service]}"
    done
}

# 主函数
main() {
    local command=${1:-help}
    local service=$2
    
    case $command in
        build)
            if [ -n "$service" ]; then
                build_service "$service"
            else
                build_all
            fi
            ;;
        pull-images)
            pull_all_base_images
            ;;
        start)
            if [ -n "$service" ]; then
                start_service "$service"
            else
                log_error "请指定要启动的服务"
            fi
            ;;
        stop)
            if [ -n "$service" ]; then
                stop_service "$service"
            else
                stop_all
            fi
            ;;
        restart)
            if [ -n "$service" ]; then
                stop_service "$service"
                start_service "$service"
            else
                log_error "请指定要重启的服务"
            fi
            ;;
        status)
            status_all
            ;;
        logs)
            if [ -n "$service" ]; then
                logs_service "$service"
            else
                log_error "请指定要查看日志的服务"
            fi
            ;;
        list)
            list_services
            ;;
        help|*)
            echo "用法: $0 {build|pull-images|start|stop|restart|status|logs|list} [service]"
            echo ""
            echo "命令:"
            echo "  build [service]   - 构建 Docker 镜像 (不指定则构建所有)"
            echo "  pull-images       - 通过 DaoCloud 拉取所有基础镜像"
            echo "  start <service>   - 启动指定服务"
            echo "  stop [service]    - 停止服务 (不指定则停止所有)"
            echo "  restart <service> - 重启指定服务"
            echo "  status            - 查看所有服务状态"
            echo "  logs <service>    - 查看服务日志"
            echo "  list              - 列出所有可用服务"
            echo ""
            echo "示例:"
            echo "  $0 pull-images               # 拉取所有基础镜像"
            echo "  $0 build                     # 构建所有服务"
            echo "  $0 build unimargin-match-server  # 构建指定服务"
            echo "  $0 status                    # 查看状态"
            ;;
    esac
}

main "$@"
