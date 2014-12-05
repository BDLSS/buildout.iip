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

RUN (adduser --disabled-password --gecos '' bodl-iip-svc && adduser bodl-iip-svc sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && su - bodl-iip-svc && mkdir -p sites/bodl-iip-svc)

# -------------------------------------------------------------------------
# --------------------------- COPY SOURCE INTO CONTAINER ------------------
# -------------------------------------------------------------------------

COPY / /home/bodl-iip-svc/sites/bodl-iip-svc/

# -------------------------------------------------------------------------
# --------------------------- INSTALL REQS --------------------------------
# -------------------------------------------------------------------------

RUN apt-get -y install $(cat /home/bodl-iip-svc/sites/bodl-iip-svc/ubuntu_requirements)
RUN mkdir -p /home/bodl-iip-svc/Downloads

# -------------------------------------------------------------------------
# --------------------------- INSTALL PYTHON ------------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-svc/Downloads && wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --no-check-certificate && tar zxfv Python-2.7.6.tgz && cd /home/bodl-iip-svc/Downloads/Python-2.7.6)
RUN /home/bodl-iip-svc/Downloads/Python-2.7.6/configure --prefix=/home/bodl-iip-svc/python/2.7.6 --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath=/home/bodl-iip-svc/python/2.7.6/lib"
RUN make
RUN make install

# -------------------------------------------------------------------------
# --------------------------- BUILDOUT SETUP ------------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-svc/Downloads && wget --no-check-certificate https://pypi.python.org/packages/source/d/distribute/distribute-0.6.49.tar.gz && tar zxfv distribute-0.6.49.tar.gz) 
RUN /home/bodl-iip-svc/python/2.7.6/bin/python /home/bodl-iip-svc/Downloads/distribute-0.6.49/distribute_setup.py
RUN /home/bodl-iip-svc/python/2.7.6/bin/easy_install pip
RUN /home/bodl-iip-svc/python/2.7.6/bin/pip install virtualenv

# -------------------------------------------------------------------------
# --------------------------- BUILDOUT CACHE ------------------------------
# -------------------------------------------------------------------------

RUN (mkdir /home/bodl-iip-svc/.buildout && cd /home/bodl-iip-svc/.buildout && mkdir eggs && mkdir downloads && mkdir extends && (echo "[buildout]" && echo "eggs-directory = /home/bodl-iip-svc/.buildout/eggs" && echo "download-cache = /home/bodl-iip-svc/.buildout/downloads" && echo "extends-cache = /home/bodl-iip-svc/.buildout/extends") >> /home/bodl-iip-svc/.buildout/default.cfg)

# -------------------------------------------------------------------------
# --------------------------- RUN BUILDOUT AND INSTALL EGGS ---------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-svc/sites/bodl-iip-svc && /home/bodl-iip-svc/python/2.7.6/bin/virtualenv . && . bin/activate && pip install zc.buildout && pip install distribute && buildout init && buildout -c development_docker.cfg && pip install pytest==2.6.2)

# -------------------------------------------------------------------------
# ------------------  INSTALL & COMPILE KAKADU  ---------------------------
# -------------------------------------------------------------------------

RUN (export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64' && cd /home/bodl-iip-svc/Downloads && curl --user admn2410:PaulB0wl3s -o Kakadu_v74.zip https://databank.ora.ox.ac.uk/dmt/datasets/Kakadu/Kakadu_v74.zip && unzip -d kakadu Kakadu_v74.zip && echo 'DEFINES += -DKDU_NO_SSSE3' >> /home/bodl-iip-svc/Downloads/kakadu/apps/make/Makefile-Linux-x86-64-gcc && cd /home/bodl-iip-svc/Downloads/kakadu/make && make -f Makefile-Linux-x86-64-gcc)

# -------------------------------------------------------------------------
# ---------------------- INSTALL & COMPILE IIP ----------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-svc/sites/bodl-iip-svc/src/iipsrv && ./autogen.sh && ./configure --with-kakadu=/home/bodl-iip-svc/Downloads/kakadu && make)

# -------------------------------------------------------------------------
# --------------------------- GET TEST IMAGE ------------------------------
# -------------------------------------------------------------------------

RUN (mkdir -p /home/bodl-iip-svc/sites/bodl-iip-svc/var/images && cd /home/bodl-iip-svc/sites/bodl-iip-svc/var/images && wget http://merovingio.c2rmf.cnrs.fr/iipimage/PalaisDuLouvre.tif && wget http://iiif-test.stanford.edu/67352ccc-d1b0-11e1-89ae-279075081939.jp2 && chmod 777 67352ccc-d1b0-11e1-89ae-279075081939.jp2 && chmod 777 PalaisDuLouvre.tif)

# -------------------------------------------------------------------------
# --------------------------- RUN TEST FRAMEWORK --------------------------
# -------------------------------------------------------------------------

RUN (cd /home/bodl-iip-svc/sites/bodl-iip-svc/ && . bin/activate && py.test /home/bodl-iip-svc/sites/bodl-iip-svc/tests/)

# -------------------------------------------------------------------------
# ---------------------------  INSTALL VALIDATOR --------------------------
# -------------------------------------------------------------------------

RUN (mkdir -p /home/bodl-iip-svc/sites/bodl-iip-svc/parts/validator && cd /home/bodl-iip-svc/sites/bodl-iip-svc/parts && wget --no-check-certificate https://pypi.python.org/packages/source/i/iiif-validator/iiif-validator-0.9.1.tar.gz && tar zxfv iiif-validator-0.9.1.tar.gz)
RUN (apt-get -y install libmagic-dev libxml2-dev libxslt-dev && cd /home/bodl-iip-svc/sites/bodl-iip-svc && . bin/activate && pip install bottle && pip install python-magic && pip install lxml && pip install Pillow)

# -------------------------------------------------------------------------
# -------------------  START SERVER, RUN VALIDATOR   ----------------------
# -------------------------------------------------------------------------

#validator needs to run in same intermediate container as the apache start

RUN chown -R bodl-iip-svc:bodl-iip-svc /home/bodl-iip-svc
WORKDIR /home/bodl-iip-svc/sites/bodl-iip-svc
EXPOSE 8080
RUN (cd /home/bodl-iip-svc/sites/bodl-iip-svc/bin/ && chmod +x iipctl && sleep 2 && ./iipctl start && cd /home/bodl-iip-svc/sites/bodl-iip-svc/ && . bin/activate && cd /home/bodl-iip-svc/sites/bodl-iip-svc/parts/iiif-validator-0.9.1/ && ./iiif-validate.py -s 127.0.0.1:8080 -p "fcgi-bin/iipsrv.fcgi?iiif=" -i /home/bodl-iip-svc/sites/bodl-iip-svc/var/images/67352ccc-d1b0-11e1-89ae-279075081939.jp2 --version=2.0 -v)


