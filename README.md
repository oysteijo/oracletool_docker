## Oracletool in docker container

This is just a repo containing some very simple `Dockerfile` and `apache2.conf` file for running [Oracletool](http://www.oracletool.com) in a Docker container.

### How to build
You need a docker installation of course. The docker build process will get everything you need except the oracle configuration files which are
normally found in `TNS_ADMIN` directory. That means you need the files that handles the Oracle database connection, the files that typically are
found in your `TNS_ADMIN` directory. I have these files:

    ldap.ora
    sqlnet.ora
    tnsnames.ora

I'm not providing these files in this repo, as they are pretty much different for every Oracle installation. The build proses will copy all files matching `*.ora` into the image's `TNS_ADMIN` directory.

**Everything else, like Oracle client, Perl modules (DBD::Oracle etc), web server and web server configuration, is taken care of automatically.**

When the `.ora` files are in the same directory, you can build your image with:

    docker build -t oracletool .

Or if you have a proxy you need to pass in the `build_arg`:

    docker build \
        --build-arg http_proxy=http://proxy.mydomain.com:80 \
        --build-arg http_proxys=http://proxy.mydomain.com:80 \
        -t oracletool .

If then everything builds successfully, you should be able to run the container:

    docker run -d -p 8000:80 oracletool

You can then visit the URL:

    http://localhost:8000

That should take you to the oracletool application. Good luck!

