# Docker version 1.2.0, build fa7b24f
 
# -------------------------------------------------------------------------
# --------------------------- STIPULATE OS --------------------------------
# -------------------------------------------------------------------------

FROM ubuntu:12.04 

# -------------------------------------------------------------------------
# --------------------------- UPDATE OS -----------------------------------
# -------------------------------------------------------------------------

RUN (apt-get update && apt-get upgrade -y -q && apt-get dist-upgrade -y -q && apt-get -y -q autoclean && apt-get -y -q autoremove)

# -------------------------------------------------------------------------
# ------------------------- CREATE APP USER/DIR ---------------------------
# -------------------------------------------------------------------------

RUN (adduser --disabled-password --gecos '' bodl-iip-srv && adduser bodl-iip-srv sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && su - bodl-iip-srv && mkdir -p sites/bodl-iip-srv)

# -------------------------------------------------------------------------
# --------------------------- COPY SOURCE INTO CONTAINER ------------------
# -------------------------------------------------------------------------

COPY / /home/bodl-iip-srv/sites/bodl-iip-srv/
RUN chown -R bodl-iip-srv:bodl-iip-srv /home/bodl-iip-srv
USER bodl-iip-srv

# -------------------------------------------------------------------------
# --------------------------- INSTALL REQS --------------------------------
# -------------------------------------------------------------------------

RUN apt-get -y install $(cat /home/bodl-iip-srv/sites/bodl-iip-srv/ubuntu_requirements12)
RUN mkdir -p /home/bodl-iip-srv/Downloads

# -------------------------------------------------------------------------
# --------------------------- INSTALL PYTHON ------------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-srv/Downloads && wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --no-check-certificate && tar zxfv Python-2.7.6.tgz && cd /home/bodl-iip-srv/Downloads/Python-2.7.6)
RUN /home/bodl-iip-srv/Downloads/Python-2.7.6/configure --prefix=/home/bodl-iip-srv/python/2.7.6 --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath=/home/bodl-iip-srv/python/2.7.6/lib"
RUN make
RUN make install

# -------------------------------------------------------------------------
# --------------------------- BUILDOUT SETUP ------------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-srv/Downloads && wget --no-check-certificate https://pypi.python.org/packages/source/d/distribute/distribute-0.6.49.tar.gz && tar zxfv distribute-0.6.49.tar.gz) 
RUN /home/bodl-iip-srv/python/2.7.6/bin/python /home/bodl-iip-srv/Downloads/distribute-0.6.49/distribute_setup.py
RUN /home/bodl-iip-srv/python/2.7.6/bin/easy_install pip
RUN /home/bodl-iip-srv/python/2.7.6/bin/pip install virtualenv

# -------------------------------------------------------------------------
# --------------------------- RUN BUILDOUT AND INSTALL EGGS ---------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-srv/sites/bodl-iip-srv && /home/bodl-iip-srv/python/2.7.6/bin/virtualenv . && . bin/activate && pip install zc.buildout && pip install distribute && buildout init && buildout -c development_docker.cfg && pip install pytest==2.6.2)

# -------------------------------------------------------------------------
# ------------------  INSTALL & COMPILE KAKADU  ---------------------------
# -------------------------------------------------------------------------

RUN (export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64' && cd /home/bodl-iip-srv/Downloads && curl --user admn2410:PaulB0wl3s -o Kakadu_v74.zip https://databank.ora.ox.ac.uk/dmt/datasets/Kakadu/Kakadu_v74.zip && unzip -d kakadu Kakadu_v74.zip && echo 'DEFINES += -DKDU_NO_SSSE3' >> /home/bodl-iip-srv/Downloads/kakadu/apps/make/Makefile-Linux-x86-64-gcc && cd /home/bodl-iip-srv/Downloads/kakadu/make && make -f Makefile-Linux-x86-64-gcc)

# -------------------------------------------------------------------------
# ---------------------- INSTALL & COMPILE IIP ----------------------------
# -------------------------------------------------------------------------

#RUN (cd /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/build && dpkg -i iipimage-0.9.9-jp2_amd64.deb)

#RUN (mkdir -p /home/bodl-iip-srv/sites/bodl-iip-srv/src/iipsrv && cd /home/bodl-iip-srv/sites/bodl-iip-srv/src/iipsrv && git clone https://github.com/ruven/iipsrv.git)
#RUN cp /usr/lib/cgi-bin/iipsrv.fcgi /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/fcgi-bin/iipsrv.fcgi
RUN (cd /home/bodl-iip-srv/sites/bodl-iip-srv/src/iipsrv && ./autogen.sh && ./configure --with-kakadu=/home/bodl-iip-srv/Downloads/kakadu && make)

# -------------------------------------------------------------------------
# --------------------------- GET TEST IMAGE ------------------------------
# -------------------------------------------------------------------------

RUN (mkdir -p /home/bodl-iip-srv/sites/bodl-iip-srv/var/images && cd /home/bodl-iip-srv/sites/bodl-iip-srv/var/images && wget http://merovingio.c2rmf.cnrs.fr/iipimage/PalaisDuLouvre.tif && wget http://iiif-test.stanford.edu/67352ccc-d1b0-11e1-89ae-279075081939.jp2 && chmod 777 67352ccc-d1b0-11e1-89ae-279075081939.jp2 && chmod 777 PalaisDuLouvre.tif)

# -------------------------------------------------------------------------
# --------------------------- RUN TEST FRAMEWORK --------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-srv/sites/bodl-iip-srv/ && . bin/activate && py.test /home/bodl-iip-srv/sites/bodl-iip-srv/tests/)

# -------------------------------------------------------------------------
# ---------------------------  INSTALL VALIDATOR --------------------------
# -------------------------------------------------------------------------

RUN (mkdir -p /home/bodl-iip-srv/sites/bodl-iip-srv/parts/validator && cd /home/bodl-iip-srv/sites/bodl-iip-srv/parts && wget --no-check-certificate https://pypi.python.org/packages/source/i/iiif-validator/iiif-validator-0.9.1.tar.gz && tar zxfv iiif-validator-0.9.1.tar.gz)
RUN (apt-get -y install libmagic-dev libxml2-dev libxslt-dev && cd /home/bodl-iip-srv/sites/bodl-iip-srv && . bin/activate && pip install bottle && pip install python-magic && pip install lxml && pip install Pillow)

# -------------------------------------------------------------------------
# -------------------  START SERVER, RUN VALIDATOR   ----------------------
# -------------------------------------------------------------------------

#validator needs to run in same intermediate container as the apache start

WORKDIR /home/bodl-iip-srv/sites/bodl-iip-srv
EXPOSE 8080
RUN (chown -R www-data:www-data /home/bodl-iip-srv/sites/bodl-iip-srv/src && cd /home/bodl-iip-srv/sites/bodl-iip-srv/bin/ && chmod +x iipctl && sleep 2 && ./iipctl start && cd /home/bodl-iip-srv/sites/bodl-iip-srv/ && . bin/activate && cd /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iiif-validator-0.9.1/ && ./iiif-validate.py -s 127.0.0.1:8080 -p "iipsrv.fcgi?iiif=" -i /home/bodl-iip-srv/sites/bodl-iip-srv/var/images/67352ccc-d1b0-11e1-89ae-279075081939.jp2 --version=2.0 -v)


