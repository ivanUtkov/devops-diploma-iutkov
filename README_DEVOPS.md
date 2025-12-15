# DevOps-обзор дипломного проекта

Подробное описание инфраструктуры, пайплайнов и приложения, собранных в этом репозитории. Сценарий: Terraform поднимает виртуалку в Yandex Cloud, Ansible готовит её и раскатывает docker-compose со всем стеком (приложение + мониторинг/логирование), GitHub Actions строит образ и при пуше в `main` деплоит последнюю версию.

## Карта репозитория
- `load-test-analizator/` — исходники приложения (FastAPI + Jinja + Chart.js), Dockerfile и локальный docker-compose.
- `infra/terraform/` — код IaC под Yandex Cloud: VM + security group, работа через сервисный аккаунт.
- `infra/ansible/` — плейбуки для установки Docker (`setup_docker.yml`) и выката стека (`deploy_app.yml`), шаблоны compose/prometheus/filebeat/env.
- `.github/workflows/ci.yml` и `.github/workflows/cd.yml` — CI (линт/тесты + push образа в GHCR) и CD (Ansible-деплой на VM).
- `README.md` — краткое описание; `readme_devops` — этот детальный гайд.

## Приложение: что внутри
- API: `app/main.py` поднимает FastAPI, эндпоинты `/upload-csv/`, `/services/`, `/stability/`, `/resources/`, `/upload-report-to-s3/`. Данные из CSV складываются в память (`crud.DATA_STORAGE`), далее используются в дашбордах (`dashboards.py`), схемы в `schemas.py`.
- UI: `app/templates/index.html` + `app/static/app.js` + Chart.js. Файл CSV загружается через форму, метрики и графики подтягиваются из API.
- Отчёт в S3: `app/s3_utils.py` шлёт отчёт в S3-совместимое хранилище по переменным `AWS_*`.
- Генератор данных: `csv_creator.py` создаёт синтетический CSV для демонстрации.
- Тесты и стиль: `tests/test_services.py` (проверка расчёта стабильности), `flake8` конфиг по умолчанию (`.flake8`), зависимости в `requirements.txt`.

## Docker и локальный запуск
- Образ: `load-test-analizator/Dockerfile` собирает Python 3.10 slim, устанавливает зависимости и стартует `uvicorn app.main:app --host 0.0.0.0 --port 8000`.
- Локальный compose: `load-test-analizator/docker-compose.yml` билдит локальный образ и стартует сервис `app` на `8000:8000`, переменные из `app/.env`.
- Ручной запуск без Docker:
  ```bash
  cd load-test-analizator
  python -m venv venv && source venv/bin/activate
  pip install -r requirements.txt
  uvicorn app.main:app --reload
  ```

## Terraform: создание ВМ
- Провайдер: Yandex Cloud (`provider "yandex"`), аутентификация сервисным аккаунтом через `sa-key.json`.
- Ресурсы:
  - `yandex_vpc_security_group`: открывает 22 (SSH), 80 (запас), 8000 (app), 3000 (Grafana), 5601 (Kibana), 9090 (Prometheus), исходящий трафик без ограничений.
  - `yandex_compute_instance.app`: VM `standard-v3`, 2 vCPU, 4 GB RAM, core_fraction 20%, диск 20 GB, зона по умолчанию `ru-central1-a`. Подключается к существующим `network_id` и `subnet_id`, прописывает SSH-ключ `vm_user`.
  - Output: `vm_external_ip` для дальнейших плейбуков.
- Входные переменные: `cloud_id`, `folder_id`, `zone`, `vm_user`, `ssh_public_key`, `network_id`, `subnet_id` (см. `variables.tf`). Значения кладутся в `terraform.tfvars`; пример с реальными ID в репозитории можно заменить на свои.
- Работа со стэком:
  ```bash
  cd infra/terraform
  terraform init
  terraform plan
  terraform apply
  ```
  Состояние хранится локально (`terraform.tfstate`), при командной работе лучше вынести в удалённый backend.

## Ansible: подготовка и деплой
- Инвентарь: `infra/ansible/inventory.ini` (есть пример `inventory.example.ini`). `ansible.cfg` настраивает путь к инвентарю и отключает проверку ключей.
- Плейбук `setup_docker.yml`:
  - Обновляет apt, ставит Docker Engine + docker-compose plugin.
  - Включает и стартует Docker, добавляет пользователя `ubuntu` в группу `docker`.
  - Создаёт каталог `/opt/diploma-app` под будущий стек.
