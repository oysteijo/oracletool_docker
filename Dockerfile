FROM ubuntu:latest

MAINTAINER oysteijo@gmail.com

ARG ORACLE_INSTALL_DIR=/opt/oracle
ARG TNS_ADMIN=${ORACLE_INSTALL_DIR}/tns

ARG ORACLE_HOME=${ORACLE_INSTALL_DIR}/instantclient_12_2
ARG INSTANTCLIENT_ZIP=instantclient-basiclite-linux.x64-12.2.0.1.0.zip
ARG INSTANTCLIENT_SDK_ZIP=instantclient-sdk-linux.x64-12.2.0.1.0.zip

# Install Base Packages
RUN apt-get update
RUN apt-get -y upgrade

# Install Apache, mod-perl, etc.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libapache2-mod-perl2 unzip make wget gcc libaio1 cpanminus libcgi-pm-perl
# Enable apache mods.
RUN a2enmod perl
RUN a2enmod rewrite

# install Oracle instantclient and SDK (SDK is needed to build perl connector DBD:Oracle)
#
# Note that the name of the directory contains the instantclient version (ie. 12_2), so you
# might have to change line 8 to reflect this if you are not using version 12.2
USER root
RUN mkdir -p ${ORACLE_INSTALL_DIR}
COPY ${INSTANTCLIENT_ZIP} /tmp/
COPY ${INSTANTCLIENT_SDK_ZIP} /tmp/
RUN unzip /tmp/${INSTANTCLIENT_ZIP} -d ${ORACLE_INSTALL_DIR}
RUN unzip /tmp/${INSTANTCLIENT_SDK_ZIP} -d ${ORACLE_INSTALL_DIR}

# Update the ld.so such that you won't need an LD_LIBRARY_PATH
RUN echo ${ORACLE_HOME} > /etc/ld.so.conf.d/oracle-instantclient.conf
RUN ldconfig

# Install oracletool
ARG DOCUMENT_ROOT=/var/www/html
ARG ORACLETOOL_VERSION=3.0.2
ARG ORACLETOOL_DIR=${DOCUMENT_ROOT}/oracletool
ARG ORACLETOOL_INI=${ORACLETOOL_DIR}/oracletool.ini

# Get, unpack and rename directory
RUN wget -qO- http://www.oracletool.com/download/oracletool-${ORACLETOOL_VERSION}.tgz | tar --transform "s/oracletool-${ORACLETOOL_VERSION}/oracletool/" -xvz -C ${DOCUMENT_ROOT} 

# Looks like oracletool isn't packed with the best file permissions
RUN chmod 755 ${ORACLETOOL_DIR}               \ 
              ${ORACLETOOL_DIR}/oracletool.pl \
              ${ORACLETOOL_DIR}/sql           \
              ${ORACLETOOL_DIR}/test          \
              ${ORACLETOOL_DIR}/test/*        \
              ${ORACLETOOL_DIR}/doc

RUN chmod 644 ${ORACLETOOL_DIR}/doc/* ${ORACLETOOL_DIR}/sql/*

# Set the right perl executable. Let's hope that is /usr/bin/perl.
RUN sed -i -E 's|(^#!).*|\1/usr/bin/perl|g' ${ORACLETOOL_DIR}/oracletool.pl

# Now generate a .ini file. Just rename .sam file and substitute TNS_ADMIN and ORACLE_HOME (and fontsize).
RUN mv ${ORACLETOOL_DIR}/oracletool.sam ${ORACLETOOL_INI} && chmod 644 ${ORACLETOOL_INI}
RUN sed -i -r "s|(ORACLE_HOME =).*|\1 ${ORACLE_HOME}|g ; s|(TNS_ADMIN =).*|\1 ${TNS_ADMIN}|g ; s|(\s*fontsize\s*=\s*)[0-9]*|\1 13|g" ${ORACLETOOL_INI}

# Install DBD::Oracle
ENV ORACLE_HOME ${ORACLE_HOME}
RUN cpanm DBD::Oracle

# Copy the TNS_ADMIN files from local.
RUN mkdir -p ${TNS_ADMIN}
COPY *.ora ${TNS_ADMIN}/

# And then we set up the httpd config.
COPY apache2_conf.template /etc/apache2/apache2.conf
RUN sed -i -e "s|XXX_ORACLETOOL_DIR_XXX|${ORACLETOOL_DIR}|g" /etc/apache2/apache2.conf

# This is details, but let's overwrite the default index.html, and redirect to the app.
COPY index.html ${DOCUMENT_ROOT}/
RUN sed -i -r "s/Oracletool/Oracletool v${ORACLETOOL_VERSION}/g" ${DOCUMENT_ROOT}/index.html

# Enable CGI sripting
RUN ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/

# And then we kick off the apache server process....
CMD apachectl -D FOREGROUND
