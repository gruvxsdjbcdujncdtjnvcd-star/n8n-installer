#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Minimal AI Stack - Распаковка архива${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверяем что скрипт не запущен случайно
if [ ! -f "minimal-installer.tar.gz" ]; then
    echo -e "${YELLOW}Внимание: Архив minimal-installer.tar.gz не найден в текущей директории${NC}"
    echo ""
    echo "Где находится ваш архив?"
    echo "Введите полный путь (например: /root/minimal-installer.tar.gz):"
    read -r ARCHIVE_PATH

    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo -e "${RED}Ошибка: Файл $ARCHIVE_PATH не найден${NC}"
        exit 1
    fi
else
    ARCHIVE_PATH="minimal-installer.tar.gz"
fi

echo -e "${GREEN}✓ Архив найден: $ARCHIVE_PATH${NC}"
echo ""

# Показываем информацию об архиве
echo "Информация об архиве:"
ls -lh "$ARCHIVE_PATH"
echo ""

# Спрашиваем куда распаковать
echo "Куда распаковать файлы?"
echo "1) /root/minimal-ai-stack (рекомендуется)"
echo "2) /opt/minimal-ai-stack"
echo "3) Текущая директория"
echo "4) Другая директория (ввести вручную)"
echo ""
read -p "Выберите (1-4): " CHOICE

case $CHOICE in
    1)
        TARGET_DIR="/root/minimal-ai-stack"
        ;;
    2)
        TARGET_DIR="/opt/minimal-ai-stack"
        ;;
    3)
        TARGET_DIR="."
        ;;
    4)
        read -p "Введите путь: " TARGET_DIR
        ;;
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac

# Создаём директорию
if [ "$TARGET_DIR" != "." ]; then
    echo ""
    echo -e "${YELLOW}Создаю директорию: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR" || exit 1
fi

echo ""
echo -e "${GREEN}Распаковываю архив...${NC}"

# Распаковываем
if tar xzf "$ARCHIVE_PATH" 2>/dev/null; then
    echo -e "${GREEN}✓ Архив успешно распакован${NC}"
else
    echo -e "${RED}✗ Ошибка распаковки${NC}"
    echo ""
    echo "Попробуйте вручную:"
    echo "  tar xzf $ARCHIVE_PATH"
    exit 1
fi

echo ""
echo "Содержимое директории:"
ls -lh
echo ""

# Проверяем наличие install-minimal.sh
if [ ! -f "install-minimal.sh" ]; then
    echo -e "${RED}✗ Файл install-minimal.sh не найден в архиве${NC}"
    echo ""
    echo "Создайте файл install-minimal.sh вручную или скачайте из GitHub"
    exit 1
fi

# Делаем исполняемым
chmod +x install-minimal.sh
echo -e "${GREEN}✓ Права на выполнение установлены${NC}"
echo ""

# Проверяем окончания строк
if file install-minimal.sh | grep -q "CRLF"; then
    echo -e "${YELLOW}Исправляю окончания строк (CRLF → LF)...${NC}"
    sed -i 's/\r$//' install-minimal.sh
    echo -e "${GREEN}✓ Окончания строк исправлены${NC}"
    echo ""
fi

# Спрашиваем запустить ли установщик
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Готово к установке!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Текущая директория: $(pwd)"
echo ""
echo "Запустить установщик сейчас?"
echo "  sudo bash install-minimal.sh"
echo ""
read -p "Запустить? (y/N): " RUN_INSTALLER

if [[ $RUN_INSTALLER =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Запускаю установщик...${NC}"
    echo ""
    sudo bash install-minimal.sh
else
    echo ""
    echo -e "${YELLOW}Установщик не запущен${NC}"
    echo ""
    echo "Чтобы запустить его позже:"
    echo -e "  ${GREEN}cd $(pwd)${NC}"
    echo -e "  ${GREEN}sudo bash install-minimal.sh${NC}"
    echo ""
fi
