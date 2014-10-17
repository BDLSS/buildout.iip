# Docker version 1.2.0, build fa7b24f
 
# -------------------------------------------------------------------------
# --------------------------- STIPULATE OS --------------------------------
# -------------------------------------------------------------------------

FROM ubuntu:12.04

# -------------------------------------------------------------------------
# --------------------------- UPDATE OS -----------------------------------
# -------------------------------------------------------------------------

RUN (sudo apt-get update && sudo apt-get upgrade -y -q)

# -------------------------------------------------------------------------
# --------------------------- CREATE APP DIR ------------------------------
# -------------------------------------------------------------------------

RUN mkdir -p /root/sites/testbuild

# -------------------------------------------------------------------------
# --------------------------- COPY SOURCE INTO CONTAINER ------------------
# -------------------------------------------------------------------------

COPY / /root/sites/testbuild/

# -------------------------------------------------------------------------
# --------------------------- INSTALL REQS --------------------------------
# -------------------------------------------------------------------------

RUN apt-get -y install $(cat /root/sites/testbuild/ubuntu_requirements12)
RUN mkdir -p /root/Downloads

# -------------------------------------------------------------------------
# --------------------------- INSTALL PYTHON ------------------------------
# -------------------------------------------------------------------------

RUN (cd /root/Downloads && wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --no-check-certificate && tar zxfv Python-2.7.6.tgz && cd /root/Downloads/Python-2.7.6)
RUN /root/Downloads/Python-2.7.6/configure --prefix=/root/python/2.7.6 --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath=/root/python/2.7.6/lib"
RUN make
RUN make install

# -------------------------------------------------------------------------
# --------------------------- BUILDOUT SETUP ------------------------------
# -------------------------------------------------------------------------

RUN (cd /root/Downloads && wget https://pypi.python.org/packages/source/d/distribute/distribute-0.6.49.tar.gz && tar zxfv distribute-0.6.49.tar.gz) 
RUN /root/python/2.7.6/bin/python /root/Downloads/distribute-0.6.49/distribute_setup.py
RUN /root/python/2.7.6/bin/easy_install pip
RUN /root/python/2.7.6/bin/pip install virtualenv

# -------------------------------------------------------------------------
# --------------------------- RUN BUILDOUT AND INSTALL EGGS ---------------
# -------------------------------------------------------------------------

RUN (cd /root/sites/testbuild && /root/python/2.7.6/bin/virtualenv . && . bin/activate && pip install zc.buildout && pip install distribute && buildout init && buildout -c development_docker.cfg && pip install pytest==2.6.2)

# -------------------------------------------------------------------------
# --------------------------- INSTALL IIP -------------------------------
# -------------------------------------------------------------------------

RUN (cd /root/sites/testbuild/parts/iipsrv/build && sudo dpkg -i iipimage-0.9.9-jp2_amd64.deb)
RUN cp /usr/lib/cgi-bin/iipsrv.fcgi /root/sites/testbuild/parts/iipsrv/fcgi-bin/iipsrv.fcgi

# -------------------------------------------------------------------------
# --------------------------- GET TEST IMAGE ------------------------------
# -------------------------------------------------------------------------

RUN (mkdir -p /root/sites/testbuild/var/images && cd /home/bodl-iip-srv/sites/bodl-iip-srv/var/images && wget http://merovingio.c2rmf.cnrs.fr/iipimage/PalaisDuLouvre.tif)

# -------------------------------------------------------------------------
# --------------------------- RUN TEST FRAMEWORK --------------------------
# -------------------------------------------------------------------------

RUN (cd /root/sites/testbuild/ && . bin/activate && py.test /root/sites/testbuild/tests/)
#EXPOSE 8080
#CMD["loris", "/"]

