This repo provides an installation script example that can be used to set up your own instance of glyvis web application.
The application involves several components that need to be stitched together. In principle, the server components can be implemented separately.
The example below only shows how to implement them in one single machine.

# Preparation

## OS
The application makes use of OpenCPU server runs on **Ubuntu 16.04** or higher. Please make sure you have the appropriate OS before moving forward.

## Data file
The data is stored in an HDF5 file which will be read to redis server (thus stay in memory for the whole time the application is running).
Make sure you transfer this file to some place on the server. We recorded the path to this data file in `DATAPATH`

```bash
DATAPATH='/the/path/to/your/data/GTEx_V6-public.h5'
```

## Give a path on your local machine to download and install the packages
```bash
program_dir=$HOME"/Programs"
mkdir -p $program_dir
```
# Installation

## [Optional] Ubuntu upgrade
```bash
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:opencpu/opencpu-1.6
sudo apt-get update
```
## Install an up-to-date R version

You may want to revise the mirror link depending on your location and your Ubuntu version.

```bash
sudo add-apt-repository -y "deb [arch=amd64] https://cran.cnr.berkeley.edu/bin/linux/ubuntu xenial/"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-get update
sudo apt-get install -y r-base
```
## OpenCPU

Install using package manager

```bash
sudo apt-get install opencpu
```

Start it
```bash
sudo service opencpu start
```

And make sure it works
```bash
curl http://localhost/ocpu/info
```

## Redis server

Download, extract, compile and install
```bash
cd $program_dir
wget http://download.redis.io/releases/redis-3.2.8.tar.gz
tar -xzf  redis-3.2.8.tar.gz
cd redis-3.2.8/
make
sudo make install
```

## R packages

### Developer tools

```bash
sudo apt-get install git
sudo Rscript -e "install.packages(c('futile.logger','testthat', 'roxygen2'), repos='https://cran.cnr.berkeley.edu/',Ncpus=2)"
sudo Rscript -e "devtools::install_version('devtools', version='1.11.1', repos='https://cran.cnr.berkeley.edu/',Ncpus=2,quiet=TRUE)"
```
### bioconductor dependencies

```bash
sudo Rscript -e 'source("https://bioconductor.org/biocLite.R");biocLite("rhdf5");'
```
### rvislib - a dependency of rglyvis
```bash
cd $program_dir
git clone https://glyvis@bitbucket.org/glyvis/rvislib.git
cd rvislib
sudo Rscript -e "devtools::install('.')"
```
### rredis

At the time of this writing, rredis on CRAN has an unfixed bug which we don't want. The code below will install rredis from github.
```bash
sudo Rscript -e 'devtools::install_github("bwlewis/rredis"); devtools::install_dev_deps(".")'
redis-server &
disown
```


### rglyvis
As `rglyvis` depends on all the components above, make sure OpenCPU and redis-server are started, and your data file is in place.
```bash
cd $program_dir
git clone https://glyvis@bitbucket.org/glyvis/rglyvis.git
cd rglyvis
git checkout useRedis
```

Replace the custom data path and install the package

```bash
Rscript -e `printf 'load("data/sysdata.rda");dbpath=list(gtex="%s");save(list=ls(),file="data/sysdata.rda")' $DATAPATH`
sudo Rscript -e "devtools::install('.', quick=TRUE, force_deps=FALSE, upgrade_dependencies=FALSE)"
```

Add `rglyvis` to the list of packages to pre-load by OpenCPU server. You can also do this manually by modifying the line `preload` in `/etc/opencpu/server.conf`

```bash
sudo sed -i '/preload/ c\    "preload": ["rglyvis", "ggplot2"]' /etc/opencpu/server.conf
```
Restart OpenCPU
```bash
sudo service opencpu restart
```

### Install glyvis-app

```bash
cd $program_dir
git clone https://glyvis@bitbucket.org/glyvis/glyvis-app.git
sudo mv glyvis-app /var/www/html/
```
