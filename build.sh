#!/bin/bash
# chuanqi 项目统一构建脚本
# 作用：从当前环境读取本地代理端口（动态变化），注入 Gradle，避免硬编码端口导致构建失败
# 所有工具链与缓存均位于 E:/codex/chuanqi 下，不写入 C 盘

set -e

ROOT="E:/codex/chuanqi"
TOOLS="$ROOT/tools"
JDK="$TOOLS/jdk-17.0.20.1+1"
GRADLE="$TOOLS/gradle-9.3.1/bin/gradle"
GRADLE_HOME="$ROOT/.gradle-home"
M2="$ROOT/.m2/repository"
ENGINE="$ROOT/engine/mindustry"

# 从环境读取当前代理端口（本机隧道端口每次会话可能变化）
PORT="${https_proxy##*:}"
PORT="${PORT%%/}"
PORT="${PORT:-${HTTPS_PROXY##*:}}"
PORT="${PORT%%/}"

if [ -n "$PORT" ]; then
  cat > "$GRADLE_HOME/gradle.properties" <<EOF
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=$PORT
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=$PORT
systemProp.http.nonProxyHosts=localhost|127.0.0.1|*.aliyun.com|maven.aliyun.com|*.aliyuncs.com
systemProp.https.nonProxyHosts=localhost|127.0.0.1|*.aliyun.com|maven.aliyun.com|*.aliyuncs.com
EOF
  echo "[build] proxy port = $PORT"
fi

export JAVA_HOME="$JDK"
export GRADLE_USER_HOME="$GRADLE_HOME"

cd "$ENGINE"
echo "[build] running: $GRADLE $*"
exec "$GRADLE" "$@"
