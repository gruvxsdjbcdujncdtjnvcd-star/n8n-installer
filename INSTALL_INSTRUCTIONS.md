# Инструкция по установке Minimal AI Stack

## Способ 1: Через GitHub (Рекомендуется)

### На вашем компьютере:

```bash
# 1. Перейдите в папку с проектом n8n-installer
cd /path/to/n8n-installer

# 2. Скопируйте 5 файлов из Claude:
# - docker-compose.minimal.yml
# - Caddyfile.minimal
# - .env.minimal
# - install-minimal.sh
# - README.minimal.md

# 3. Закоммитьте в GitHub
git add docker-compose.minimal.yml Caddyfile.minimal .env.minimal install-minimal.sh README.minimal.md
git commit -m "Add minimal installer for 6 services"
git push origin main
```

### На сервере:

```bash
# 1. Перейдите в папку с проектом
cd /root/n8n-installer

# 2. Подтяните изменения
git pull origin main

# 3. Запустите установщик
sudo bash install-minimal.sh
```

---

## Способ 2: Прямое копирование на сервер

### На вашем компьютере создайте 5 файлов:

#### 1. docker-compose.minimal.yml
Скопируйте содержимое из `/tmp/cc-agent/59709889/project/docker-compose.minimal.yml`

#### 2. Caddyfile.minimal
Скопируйте содержимое из `/tmp/cc-agent/59709889/project/Caddyfile.minimal`

#### 3. .env.minimal
Скопируйте содержимое из `/tmp/cc-agent/59709889/project/.env.minimal`

#### 4. install-minimal.sh
Скопируйте содержимое из `/tmp/cc-agent/59709889/project/install-minimal.sh`

#### 5. README.minimal.md
Скопируйте содержимое из `/tmp/cc-agent/59709889/project/README.minimal.md`

### Затем скопируйте на сервер:

```bash
# Используя scp
scp docker-compose.minimal.yml Caddyfile.minimal .env.minimal install-minimal.sh README.minimal.md root@your-server:/root/n8n-installer/

# Или используя rsync
rsync -avz docker-compose.minimal.yml Caddyfile.minimal .env.minimal install-minimal.sh README.minimal.md root@your-server:/root/n8n-installer/
```

### На сервере:

```bash
cd /root/n8n-installer
sudo bash install-minimal.sh
```

---

## Способ 3: Создать файлы прямо на сервере

Подключитесь к серверу по SSH и создайте файлы:

```bash
cd /root/n8n-installer

# Создайте docker-compose.minimal.yml
nano docker-compose.minimal.yml
# Вставьте содержимое и сохраните (Ctrl+O, Enter, Ctrl+X)

# Создайте Caddyfile.minimal
nano Caddyfile.minimal
# Вставьте содержимое и сохраните

# Создайте .env.minimal
nano .env.minimal
# Вставьте содержимое и сохраните

# Создайте install-minimal.sh
nano install-minimal.sh
# Вставьте содержимое и сохраните

# Создайте README.minimal.md
nano README.minimal.md
# Вставьте содержимое и сохраните

# Сделайте скрипт исполняемым
chmod +x install-minimal.sh

# Запустите установщик
sudo bash install-minimal.sh
```

---

## Что делает установщик:

1. **Проверяет требования**: Docker, Docker Compose
2. **Генерирует секреты**: Все пароли, ключи, токены
3. **Запрашивает данные**:
   - Домены для каждого сервиса
   - Cloudflare Tunnel Token
   - Логины и пароли
4. **Скачивает Supabase файлы** автоматически
5. **Создаёт .env** с конфигурацией
6. **Запускает все сервисы**
7. **Показывает credentials**

---

## После установки:

Сервисы будут доступны по вашим доменам:

- **n8n**: https://n8n.yourdomain.com
- **Langfuse**: https://langfuse.yourdomain.com
- **Qdrant**: https://qdrant.yourdomain.com
- **SearXNG**: https://search.yourdomain.com
- **Supabase**: https://supabase.yourdomain.com

---

## Troubleshooting

### Если скрипт не запускается:

```bash
# Проверьте права
ls -la install-minimal.sh

# Должно быть: -rwxr-xr-x
# Если нет, выполните:
chmod +x install-minimal.sh

# Проверьте окончания строк (если копировали из Windows)
dos2unix install-minimal.sh  # или
sed -i 's/\r$//' install-minimal.sh
```

### Если Docker не установлен:

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Просмотр логов:

```bash
# Все сервисы
docker compose -f docker-compose.minimal.yml logs -f

# Конкретный сервис
docker compose -f docker-compose.minimal.yml logs -f n8n
```

---

## Важно:

- Сохраните все credentials из вывода установщика!
- Файл `.env` содержит все секреты - сделайте backup
- Используйте команду `docker compose -f docker-compose.minimal.yml` для управления

---

## Поддержка:

Если возникли проблемы:
1. Проверьте логи контейнеров
2. Проверьте что Cloudflare Tunnel работает: `docker logs cloudflared`
3. Проверьте статус: `docker compose -f docker-compose.minimal.yml ps`
4. Создайте Issue на GitHub с логами
