Introduction
============

This Loris build is intended for Ubuntu 12.0, IIP 0.9.9 (https://github.com/ruven/iipsrv) and Kakadu 7.4. These versions can be changed, see ```development.cfg```, ```development_docker.cfg``` and ```Dockerfile```. 

General
-------

**Core application source** is held in ```/home/bodl-loris-svc/sites/bodl-loris-svc/src```

**Eggs** are held in ```/home/bodl-loris-svc/.buildout/eggs```

**FCGI conf** is held in ```/home/bodl-loris-svc/sites/bodl-loris-svc/parts/apache/conf```

**Virtualenv Python** is held in ```/home/bodl-loris-svc/python```

**Caches and logs and images** are held in ```/home/bodl-loris-svc/sites/bodl-loris-svc/var``` (never cleared in event of buildout re-run)

**Components of application stack** (such as webserver) are held in ```/home/bodl-loris-svc/sites/bodl-loris-svc/parts```

**Apache start script** is held in ```/home/bodl-loris-svc/sites/bodl-loris-svc/bin```

Continuous Integration
----------------------

The Dockerfile will run the ```_docker.cfg``` version of development.cfg. This just ensures that users are named properly (the 'env' recipe does not work inside containers) and that the localhost is pointed to all IPs (as this cannot be dictated or predicted when creating a container).

Docker
https://registry.hub.docker.com/u/bdlss/buildout.iip/

If any of the 21 IIIF validation tests fail, Docker will exit with a non-zero result. This means the Docker build will fail and read "Error".

More about IIIF validation can be found here: http://iiif-test.stanford.edu/

Functional and Unit Testing
---------------------------

Pytest is executed in the docker run.

This runs all test scripts using the filename format of ``test_<something>.py`` in the ``tests/`` folder.

IIIF Validation
---------------

This is done automatically in the docker CI. However, you can do this manually via the website:

http://iiif-test.stanford.edu/

Or you can download the validator and run it on your server (once you have started the application), as follows:

```bash
cd /home/bodl-iip-svc/sites/bodl-iip-svc/parts 
wget --no-check-certificate https://pypi.python.org/packages/source/i/iiif-validator/iiif-validator-0.9.1.tar.gz
tar zxfv iiif-validator-0.9.1.tar.gz
su - <sudo user>
sudo apt-get -y install libmagic-dev libxml2-dev libxslt-dev
su - bodl-iip-svc
cd /home/bodl-iip-svc/sites/bodl-iip-svc 
. bin/activate 
pip install bottle 
pip install python-magic 
pip install lxml 
pip install Pillow
cd /home/bodl-iip-svc/sites/bodl-iip-svc/parts/iiif-validator-0.9.1/ 
./iiif-validate.py -s 127.0.0.1:8080 -p "fcgi-bin/iipsrv.fcgi?iiif=" -i /home/bodl-iip-svc/sites/bodl-iip-svc/var/images/67352ccc-d1b0-11e1-89ae-279075081939.jp2 --version=2.0 -version
```

Installation
============

To deploy IIP on a server, follow these instructions. Whenever this GIT account is updated, Docker will run a test deployment at ```https://registry.hub.docker.com/u/bdlss/buildout.iip/```. Please see **Continuous Integration** section above for more details.

Create user "bodl-iip-svc"
--------------------------

```bash
sudo useradd bodl-iip-svc
sudo passwd bodl-iip-svc
sudo mkdir -p /home/bodl-iip-svc/.ssh
cd /home
sudo chown -R bodl-iip-svc:bodl-iip-svc bodl-iip-svc/
sudo chsh -s /bin/bash bodl-iip-svc
su - bodl-iip-svc
ssh-keygen -t rsa
```

Copy and paste your key into gitlab by choosing My Profile (the grey person graphic link in the top right hand corner) then Add Public Key.

```bash
cat ~/.ssh/id_rsa.pub
```

Install and configure Git (Ubuntu)
----------------------------------
```bash
su - <sudo user>
sudo apt-get install git
```
```bash
git config --global user.email "my@address.com"
git config --global user.name "name in quotes"
```

Checkout the buildout
---------------------
```bash
su - bodl-iip-svc
mkdir -p ~/sites/bodl-iip-svc
cd ~/sites/bodl-iip-svc
git clone https://github.com/BDLSS/buildout.iip.git ./
```

OpenJPEG Libraries
------------------

For PIL/Pillow to run with JPEG2000 capability we need to install the OpenJpeg libraries before python-imaging.

http://shortrecipes.blogspot.co.uk/2014/06/python-34-and-pillow-24-with-jpeg2000.html

```bash
su - <sudo user>
sudo apt-get install -y -q wget cmake make
su - bodl-loris-svc
mkdir -p /home/bodl-loris-svc/Downloads 
cd /home/bodl-loris-svc/Downloads 
wget http://downloads.sourceforge.net/project/openjpeg.mirror/2.0.1/openjpeg-2.0.1.tar.gz 
tar xzvf openjpeg-2.0.1.tar.gz 
cd openjpeg-2.0.1/ 
cmake . 
make 
su - <sudo user>
sudo make install
```

Setup server 
------------

```bash
su - <sudo user>
sudo apt-get install $(cat /home/bodl-iip-svc/sites/bodl-iip-svc/ubuntu_requirements)
su - bodl-iip-svc
```

Install Python
--------------
```bash
su - bodl-iip-svc
cd ~/Downloads
wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --no-check-certificate
tar zxfv Python-2.7.6.tgz
cd Python-2.7.6
./configure --prefix=$HOME/python/2.7.6 --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath=/home/bodl-iip-svc/python/2.7.6/lib"
make
make install
cd ..
wget https://pypi.python.org/packages/source/d/distribute/distribute-0.6.49.tar.gz
tar zxfv distribute-0.6.49.tar.gz
~/python/2.7.6/bin/python distribute-0.6.49/distribute_setup.py
~/python/2.7.6/bin/easy_install pip
~/python/2.7.6/bin/pip install virtualenv
```

Setup the buildout cache
------------------------
```bash
mkdir ~/.buildout
cd ~/.buildout
mkdir eggs
mkdir downloads
mkdir extends
echo "[buildout]
eggs-directory = /home/bodl-iip-svc/.buildout/eggs
download-cache = /home/bodl-iip-svc/.buildout/downloads
extends-cache = /home/bodl-iip-svc/.buildout/extends" >> ~/.buildout/default.cfg
```
Change the IP address for apache config
---------------------------------------

edit development or production.cfg:

```bash

[hosts]
internalIP = <your server internal IP address>
externalIP = <your server external IP address>
```

Create a virtualenv and run the buildout
----------------------------------------

Add _docker to development.cfg if running in docker environment (or remove [...] from code below).

```bash
cd ~/sites/bodl-iip-svc
~/python/2.7.6/bin/virtualenv .
. bin/activate
pip install zc.buildout
pip install distribute
buildout init
buildout -c development.cfg
```

Upload Kakadu source to server for compilation
----------------------------------------------

You can retrieve the source from databank (you will need a user account for databank):

```bash
cd ~/Downloads
curl --user <username>:<password> -o Kakadu_v72.zip https://databank.ora.ox.ac.uk/dmt/datasets/Kakadu/Kakadu_v72.zip 
unzip -d kakadu Kakadu_v72.zip
```

Otherwise you will need to ```scp```, ```wget``` or ```curl``` your licensed Kakadu source into the ```~/Downloads``` directory as a folder called 'kakadu'.

Add the following to ```~/Downloads/kakadu/managed/make/Makefile-Linux-x86-64-gcc``` (in place of the non-specific java include directives there)

```bash
INCLUDES += -I/usr/lib/jvm/java-7-openjdk-amd64/include       # or wherever the Java
INCLUDES += -I/usr/lib/jvm/java-7-openjdk-amd64/include/linux # includes are on your system
```

Or

```bash
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
```

Add the following at the end of ~/Downloads/kakadu/apps/make/Makefile-Linux-x86-64-gcc:

```bash
DEFINES += -DKDU_NO_SSSE3
```

You can do this by typing the following in the command line:

```bash
echo 'DEFINES += -DKDU_NO_SSSE3' >> /home/bodl-iip-svc/Downloads/kakadu/apps/make/Makefile-Linux-x86-64-gcc
```

And compile...

```bash
cd ~/Downloads/kakadu/make
make -f Makefile-Linux-x86-64-gcc
```

If there are no errors, compile the IIP server.

Compile IIP server
-----------------

Make sure there is no trailing slash in the --with-kakadu param value; also, that it is an absolute path.

```bash
cd ~/sites/bodl-iip-svc/src/iipsrv
./autogen.sh
./configure --with-kakadu=/home/bodl-iip-svc/Downloads/kakadu
make 
```

The ```./configure`` result should read as follows:

```bash
Options Enabled:
---------------
 Memcached: 			true
 JPEG2000 (Kakadu):		true
 PNG Output:			false
 LitleCMS:	
 ```
 
 Then ```make``` it.

Test images
-----------

```bash
mkdir -p /home/bodl-iip-svc/sites/bodl-iip-svc/var/images
```

Copy your ```.tif``` and ```.jp2``` images into this directory. 

e.g. 

```bash
cd /home/bodl-iip-svc/sites/bodl-iip-svc/var/images
wget http://iiif-test.stanford.edu/67352ccc-d1b0-11e1-89ae-279075081939.jp2
wget http://merovingio.c2rmf.cnrs.fr/iipimage/PalaisDuLouvre.tif
```

Check their permissions or the viewer may hang!

Amend MooViewer image path
--------------------------

```bash
vi /home/bodl-iip-svc/sites/bodl-iip-svc/src/www/index.html
```

Amend the parameter as follows:

```bash
var image = /home/bodl-iip-svc/sites/bodl-iip-svc/var/images/<image name>
```

e.g.

```bash
var image = /home/bodl-iip-svc/sites/bodl-iip-svc/var/images/PalaisDuLouvre.tif
```

Start Apache
------------

```bash
su - <sudo user>
sudo chmod +x /home/bodl-iip-svc/sites/bodl-iip-svc/bin/iipctl
sudo /home/bodl-iip-svc/sites/bodl-iip-svc/bin/iipctl start
```

Browse to http://&lt;your server&gt;:8080/index.html

The IIP image server is located at (You should receive a welcome screen at this URL):

http://&lt;your server&gt;:8080/fcgi-bin/iipsrv.fcgi

If there is something wrong, check the logs at ```/home/bodl-iip-svc/sites/bodl-iip-svc/parts/iipsrv/logs/error.log```

Setup the reboot script in the sudo crontab
-------------------------------------------

```bash
su - <sudo user>
sudo crontab /home/bodl-iip-svc/sites/bodl-iip-svc/bin/cron.txt
su - bodl-iip-svc
```

Startup scripts and cron jobs
-----------------------------

The following script can be run manually. 

```bash
su - <sudo user>
/home/bodl-iip-svc/sites/bodl-iip-svc/bin/iipctl [start|stop|restart]
```

It will stop/start/restart iip. It runs under a @reboot directive in the sudo crontab to ensure the service comes back up in the event of a server shutdown/restart. It logs progress in ```var/log/reboot.log```.

```bash
@reboot /home/bodl-iip-svc/sites/bodl-iip-svc/bin/iipctl start > /home/bodl-iip-svc/sites/bodl-iip-svc/var/log/reboot.log 2>&1
```

