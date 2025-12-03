.PHONY: all clean help maven-projects gradle-projects go-projects node-projects jraft

# 默认目标：编译所有工程
all: jraft maven-projects gradle-projects go-projects node-projects
	@echo "=========================================="
	@echo "所有工程编译完成！"
	@echo "=========================================="

# 帮助信息
help:
	@echo "可用的编译目标："
	@echo "  make all              - 编译所有工程"
	@echo "  make jraft            - 编译 sofa-jraft (jraft-core)"
	@echo "  make maven-projects   - 编译所有 Maven 项目"
	@echo "  make gradle-projects  - 编译所有 Gradle 项目"
	@echo "  make go-projects      - 编译所有 Go 项目"
	@echo "  make node-projects    - 编译所有 Node.js 项目"
	@echo "  make clean            - 清理所有编译产物"

# 编译 sofa-jraft jraft-core 模块
jraft:
	@echo "=========================================="
	@echo "编译 sofa-jraft/jraft-core..."
	@echo "=========================================="
	cd sofa-jraft/jraft-core && \
		mvn clean install -DskipTests -Dmain.user.dir=$(PWD)/sofa-jraft && \
		find target/classes -name "enum.proto" -exec rm -f {} + 2>/dev/null || true

# 编译所有 Maven 项目
maven-projects: \
	unimargin-protos \
	unimargin-common \
	decode-admin-server \
	spot-trade-proxy \
	unimargin-funding-server \
	spot-trade-server \
	unimargin-grpc-gateway \
	unimargin-history-server \
	unimargin-http-gateway \
	unimargin-index-server \
	unimargin-liquidate-server \
	unimargin-match-server \
	unimargin-quote-proxy \
	unimargin-quote-server \
	unimargin-trade-proxy \
	unimargin-trade-server \
	unimargin-websocket-gateway
	@echo "所有 Maven 项目编译完成"

# 单独的 Maven 项目目标
unimargin-protos:
	@echo "编译 unimargin-protos..."
	cd unimargin-protos && mvn clean install -DskipTests

unimargin-common:
	@echo "编译 unimargin-common..."
	cd unimargin-common && mvn clean install -DskipTests

decode-admin-server:
	@echo "编译 decode-admin-server..."
	cd decode-admin-server && mvn clean compile

spot-trade-proxy:
	@echo "编译 spot-trade-proxy..."
	cd spot-trade-proxy && mvn clean compile

unimargin-funding-server:
	@echo "编译 unimargin-funding-server..."
	cd unimargin-funding-server && mvn clean compile

spot-trade-server:
	@echo "编译 spot-trade-server..."
	cd spot-trade-server && mvn clean compile

unimargin-grpc-gateway:
	@echo "编译 unimargin-grpc-gateway..."
	cd unimargin-grpc-gateway && mvn clean compile

unimargin-history-server:
	@echo "编译 unimargin-history-server..."
	cd unimargin-history-server && mvn clean compile

unimargin-http-gateway:
	@echo "编译 unimargin-http-gateway..."
	cd unimargin-http-gateway && mvn clean compile

unimargin-index-server:
	@echo "编译 unimargin-index-server..."
	cd unimargin-index-server && mvn clean compile

unimargin-liquidate-server:
	@echo "编译 unimargin-liquidate-server..."
	cd unimargin-liquidate-server && mvn clean compile

unimargin-match-server:
	@echo "编译 unimargin-match-server..."
	cd unimargin-match-server && mvn clean compile

unimargin-quote-proxy:
	@echo "编译 unimargin-quote-proxy..."
	cd unimargin-quote-proxy && mvn clean compile

unimargin-quote-server:
	@echo "编译 unimargin-quote-server..."
	cd unimargin-quote-server && mvn clean compile

unimargin-trade-proxy:
	@echo "编译 unimargin-trade-proxy..."
	cd unimargin-trade-proxy && mvn clean compile

unimargin-trade-server:
	@echo "编译 unimargin-trade-server..."
	cd unimargin-trade-server && mvn clean compile

unimargin-websocket-gateway:
	@echo "编译 unimargin-websocket-gateway..."
	cd unimargin-websocket-gateway && mvn clean compile

# 编译所有 Gradle 项目
gradle-projects: unimargin-activity-server
	@echo "所有 Gradle 项目编译完成"

unimargin-activity-server:
	@echo "编译 unimargin-activity-server..."
	cd unimargin-activity-server && ./gradlew clean build -x test

# 编译所有 Go 项目
go-projects: market-maker-server
	@echo "所有 Go 项目编译完成"

market-maker-server:
	@echo "编译 market-maker-server..."
	cd market-maker-server && go mod vendor && make mac

# 编译所有 Node.js 项目
node-projects: decode-web decode-web-admin
	@echo "所有 Node.js 项目编译完成"

decode-web:
	@echo "编译 decode-web..."
	cd decode-web && npm run build:production

decode-web-admin:
	@echo "编译 decode-web-admin..."
	cd decode-web-admin && npm run build:production

# 清理所有编译产物
clean:
	@echo "清理所有编译产物..."
	@echo "清理 Maven 项目..."
	@find . -type d -name "target" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "清理 Gradle 项目..."
	@find . -type d -name "build" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "清理 Go 项目..."
	@find . -type d -name "vendor" -prune -exec rm -rf {} + 2>/dev/null || true
	@cd market-maker-server && make clean 2>/dev/null || true
	@echo "清理 Node.js 项目..."
	@cd decode-web && rm -rf dist 2>/dev/null || true
	@cd decode-web-admin && rm -rf dist 2>/dev/null || true
	@echo "清理完成！"
