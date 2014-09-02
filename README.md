Installation (Ubuntu 12.04.4 LTS)
=================================

IIP is not yet compatible with Ubuntu 14.

Create user "bodl-iip-svc"
------------------

```bash
sudo useradd bodl-iip-srv
sudo passwd bodl-iip-srv
sudo mkdir -p /home/bodl-iip-srv/.ssh
cd /home
sudo chown -R bodl-iip-srv:bodl-iip-srv bodl-iip-srv/
sudo chsh -s /bin/bash bodl-iip-srv
su - bodl-iip-srv
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
su - bodl-iip-srv
mkdir -p ~/sites/bodl-iip-srv
cd ~/sites/bodl-iip-srv
git clone gitlab@source.bodleian.ox.ac.uk:calvin.butcher/buildout.iip.git ./
```
Setup server (Debian/Ubuntu)
----------------------------

```bash
su - <sudo user>
sudo apt-get install $(cat /home/bodl-iip-srv/sites/bodl-iip-srv/ubuntu_requirements)
su - bodl-iip-srv
```

Install Python
--------------
```bash
su - bodl-iip-srv
mkdir -p ~/Downloads
cd ~/Downloads
wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --no-check-certificate
tar zxfv Python-2.7.6.tgz
cd Python-2.7.6
./configure --prefix=$HOME/python/2.7.6 --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath=/home/bodl-iip-srv/python/2.7.6/lib"
make
make install
cd ..
wget http://python-distribute.org/distribute_setup.py
~/python/2.7.6/bin/python distribute_setup.py
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
eggs-directory = /home/bodl-iip-srv/.buildout/eggs
download-cache = /home/bodl-iip-srv/.buildout/downloads
extends-cache = /home/bodl-iip-srv/.buildout/extends" >> ~/.buildout/default.cfg
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
```bash
cd ~/sites/bodl-iip-srv
~/python/2.7.6/bin/virtualenv .
source bin/activate
pip install zc.buildout
pip install distribute
buildout init
buildout -c development.cfg
```

Install IIP server
------------------

```bash
su - <sudo user>
cd /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/build
sudo dpkg -i iipimage-0.9.9-jp2_amd64.deb
sudo cp /usr/lib/cgi-bin/iipsrv.fcgi /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/fcgi-bin/iipsrv.fcgi
sudo chown bodl-iip-srv:bodl-iip-srv /home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/fcgi-bin/iipsrv.fcgi
su - bodl-iip-srv
```

Test images
-----------

```bash
mkdir -p /home/bodl-iip-srv/sites/bodl-iip-srv/var/images
```

Copy your ```.tif``` and ```.jp2``` images into this directory. 

e.g. 

```bash
cd /home/bodl-iip-srv/sites/bodl-iip-srv/var/images
wget http://merovingio.c2rmf.cnrs.fr/iipimage/PalaisDuLouvre.tif
```

Amend MooViewer image path
--------------------------

```bash
vi /home/bodl-iip-srv/sites/bodl-iip-srv/src/www/index.html
```

Amend the parameter as follows:

```bash
var image = /home/bodl-iip-srv/sites/bodl-iip-srv/iipsrv/var/images/<image name>
```

e.g.

```bash
var image = /home/bodl-iip-srv/sites/bodl-iip-srv/iipsrv/var/images/PalaisDuLouvre.tif
```

Start Apache
------------

From within the virtual environment:

```bash
su - bodl-iip-srv
cd ~/sites/bodl-iip-srv
. bin/activate
/home/bodl-iip-srv/sites/bodl-iip-srv/parts/apache/bin/apachectl start
```

Browse to http://&lt;your server&gt;:8080/index.html

The IIP image server is located at (You should receive a welcome screen at this URL):

http://&lt;your server&gt;:8080/fcgi-bin/iipsrv.fcgi

If there is something wrong, check the logs at ```/home/bodl-iip-srv/sites/bodl-iip-srv/parts/iipsrv/logs/error.log```

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