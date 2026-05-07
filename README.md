# Nokroner API

Backend of the Nokroner personal finance app. Written using [Ruby on
Rails](https://rubyonrails.org/)

## What is it?

Nokroner is a finance tracking app, made with the intention of making it
easy and convenient for anyone to keep track of their personal finance. The
goal is to provide in depth analysis of the spending habits of the user,
as well as making planning future spending and saving easy.

This is the backend for this app, developed separate from the front-end in
order to support multiple front-end solutions.

Nokroner aims to be as secure as possible, so that the possibility of the highly
sensitive financial information stored in its database being compromised is
as small as possible. The more information is encrypted however, the less
functionality can be supported. As such, a compromise between security and
functionality has to be made, and absolute confidenciality cannot be guaranteed.

This is ultimately a hobby project, intended for personal use.

## Getting started

In order to set up this repository, make sure
you have [Docker](https://www.docker.com/) and
[rails](https://guides.rubyonrails.org/install_ruby_on_rails.html)
installed. [just](https://github.com/casey/just) is also recommended for
easier CLI usage.

### Setup

#### Master key

Before Ruby on Rails will work, you will need the master key. If you already
have a master key, you can skip this step.

To generate a new master key, run the following command.

```sh
rails secret
```

#### Environment

This project expects certain environment variables to be set. These variables
are expected to be found in certain `.env` files. Example environment files
have been provided with the file ending `.env.example`.

When setting up the project, create copies of the `*.env.example` files without
the `.example` suffix, and fill inn the variables with appropriate values. Some
have defaults provided, but these are not suitable for production builds.

### Development

#### Running the development build

In order to run the development build, simply run

```sh
just watch
```

This will start docker containers for the development build and watch the
directory for changes to do live updates.

You can find the full command in the [justfile](.justfile) under the watch
section.

#### Entering the container

To enter the rails container and run commands directly on the running
server, run

```sh
just shell
```

#### Logs

To get the logs from the rails server, run

```sh
just monitor
```

As long as the container is running, this will show the output from the
server in real time.

#### Stopping the container

To stop the development build, run

```sh
just down
```

### Production

Most of the [development](#development) commands apply to the production
environment as well, except for the command to run the build.

To run the production build, run

```sh
just up
```

## License

See [LICENSE](LICENSE)
