# Nokroner Database

This is the backend of Nokroner, a personal finance management platform. 

## Run locally

The Nokroner backend is configured using Docker and Docker Compose. To run locally, simply create an `.env` file (see [.env.example](.env.example)) and then run the following command

```sh
$ docker compose up -d
```

Navigate to `localhost:3000` to access the API, or to `localhost:8080` to access the admin panel. Additionally, the PostgreSQL server will be running on port `5432`.

## Notice

This is a hobby project, you should probably not actually put sensitive financial information into this. Do so at your own risk.
