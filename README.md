## Oracletool in docker container

This is just a repo containing some very simple `Dockerfile` and `apache2.conf` file for running [Oracletool](http://www.oracletool.com) in a Docker container.

### How to build
You need an Oracle instant client to build this (and a docker installation of course). I think
shearing the instant client is not encouraged by Oracle, so you have to [download](https://www.oracle.com/database/technologies/instant-client/downloads.html) these yourself.
You need both the basic lite instance client and the SDK. In the `Dockerfile` here, I have used these: 

    instantclient-basiclite-linux.x64-12.2.0.1.0.zip
    instantclient-sdk-linux.x64-12.2.0.1.0.zip

Place these in the same directory as you are running `docker build` and it should all be fine.

You also need files that handles the Oracle database connection, the files that typically are found in your `TNS_ADMIN` directory. I have these files:

    ldap.ora
    sqlnet.ora
    tnsnames.ora

I'm not providing these files in this repo, as they are pretty much different for every Oracle installation. The build proses will copy all files matching `*.ora` into the image's `TNS_ADMIN` directory.

When this is done, you can build your image with:

    docker build -t oracletool .

Or if you have a proxy you need to pass in the `build_arg`:

    docker build -t oracletool .

If then everything builds successfully, you should be able to run the container:

    docker run -d -p 8000:80 oracletool

You can then visit the URL:

    http://localhost:8000

That should take you to the oracletool application. Good luck!

