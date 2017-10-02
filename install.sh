#!/bin/bash

#### Preparation
# Make sure the data is available at this path with appropriate permission
# before rglyvis is installed
DATAPATH='/the/path/to/your/data/GTEx_V6-public.h5'


# Where to put the packages
program_dir=$HOME"/Programs"
mkdir -p $program_dir

####[Optional] Ubuntu upgrade 
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:opencpu/opencpu-1.6
sudo apt-get update

#### [Optional] Install an up-to-date R version that is accessible to opencpu
sudo add-apt-repository -y "deb [arch=amd64] https://cran.cnr.berkeley.edu/bin/linux/ubuntu xenial/"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-get update
sudo apt-get install -y r-base
 
#### Install OpenCPU by package manager
sudo apt-get install opencpu

#### Start opencpu
sudo service opencpu start

#### [Optional] Test if OpenCPU is up and running
curl http://localhost/ocpu/info
 
#### Install Redis server
cd $program_dir
wget http://download.redis.io/releases/redis-3.2.8.tar.gz
tar -xzf  redis-3.2.8.tar.gz
cd redis-3.2.8/
make
sudo make install

#### [Optional] Developer tools
cd
sudo Rscript -e "install.packages(c('futile.logger','testthat', 'roxygen2'), repos='https://cran.cnr.berkeley.edu/',Ncpus=2)"
sudo Rscript -e "devtools::install_version('devtools', version='1.11.1', repos='https://cran.cnr.berkeley.edu/',Ncpus=2,quiet=TRUE)"

#### Install bioconductor dependencies
sudo Rscript -e 'source("https://bioconductor.org/biocLite.R");biocLite("rhdf5");'

#### Install rvislib
cd $program_dir
git clone https://@bitbucket.org/glyvis/rvislib.git
cd rvislib
sudo Rscript -e "devtools::install('.')"

#### Install rredis from github, since CRAN version has unfixed bug
sudo Rscript -e 'devtools::install_github("bwlewis/rredis"); devtools::install_dev_deps(".")'

#### Start redis-server
redis-server &
disown

#### Install rglyvis
cd $program_dir
git clone https://@bitbucket.org/glyvis/rglyvis.git
cd rglyvis
git checkout useRedis
##### Replace the data path
Rscript -e `printf 'load("data/sysdata.rda");dbpath=list(gtex="%s");save(list=ls(),file="data/sysdata.rda")' $DATAPATH`
sudo Rscript -e "devtools::install('.', quick=TRUE, force_deps=FALSE, upgrade_dependencies=FALSE)"

##### Add rglyvis to list of preload packages in /etc/opencpu/server.conf
sudo sed -i '/preload/ c\    "preload": ["rglyvis", "ggplot2"]' /etc/opencpu/server.conf
sudo service opencpu restart

#### Install web-app to /var/www/html
cd $program_dir
git clone https://@bitbucket.org/glyvis/glyvis-app.git
sudo mv glyvis-app /var/www/html/
