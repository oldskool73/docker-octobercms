# Docker + October CMS

The docker images defined in this repository serve as a starting point for [October CMS](https://octobercms.com) projects.

Based on [official docker PHP images](https://hub.docker.com/_/php), images include dependencies required by October, Composer and install the [latest release](https://octobercms.com/changelog).

## Quick Start

There are 3 ways to run this container...

### [Install Wizard](http://octobercms.com/docs/setup/installation#wizard-installation)

The simplest way to test October CMS using Docker is to start a container using the latest image, mapping a local port to the container's port 80:

```shell
$ docker run -d -p80:80 --name october oldskool73/octobercms:latest
```

Alternatively using docker-compose:

```
version: '2'
services:
    october:
        image: "oldskool73/octobercms"
        ports:
            - "80:80"
```

You can then visit `http://localhost:ip/install.php` and run through the wizard. The image has a local sqlite db ready to use so can just select that for the database option (or use an external db service), set an admin password and you should up and running.

Pros:

* Very easy way to test out October CMS in seconds!

Cons:

* Your data will not be persisted - as soon as you shut down the container your site and any changes you make will be gone (see 'Persisting your data' below).
* You need to run through the install wizard to set up October CMS, so you can't use this for automated/scalable installs (although you could conceivibly create a new container with your changes after running the installer and deploy that).


### [CLI Install](http://octobercms.com/docs/console/commands#console-install)

This image also allows for a CLI install. The CLI install runs `php artisan october:env` to place common settings into the environment, so you can overwrite them from the Docker environment.

```shell
$ docker run -d --name october -e "INSTALL_TYPE=cli" -e "DB_CONNECTION=sqlite" -e "DB_DATABASE=storage/database.sqlite" -p80:80 oldskool73/octobercms:latest
```

Alternatively using docker-compose:

```
version: '2'
services:
    october:
        image: "oldskool73/octobercms"
        ports:
            - "80:80"
        environment:
            - OCTOBER_INSTALL_TYPE=cli
            - DB_CONNECTION=sqlite
            - DB_DATABASE=storage/database.sqlite
```

Pros :

* Exports important variables to `.env` file and reads from file or environment, making overwriting from docker simple.
* Uses a consistent (bundled) version of October CMS, instead of the 'latest' as downloaded by the installer.
* Management by composer may give you more control.

Cons :

* More complex to set up than the `wizard` install. (see `Seeding the database` and `Seeding an admin user` below)

### No Install

If you already have an October CMS project ready to go, and just want to use this container to host it, you can use the 'none' install type and simply map in your code volume. Thus the container is basically just an empty Apache/PHP server with the correct setup to run your October CMS project. See also the 'Connecting to other containers' section below and edit your projects config/env accordingly.

Also, once you have set up the `wizard` or `cli` versions, you should probably change to using the `none` version also to avoid the slight delay copying files at startup, and prevent any of your files being replaced or overwritten by accident.

```shell
$ docker run -d --name october -e "OCTOBER_INSTALL_TYPE=none" -p80:80 -v `pwd`/october:/var/www/html --name october oldskool73/octobercms:latest
```

```
version: '2'
services:
    october:
        image: "oldskool73/octobercms"
        ports:
            - "80:80"
        volumes:
            - ./october:/var/www/html
        environment:
            - OCTOBER_INSTALL_TYPE=none
```

---

## Further Details

### Persisting your data

To persist your data, map a local folder to the `var/www/html` volume on the container.

```shell
$ docker run -d --name october -p80:80 -v `pwd`/october:/var/www/html oldskool73/octobercms:latest
```

```
version: '2'
services:
    october:
        image: "oldskool73/octobercms"
        ports:
            - "80:80"
        volumes:
            - ./october:/var/www/html
        environment:
            - OCTOBER_INSTALL_TYPE=cli
            - DB_CONNECTION=sqlite
            - DB_DATABASE=storage/database.sqlite
```

### Connecting to other services

To connect to other services you should probably use the CLI Install method, and set the services using environment variables.

```
version: '2'
services:
    october:
        image: "oldskool73/octobercms"
        ports:
            - "80"
        volumes:
            - ./october:/var/www/html
        environment:
            - OCTOBER_INSTALL_TYPE=cli
            - APP_DEBUG=true
            - APP_URL=http://localhost
            - DB_CONNECTION=mysql
            - DB_HOST=mysql
            - DB_DATABASE=october
            - DB_PORT=3306
            - DB_USERNAME=root
            - DB_PASSWORD=password
            - REDIS_HOST=redis
            - REDIS_PASSWORD=null
            - REDIS_PORT=6379
            - CACHE_DRIVER=redis
            - SESSION_DRIVER=redis
            - QUEUE_DRIVER=redis
        depends_on:
            - mysql
            - redis
    mysql:
        image: "mariadb"
        environment:
            - MYSQL_ROOT_PASSWORD=password
            - MYSQL_DATABASE=october
        ports:
            - "3306"
    redis:
        image: "redis"

```

Alternatively if you want to use the 'wizard' method, you could manually input the name/password etc of the 'mysql' container in the setup steps.

### Running container commands

```shell
$ docker-compose exec october bash -c "composer require predis/predis"
```

### Seeding the database

The `wizard` will seed your database for you. When you use the `cli` install you must do this manually, e.g...

```shell
$ docker-compose exec october bash -c "php artisan october:up"
```


### Seeding an Admin User

The `wizard` will create an admin user for you. When you use the `cli` install you must do this manually, e.g...

```shell
$ docker-compose exec october bash -c "php artisan tinker"
$u = new Backend\Database\Seeds\SeedSetupAdmin(); $u->run(); \Backend\Models\User::first()->update(['is_superUser' => true]); exit;
```

---

