alias w := watch
alias m := monitor
alias l := logs
alias u := up
alias d := down
alias r := restart
alias sh := shell
alias c := console
alias stat := status
alias mig := migrate
alias mu := migrate_undo
alias mr := migrate_redo

watch:
    docker compose -f docker-compose.dev.yml watch

logs:
    docker compose logs rails

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

console:
    docker compose exec rails ./bin/rails console

status:
    docker compose ls && docker compose ps

migrate:
    docker compose exec rails ./bin/rails db:migrate

migrate_undo:
    docker compose exec rails ./bin/rails db:migrate:undo

migrate_redo:
    docker compose exec rails ./bin/rails db:migrate:redo
