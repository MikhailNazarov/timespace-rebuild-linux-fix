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
BACKUP="${CLIPS}.bak"

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

# --- Проверка что скрипт не запускался ранее ---

if [ -d "$BACKUP" ]; then
    echo "Бэкап уже существует: $BACKUP"
    echo "Похоже, скрипт уже запускался. Для повторного запуска удалите бэкап."
    exit 1
fi

# --- Извлечение ключа шифрования ---

KEY_FILE="$CLIPS/encrypt.key"
if [ ! -f "$KEY_FILE" ]; then
    echo "ОШИБКА: Файл ключа не найден: $KEY_FILE"
    exit 1
fi

KEY=$(xxd -p "$KEY_FILE" | tr -d '\n')

# Извлечение IV из первого m3u8 файла
FIRST_M3U8=$(ls "$CLIPS"/*.m3u8 | head -1)
IV=$(grep -oP 'IV=0x\K[0-9a-fA-F]+' "$FIRST_M3U8" | head -1)

if [ -z "$IV" ]; then
    echo "ОШИБКА: Не удалось извлечь IV из $FIRST_M3U8"
    exit 1
fi

echo "=== Time Space Rebuild — Linux Video Fix ==="
echo "Папка игры: $GAME_ROOT"
echo "Ключ: $KEY"
echo "IV: $IV"
echo ""

# --- Создание бэкапа ---

echo "[1/3] Создание бэкапа..."
cp -r "$CLIPS" "$BACKUP"
echo "  Бэкап: $BACKUP"

# --- Расшифровка .ts файлов ---

TS_COUNT=$(ls "$CLIPS"/*.ts 2>/dev/null | wc -l)
echo "[2/3] Расшифровка $TS_COUNT .ts файлов..."

count=0
errors=0
for f in "$CLIPS"/*.ts; do
    if openssl aes-128-cbc -d -K "$KEY" -iv "$IV" -in "$f" -out "${f}.dec" 2>/dev/null; then
        mv "${f}.dec" "$f"
        count=$((count + 1))
    else
        rm -f "${f}.dec"
        errors=$((errors + 1))
    fi

    # Прогресс
    total=$((count + errors))
    if [ $((total % 100)) -eq 0 ]; then
        echo "  $total / $TS_COUNT..."
    fi
done
echo "  Расшифровано: $count, ошибок: $errors"

if [ "$errors" -gt 0 ]; then
    echo "ПРЕДУПРЕЖДЕНИЕ: Некоторые файлы не удалось расшифровать"
fi

# --- Сборка и ремуксирование m3u8 → MPEG-TS ---

M3U8_COUNT=$(ls "$BACKUP"/*.m3u8 2>/dev/null | wc -l)
echo "[3/3] Ремуксирование $M3U8_COUNT видео..."

count=0
errors=0
for m3u8 in "$BACKUP"/*.m3u8; do
    name=$(basename "$m3u8")

    # Собираем список .ts файлов из оригинального плейлиста
    ts_files=""
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        ts_files="$ts_files|$CLIPS/$line"
    done < "$m3u8"
    ts_files="${ts_files:1}"

    if [ -n "$ts_files" ]; then
        if ffmpeg -y -i "concat:${ts_files}" -c copy -f mpegts "$CLIPS/$name" 2>/dev/null; then
            count=$((count + 1))
        else
            errors=$((errors + 1))
            echo "  ОШИБКА: $name"
        fi
    fi

    # Прогресс
    total=$((count + errors))
    if [ $((total % 50)) -eq 0 ]; then
        echo "  $total / $M3U8_COUNT..."
    fi
done
echo "  Ремуксировано: $count, ошибок: $errors"

echo ""
echo "=== Готово ==="
echo ""
echo "Не забудьте добавить параметр запуска в Steam:"
echo "  PROTON_MEDIA_USE_GST=1 %command%"
echo ""
echo "Бэкап оригиналов: $BACKUP"
echo "Для освобождения места можно удалить бэкап после проверки работоспособности."
