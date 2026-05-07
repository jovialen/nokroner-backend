alias w := watch
alias m := monitor
alias u := up
alias d := down
alias r := restart
alias sh := shell
alias stat := status

watch:
    docker compose -f docker-compose.dev.yml watch

monitor:
    docker compose logs rails -f

up:
    docker compose up -d

down:
    docker compose down && docker compose -f docker-compose.dev.yml down

restart:
    docker compose restart

shell:
    docker compose exec rails bash

status:
    docker compose ls && docker compose ps
