# Minimal AI Stack

Простой установщик для 6 ключевых AI-сервисов без конфликтов.

## Сервисы

1. **n8n** - Автоматизация и AI-workflows
2. **Langfuse** - LLM observability и трекинг
3. **Qdrant** - Векторная база данных
4. **SearXNG** - Приватный поисковик
5. **Supabase** - Backend-as-a-Service (PostgreSQL, Auth, Storage, Realtime)
6. **Cloudflare Tunnel** - Безопасный доступ через HTTPS

## Быстрый старт

### 1. Требования

- Ubuntu 20.04+ / Debian 11+
- Docker 20.10+
- Docker Compose V2
- Root доступ
- Домен в Cloudflare

### 2. Подготовка Cloudflare Tunnel

1. Зайдите в [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Перейдите в **Networks → Tunnels**
3. Создайте новый туннель
4. В разделе **Public Hostname** добавьте:
   - **Subdomain**: `*` (wildcard для всех поддоменов)
   - **Domain**: `yourdomain.com`
   - **Type**: `HTTP`
   - **URL**: `caddy:80`
5. Скопируйте **Tunnel Token**

### 3. Установка

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/n8n-installer.git
cd n8n-installer

# Запустите установщик
sudo bash install-minimal.sh
```

Установщик запросит:
- Домены для каждого сервиса (например, `n8n.yourdomain.com`)
- Cloudflare Tunnel Token
- Логины и пароли для сервисов

### 4. Что происходит при установке

1. Генерируются безопасные ключи и пароли
2. Создаётся `.env` файл с конфигурацией
3. Скачиваются Docker образы
4. Запускаются все сервисы
5. Выводятся credentials для доступа

## Архитектура

```
Internet
   ↓
Cloudflare (SSL/TLS)
   ↓
Cloudflare Tunnel (cloudflared)
   ↓
Caddy (HTTP routing)
   ↓
┌──────────────────────────────────────┐
│ n8n          langfuse-web    qdrant │
│ searxng      supabase-*             │
│ postgres     redis                   │
└──────────────────────────────────────┘
```

### Основные принципы

- **Одна сеть**: Все контейнеры в сети `ai-stack`
- **HTTP внутри**: Между контейнерами только HTTP (без SSL)
- **SSL на Cloudflare**: HTTPS терминируется на Cloudflare
- **Host-based routing**: Caddy маршрутизирует по hostname

## Управление

### Просмотр логов

```bash
# Все сервисы
docker compose -f docker-compose.minimal.yml logs -f

# Конкретный сервис
docker compose -f docker-compose.minimal.yml logs -f n8n
docker compose -f docker-compose.minimal.yml logs -f langfuse-web
docker compose -f docker-compose.minimal.yml logs -f supabase-kong
```

### Перезапуск

```bash
# Все сервисы
docker compose -f docker-compose.minimal.yml restart

# Конкретный сервис
docker compose -f docker-compose.minimal.yml restart n8n
```

### Остановка

```bash
# Остановить (данные сохраняются)
docker compose -f docker-compose.minimal.yml down

# Остановить и удалить данные
docker compose -f docker-compose.minimal.yml down -v
```

### Обновление

```bash
# Обновить образы
docker compose -f docker-compose.minimal.yml pull

# Пересоздать контейнеры
docker compose -f docker-compose.minimal.yml up -d --force-recreate
```

## Доступ к сервисам

После установки сервисы доступны по вашим доменам:

### n8n
- URL: `https://n8n.yourdomain.com`
- При первом входе создайте admin аккаунт

### Langfuse
- URL: `https://langfuse.yourdomain.com`
- Email и пароль указали при установке
- API ключи в `.env`: `LANGFUSE_INIT_PROJECT_PUBLIC_KEY` и `LANGFUSE_INIT_PROJECT_SECRET_KEY`

### Qdrant
- URL: `https://qdrant.yourdomain.com`
- API Key в `.env`: `QDRANT_API_KEY`
- Используйте в запросах: `X-API-Key: your_key`

### SearXNG
- URL: `https://searxng.yourdomain.com`
- Username/Password указали при установке
- Basic Auth защита

### Supabase
- URL: `https://supabase.yourdomain.com`
- Dashboard: Username/Password указали при установке
- API Keys в `.env`:
  - `ANON_KEY` - для клиентских запросов
  - `SERVICE_ROLE_KEY` - для server-side запросов

## Интеграция с n8n

### Подключение к Qdrant

1. В n8n создайте Credentials → Qdrant
2. URL: `http://qdrant:6333`
3. API Key: из `.env` файла

### Подключение к Supabase

1. В n8n создайте Credentials → Supabase
2. Host: `http://supabase-kong:8000`
3. Service Role Secret: из `.env` (`SERVICE_ROLE_KEY`)

### Подключение к Langfuse

1. В n8n используйте HTTP Request node
2. URL: `http://langfuse-web:3000/api`
3. Authentication: API Key
4. Public Key: `LANGFUSE_INIT_PROJECT_PUBLIC_KEY`
5. Secret Key: `LANGFUSE_INIT_PROJECT_SECRET_KEY`

### Использование SearXNG

1. В n8n используйте HTTP Request node
2. URL: `http://searxng:8080/search`
3. Method: GET
4. Query Parameters: `q=your search query&format=json`

## Troubleshooting

### Проверка статуса контейнеров

```bash
docker compose -f docker-compose.minimal.yml ps
```

### Cloudflare Tunnel не работает

```bash
# Проверьте логи
docker logs cloudflared

# Должно быть: "Registered tunnel connection"
```

### n8n не доступен

```bash
# Проверьте логи n8n
docker logs n8n

# Проверьте postgres
docker logs postgres
```

### Supabase не запускается

```bash
# Проверьте все Supabase контейнеры
docker ps | grep supabase

# Проверьте логи базы данных
docker logs supabase-db

# Проверьте Kong
docker logs supabase-kong
```

### Сброс и переустановка

```bash
# Остановить и удалить всё
docker compose -f docker-compose.minimal.yml down -v

# Удалить .env
rm .env

# Переустановить
sudo bash install-minimal.sh
```

## Файлы конфигурации

- `docker-compose.minimal.yml` - Docker Compose конфигурация
- `Caddyfile.minimal` - Caddy reverse proxy конфигурация
- `.env.minimal` - Шаблон переменных окружения
- `install-minimal.sh` - Установочный скрипт

## Volumes (данные)

Все данные хранятся в Docker volumes:

```bash
# Список volumes
docker volume ls | grep ai-stack

# Backup volumes
docker run --rm -v caddy-data:/data -v $(pwd):/backup alpine tar czf /backup/caddy-backup.tar.gz -C /data .
```

## Порты

Внутренние порты контейнеров:
- n8n: 5678
- Langfuse: 3000
- Qdrant: 6333
- SearXNG: 8080
- Supabase Kong: 8000
- Postgres: 5432
- Redis: 6379
- Caddy: 80, 443

Только Caddy открывает порты на хосте (80, 443).
Cloudflared работает без открытых портов.

## Безопасность

- SSL сертификаты управляются Cloudflare
- Все сервисы за Cloudflare Tunnel (защита от DDoS)
- SearXNG защищён Basic Auth
- Supabase Dashboard защищён Basic Auth
- Все API ключи генерируются автоматически
- Row Level Security (RLS) включен в Supabase по умолчанию

## Дополнительно

### Создание Supabase таблиц

```sql
-- Пример создания таблицы в Supabase Studio
create table public.notes (
  id uuid default gen_random_uuid() primary key,
  content text,
  created_at timestamp with time zone default now()
);

-- Включить RLS
alter table public.notes enable row level security;

-- Создать policy
create policy "Users can read own notes"
  on public.notes for select
  using (auth.uid() = user_id);
```

### Использование Supabase Storage

Storage доступен через API:

```javascript
// В n8n или вашем приложении
const { createClient } = require('@supabase/supabase-js')

const supabase = createClient(
  'https://supabase.yourdomain.com',
  'your_anon_key'
)

// Upload файла
const { data, error } = await supabase.storage
  .from('bucket-name')
  .upload('file-path', file)
```

## Поддержка

- Создайте Issue на GitHub
- Проверьте логи контейнеров
- Изучите документацию каждого сервиса:
  - [n8n](https://docs.n8n.io/)
  - [Langfuse](https://langfuse.com/docs)
  - [Qdrant](https://qdrant.tech/documentation/)
  - [SearXNG](https://docs.searxng.org/)
  - [Supabase](https://supabase.com/docs)

## Лицензия

MIT License