- Плейбук `deploy_app.yml`:
  - Претаскивает мусор/логи, чистит Docker cache.
  - Настраивает `vm.max_map_count` (для OpenSearch).
  - Создаёт каталоги `/opt/diploma-app/{filebeat,grafana,prometheus}`.
  - Рендерит шаблоны:
    - `templates/docker-compose.yml.j2` — поднимает `app`, `grafana`, `node_exporter`, `prometheus`, `elasticsearch` (OpenSearch), `kibana`, `diploma-filebeat`; образ приложения берётся из GHCR `ghcr.io/ivanutkov/load-test-analizator:latest`.
    - `templates/prometheus.yml.j2` — скрейп Prometheus самого себя и node_exporter.
    - `templates/filebeat.yml.j2` — сбор логов контейнеров в OpenSearch индекс `filebeat-*`.
    - `templates/app.env.j2` — env-файл с `AWS_*` (для S3/OBS).
  - Выполняет `docker compose pull app` и `docker compose up -d`.
  - Перезапускает и проверяет logging stack: ждёт OpenSearch, включает совместимость для Beats, тестирует вывод filebeat и ждёт появления индекса.

## Логирование и мониторинг (после Ansible)
- `node_exporter` отдаёт системные метрики, Prometheus их скрейпит, Grafana доступна на 3000 для дашбордов.
- Логи контейнеров собирает Filebeat и шлёт в OpenSearch (порт 9200); Kibana (OpenSearch Dashboards) на 5601 для просмотра логов.
- Приложение доступно на 8000; при желании можно повесить обратный прокси на 80.

## CI: `.github/workflows/ci.yml`
- Триггер: любой `push`.
- Шаги: checkout → Python 3.10 → install deps (`load-test-analizator/requirements.txt` + `flake8` + `pytest`) → `flake8 .` → `pytest` → login GHCR → build/push `ghcr.io/ivanutkov/load-test-analizator:latest`.
- Требования: доступ к GHCR через `GITHUB_TOKEN` (дается автоматически в GitHub Actions).

## CD: `.github/workflows/cd.yml`
- Триггер: `push` в `main`.
- Шаги: checkout → Python 3.10 → установить Ansible → подложить SSH-ключ (`APP_VM_SSH_KEY`) и known_hosts по `APP_VM_HOST` → сгенерировать `infra/ansible/inventory.ini` и `ansible.cfg` → выполнить `ansible-playbook deploy_app.yml`.
- Требуемые secrets в репозитории: `APP_VM_SSH_KEY` (приватный ключ для `ubuntu` на ВМ), `APP_VM_HOST` (внешний IP из output Terraform).
- Предусловие: Docker уже установлен на ВМ (`setup_docker.yml` прогнан вручную или иным способом). В рантайме CD использует GHCR-образ, собранный CI.

## Переменные и секреты
- Приложение (`/opt/diploma-app/.env`): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET_NAME`, `AWS_REGION` (по умолчанию `ru-central1`, подходит для Yandex Object Storage). Шаблон — `infra/ansible/templates/app.env.j2`, пример — `load-test-analizator/app/.env.example`.
- Terraform: `sa-key.json` (ключ сервисного аккаунта), `terraform.tfvars` (cloud/folder/network/subnet/ssh key). Эти файлы приватные, по `.gitignore`.
- Ansible: `inventory.ini` с `ansible_host`, `ansible_user`, `ansible_ssh_private_key_file`.
- GitHub Actions: `APP_VM_SSH_KEY`, `APP_VM_HOST`; доступ к GHCR уже есть через встроенный `GITHUB_TOKEN`.

## Полный сценарий развёртывания
1) Подготовить `infra/terraform/terraform.tfvars` и `sa-key.json`; запустить `terraform init && terraform apply` и сохранить `vm_external_ip`.
2) Заполнить `infra/ansible/inventory.ini` (или использовать CD, где он генерируется из секретов), убедиться что SSH до ВМ доступен.
3) Однажды прогнать `ansible-playbook infra/ansible/setup_docker.yml` для установки Docker.
4) Настроить `AWS_*` в секретах/`app.env.j2`.
5) Пушить код: CI соберёт и запушит образ; пуш в `main` запустит CD и выкатит стэк на ВМ (compose + мониторинг/логирование).
6) Проверить доступ: приложение `http://<vm_ip>:8000`, Grafana `:3000`, Prometheus `:9090`, Kibana `:5601`, OpenSearch API `:9200`.

## Работа и тесты в разработке
- Линт и тесты локально:
  ```bash
  cd load-test-analizator
  pip install -r requirements.txt flake8 pytest
  flake8 .
  pytest
  ```
- Генерация демо-данных: `python csv_creator.py` (создаст `load_test_data.csv`).
- Загружайте CSV через UI или POST `/upload-csv/`; после загрузки обновятся списки сервисов и графики.

## Что менять под себя
- В Terraform — IDs сети/сабнета/облака, размеры ВМ, открытые порты по потребности; рекомендовано вынести state в remote backend.
- В Ansible — пути, версии образов и сервисов в `docker-compose.yml.j2`, доп. dashboards/targets в Prometheus, политики логирования Filebeat.
- В CI/CD — имя образа GHCR, список веток, дополнительные проверки или разделение окружений (staging/prod) по веткам и inventory.
