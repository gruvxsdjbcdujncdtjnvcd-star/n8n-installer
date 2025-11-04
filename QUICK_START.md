# Быстрый запуск из архива

## Если вы уже загрузили minimal-installer.tar.gz на сервер:

### 1. Подключитесь к серверу по SSH

```bash
ssh root@your-server-ip
```

### 2. Перейдите в директорию где лежит архив

```bash
# Обычно это одна из этих директорий:
cd /root
# или
cd ~
# или
cd /tmp
```

### 3. Проверьте что архив есть

```bash
ls -lh minimal-installer.tar.gz
```

Должно показать примерно: `-rw-r--r-- 1 root root 18K ... minimal-installer.tar.gz`

### 4. Создайте директорию для установки

```bash
mkdir -p /root/minimal-ai-stack
cd /root/minimal-ai-stack
```

### 5. Распакуйте архив

```bash
tar xzf /path/to/minimal-installer.tar.gz
```

Например, если архив в /root:
```bash
tar xzf /root/minimal-installer.tar.gz
```

Или если в /tmp:
```bash
tar xzf /tmp/minimal-installer.tar.gz
```

### 6. Проверьте что файлы распаковались

```bash
ls -la
```

Должны быть эти файлы:
- docker-compose.minimal.yml
- Caddyfile.minimal
- .env.minimal
- install-minimal.sh
- README.minimal.md
- searxng/ (директория)
- supabase/ (директория, может быть пустой - не страшно)
- n8n/ (директория)

### 7. Сделайте скрипт исполняемым

```bash
chmod +x install-minimal.sh
```

### 8. Запустите установщик

```bash
sudo bash install-minimal.sh
```

## Что будет происходить:

1. **Проверка Docker** - установлен ли Docker и Docker Compose
2. **Генерация секретов** - автоматически создаются все пароли
3. **Вопросы** - установщик спросит:
   - Домены для сервисов (n8n.yourdomain.com, и т.д.)
   - Cloudflare Tunnel Token
   - Логины и пароли для SearXNG, Supabase, Langfuse
4. **Скачивание Supabase файлов** - автоматически
5. **Скачивание SearXNG конфига** - автоматически
6. **Создание .env** - со всеми настройками
7. **Запуск сервисов** - docker compose up -d

## После установки:

В конце установщик покажет:
- URLs всех сервисов
- Все credentials
- Команды для управления

**ВАЖНО: Сохраните эти credentials!**

---

## Troubleshooting

### Ошибка: "tar: This does not look like a tar archive"

Архив повреждён. Попробуйте:

```bash
# Проверьте размер файла
ls -lh minimal-installer.tar.gz

# Если размер очень маленький (< 10KB) - архив повреждён
# Перезагрузите архив на сервер
```

### Ошибка: "Permission denied"

```bash
# Добавьте права на выполнение
chmod +x install-minimal.sh

# Или запустите через bash напрямую
bash install-minimal.sh
```

### Ошибка: "/bin/bash^M: bad interpreter"

Это значит что файл создан в Windows. Исправьте:

```bash
# Способ 1 - через sed
sed -i 's/\r$//' install-minimal.sh

# Способ 2 - через dos2unix (если установлен)
dos2unix install-minimal.sh

# Затем снова запустите
bash install-minimal.sh
```

### Docker не установлен

```bash
# Установите Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Проверьте версию
docker --version
docker compose version
```

### Архив не содержит всех файлов

Не проблема! Установщик сам скачает недостающие:
- Supabase конфигурации
- SearXNG настройки

Просто запустите `bash install-minimal.sh` и скрипт всё сделает.

---

## Альтернативный способ (если архив не работает)

Создайте файлы вручную на сервере:

```bash
cd /root/minimal-ai-stack

# Скачайте файлы из GitHub (если вы их туда залили)
wget https://raw.githubusercontent.com/username/repo/main/docker-compose.minimal.yml
wget https://raw.githubusercontent.com/username/repo/main/Caddyfile.minimal
wget https://raw.githubusercontent.com/username/repo/main/.env.minimal
wget https://raw.githubusercontent.com/username/repo/main/install-minimal.sh
wget https://raw.githubusercontent.com/username/repo/main/README.minimal.md

chmod +x install-minimal.sh
bash install-minimal.sh
```

---

## Проверка после запуска

```bash
# Посмотрите статус контейнеров
docker compose -f docker-compose.minimal.yml ps

# Должны быть запущены (~20 контейнеров):
# - n8n
# - langfuse-web, langfuse-worker
# - qdrant
# - searxng
# - supabase-* (14 контейнеров)
# - postgres, redis, clickhouse, minio
# - caddy, cloudflared

# Проверьте логи
docker compose -f docker-compose.minimal.yml logs -f

# Проверьте что Cloudflare Tunnel подключён
docker logs cloudflared
# Должно быть: "Registered tunnel connection"
```

---

## Управление сервисами

```bash
# Остановить все
docker compose -f docker-compose.minimal.yml down

# Запустить все
docker compose -f docker-compose.minimal.yml up -d

# Перезапустить конкретный сервис
docker compose -f docker-compose.minimal.yml restart n8n

# Посмотреть логи
docker compose -f docker-compose.minimal.yml logs -f n8n

# Удалить всё (включая данные!)
docker compose -f docker-compose.minimal.yml down -v
```

---

## Нужна помощь?

1. Проверьте логи: `docker compose -f docker-compose.minimal.yml logs`
2. Проверьте статус: `docker compose -f docker-compose.minimal.yml ps`
3. Прочитайте README.minimal.md для подробной информации
4. Создайте Issue на GitHub с логами ошибок
