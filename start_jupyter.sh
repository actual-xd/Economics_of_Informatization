#!/usr/bin/env bash
# Запуск JupyterLab из корня проекта Economics_of_Informatization и открытие в браузере.
# Использование: ./start_jupyter.sh
set -euo pipefail

cd "$(dirname "$0")"

LOG="jupyter.log"
PORT="${PORT:-8888}"

# Не запускать повторно, если сервер уже слушает порт
if curl -sf "http://127.0.0.1:${PORT}/api" >/dev/null 2>&1; then
    echo "Jupyter уже запущен на http://127.0.0.1:${PORT}"
    .venv/bin/jupyter server list 2>/dev/null | rg 'http' || true
    exit 0
fi

nohup .venv/bin/jupyter lab \
    --no-browser \
    --ip=127.0.0.1 \
    --port="${PORT}" \
    --ServerApp.root_dir="$(pwd)" \
    >"${LOG}" 2>&1 &

# Ждём, пока сервер поднимется и в логе появится URL с токеном
URL=""
for _ in $(seq 1 30); do
    URL="$(rg -o 'http://127.0.0.1:[0-9]+/lab\?token=[a-f0-9]+' "${LOG}" 2>/dev/null | head -1 || true)"
    if [ -n "${URL}" ] && curl -sf "http://127.0.0.1:${PORT}/api" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if [ -n "${URL}" ]; then
    echo "JupyterLab запущен (PID $!): ${URL}"
    open "${URL}"
else
    echo "JupyterLab не поднялся за 30 секунд. Смотри ${LOG}" >&2
    exit 1
fi
