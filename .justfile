alias dev := development
alias d := down

development:
    docker compose -f docker-compose.dev.yml watch

up:
    docker compose up -d

down:
    docker compose down && docker compose -f docker-compose.dev.yml down

restart:
    docker compose restart