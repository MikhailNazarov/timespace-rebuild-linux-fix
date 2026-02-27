#!/usr/bin/env bash
set -euo pipefail

# Time Space Rebuild (時空重構) — Linux video fix
# Расшифровывает и перемуксирует внутриигровые видео для работы через Proton

# --- Поиск папки игры ---

if [ -n "${1:-}" ]; then
    GAME_ROOT="$1"
else
    GAME_ROOT="$HOME/.local/share/Steam/steamapps/common/時空重構"
fi

GAME_DIR="$GAME_ROOT/時空重構"
STREAMING="$GAME_DIR/時空重構_Data/StreamingAssets"
CLIPS="$STREAMING/CommonVideoClips"
CLIPS_4K="$GAME_ROOT/TimeRebuildSpace4KVideo"

if [ ! -d "$CLIPS" ]; then
    echo "ОШИБКА: Папка с видео не найдена: $CLIPS"
    echo "Укажите путь к игре: $0 /path/to/steamapps/common/時空重構"
    exit 1
fi

# --- Проверка зависимостей ---

for cmd in ffmpeg openssl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ОШИБКА: $cmd не установлен"
        exit 1
    fi
done

# --- Функция обработки одной папки с видео ---

process_clips() {
    local clips="$1"
    local label="$2"
    local backup="${clips}.bak"

    if [ -d "$backup" ]; then
        echo "[$label] Бэкап уже существует: $backup — пропуск."
        return
    fi

    # Извлечение ключа
    local key_file="$clips/encrypt.key"
    if [ ! -f "$key_file" ]; then
        echo "[$label] ОШИБКА: Файл ключа не найден: $key_file"
        return 1
    fi

    local key iv first_m3u8
    key=$(od -A n -t x1 "$key_file" | tr -d ' \n')

    first_m3u8=$(find "$clips" -maxdepth 1 -name '*.m3u8' -print -quit)
    iv=$(grep -oP 'IV=0x\K[0-9a-fA-F]+' "$first_m3u8")

    if [ -z "$iv" ]; then
        echo "[$label] ОШИБКА: Не удалось извлечь IV из $first_m3u8"
        return 1
    fi

    # Бэкап
    echo "[$label] Создание бэкапа..."
    cp -r "$clips" "$backup"

    # Расшифровка
    local ts_count count=0 errors=0
    ts_count=$(find "$clips" -maxdepth 1 -name '*.ts' | wc -l)
    echo "[$label] Расшифровка $ts_count .ts файлов..."

    for f in "$clips"/*.ts; do
        if openssl aes-128-cbc -d -K "$key" -iv "$iv" -in "$f" -out "${f}.dec" 2>/dev/null; then
            mv "${f}.dec" "$f"
            count=$((count + 1))
        else
            rm -f "${f}.dec"
            errors=$((errors + 1))
        fi

        local total=$((count + errors))
        if [ $((total % 100)) -eq 0 ]; then
            echo "  $total / $ts_count..."
        fi
    done
    echo "  Расшифровано: $count, ошибок: $errors"

    if [ "$errors" -gt 0 ]; then
        echo "  ПРЕДУПРЕЖДЕНИЕ: Некоторые файлы не удалось расшифровать"
    fi

    # Ремуксирование
    local m3u8_count
    m3u8_count=$(find "$backup" -maxdepth 1 -name '*.m3u8' | wc -l)
    echo "[$label] Ремуксирование $m3u8_count видео..."

    count=0
    errors=0
    for m3u8 in "$backup"/*.m3u8; do
        local name ts_files=""
        name=$(basename "$m3u8")

        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            ts_files="$ts_files|$clips/$line"
        done < "$m3u8"
        ts_files="${ts_files:1}"

        if [ -n "$ts_files" ]; then
            if ffmpeg -y -i "concat:${ts_files}" -c copy -f mpegts "$clips/$name" 2>/dev/null; then
                count=$((count + 1))
            else
                errors=$((errors + 1))
                echo "  ОШИБКА: $name"
            fi
        fi

        local total=$((count + errors))
        if [ $((total % 50)) -eq 0 ]; then
            echo "  $total / $m3u8_count..."
        fi
    done
    echo "  Ремуксировано: $count, ошибок: $errors"
}

# --- Основной процесс ---

echo "=== Time Space Rebuild — Linux Video Fix ==="
echo "Папка игры: $GAME_ROOT"
echo ""

process_clips "$CLIPS" "SD"

if [ -d "$CLIPS_4K" ]; then
    echo ""
    process_clips "$CLIPS_4K" "4K"
fi

echo ""
echo "=== Готово ==="
echo ""
echo "Убедитесь, что в Steam выбран GE-Proton для этой игры."
echo ""
echo "Бэкап оригиналов: ${CLIPS}.bak"
if [ -d "${CLIPS_4K}.bak" ]; then
    echo "Бэкап 4K: ${CLIPS_4K}.bak"
fi
echo "Для освобождения места можно удалить бэкапы после проверки работоспособности."
