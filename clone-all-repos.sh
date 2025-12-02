#!/bin/bash

# 从 GitHub 组织克隆所有仓库
# Usage: ./clone-all-repos.sh

set -e

ORG="decodeex-crypto"
GITHUB_TOKEN="${GITHUB_TOKEN:-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}"

echo "=========================================="
echo "从 GitHub 组织拉取所有仓库: $ORG"
echo "=========================================="
echo ""

# 获取所有仓库列表
echo "正在获取仓库列表..."
repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$ORG/repos?per_page=100&type=all" | \
    grep -o '"name": "[^"]*' | \
    sed 's/"name": "//')

if [ -z "$repos" ]; then
    echo "错误：无法获取仓库列表"
    echo "请检查 GitHub Token 是否有效"
    exit 1
fi

total=$(echo "$repos" | wc -l | xargs)
current=0

echo "找到 $total 个仓库"
echo ""

for repo in $repos; do
    current=$((current + 1))
    echo "[$current/$total] 处理仓库: $repo"
    
    if [ -d "$repo" ]; then
        echo "  ✓ 目录已存在，拉取最新代码..."
        cd "$repo"
        
        # 检查是否有未提交的修改
        if [ -n "$(git status --porcelain)" ]; then
            echo "  ⚠ 有未提交的修改，跳过拉取"
            git status --short
        else
            branch=$(git rev-parse --abbrev-ref HEAD)
            git pull origin "$branch"
            echo "  ✓ 拉取成功"
        fi
        
        cd ..
    else
        echo "  → 克隆新仓库..."
        git clone "https://$GITHUB_TOKEN@github.com/$ORG/$repo.git"
        echo "  ✓ 克隆成功"
    fi
    
    echo ""
done

echo "=========================================="
echo "完成！所有仓库已同步"
echo "=========================================="
