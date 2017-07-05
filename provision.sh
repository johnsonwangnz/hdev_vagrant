#!/usr/bin/env bash
# this is running as root
#stop on error
set -e
echo "If there was a problem, please correct and destroy and start provision process again, as the script only suppose to be run once..."

#to remove a package 
#sudo apt-get --purge remove packagename

echo "Create apps folder under home for all installed apps"
mkdir  ~/apps

echo "Set timezone instead of using UTC"
echo  'Pacific/Auckland' | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

echo "Prepare folders..."
echo "To remove libreoffice apps:"
sudo apt-get remove -y --purge libreoffice*
sudo apt-get -y clean
sudo apt-get -y autoremove
# Vim it has to be manually installed, complaining about not getting some downloads 
echo "To install full vim"
sudo apt-get -y  install vim
echo "To install tree command"
sudo apt-get -y install tree
echo "Install java8"
echo "If it hangs at setting grub-pc, please run:"
echo "sudo dpkg --configure -a"
echo "After restart the vagrant with no provision(comment it out) and vagrant ssh "
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
#sudo apt-get -y upgrade
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java8-installer
#set JAVA_HOME
export "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.profile
#sudo apt-get install oracle-java8-set-default
echo "Install git and git gui"
sudo apt-get -y install git
sudo apt-get -y install git-gui

echo "Install maven"
sudo apt-get -y install maven	

echo "Install docker :"
echo "Issuing following to check docker version"
echo "sudo docker --version"
sudo wget -qO- https://get.docker.com/ | sh

echo "Install docker composer"
echo "Add current user to docker group"
sudo usermod -aG docker $(whoami)

echo "Install Python-pip"
sudo apt-get -y install python-pip

echo "Install docker-compose"
echo "Verify : docker-compose --version"
sudo pip install docker-compose 

#install spark
echo "Checking spark folder..."
if [ ! -d "/usr/local/spark" ]; then
	echo "Install spark-2.1.0"
	wget http://d3kbcqa49mib13.cloudfront.net/spark-2.1.0-bin-hadoop2.7.tgz
	tar -xzvf  spark-2.1.0-bin-hadoop2.7.tgz
	mv spark-2.1.0-bin-hadoop2.7 ~/apps/spark
	rm spark-2.1.0-bin-hadoop2.7.tgz
	echo "export SPARK_HOME=/home/vagrant/apps/spark" >> ~/.profile
	export SPARK_HOME=/home/vagrant/apps/spark
fi

# Add hadoop hosts names to local hosts
if ! grep -q "hadoop-master" /etc/hosts 
then
	echo '172.18.0.2 hadoop-master' | sudo tee --append /etc/hosts
fi

if ! grep -q "hadoop-slave1" /etc/hosts 
then
	echo '172.18.0.3 hadoop-slave1' | sudo tee --append /etc/hosts
fi

if ! grep -q "hadoop-slave2" /etc/hosts 
then
	echo '172.18.0.4 hadoop-slave2' | sudo tee --append /etc/hosts
fi


#Fix docker compose build error:  module object has no attribute connection
#echo "Do following to avoid docker compose build error:  module object has no attribute connection"
#sudo pip install --upgrade pip 
#sudo pip install -U urllib3

echo "Checking mydocker folder..."
if [ ! -d "/home/vagrant/mydocker" ]; then
	#Get big data dev docker files
	echo "Git clone bddevdocker docker files"
	mkdir mydocker
	cd mydocker
	git clone https://github.com/johnsonwangnz/bddevdocker.git
	cd ..
fi

echo "Installing hadoop 2.7.3 "
wget http://www-eu.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz && \
    tar -xzvf hadoop-2.7.3.tar.gz && \
    mv hadoop-2.7.3 ~/apps/hadoop && \
    rm hadoop-2.7.3.tar.gz

echo "export HADOOP_HOME=/home/vagrant/apps/hadoop" >> ~/.profile
export HADOOP_HOME=/home/vagrant/apps/hadoop
echo "export PATH=$PATH:/home/vagrant/apps/hadoop/bin:/home/vagrant/apps/hadoop/sbin" >> ~/.profile
export PATH=$PATH:/home/vagrant/apps/hadoop/bin:/home/vagrant/apps/hadoop/sbin

echo "Making ssh localhost passwordless for pseudodistributed mode, testing it by : ssh localhost"
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo "Add pseudodistributed configuration"
mkdir -p ~/config
cp -r /home/vagrant/apps/hadoop/etc/hadoop  ~/config
#copy config files 
cp -r /vagrant/hadoopConfig/. ~/config/hadoop/

echo "export HADOOP_CONF_DIR=/home/vagrant/config/hadoop" >> ~/.profile
export HADOOP_CONF_DIR=/home/vagrant/config/hadoop

echo "Add JAVA_HOME to hadoop-env.sh"
sed -i -e 's@${JAVA_HOME}@/usr/lib/jvm/java-8-oracle@' ~/config/hadoop/hadoop-env.sh
echo "Formatting namenode"
hdfs namenode -format

echo "Copy start and stop scripts for hadoop"
cp /vagrant/scripts/start-all.sh ~/
cp /vagrant/scripts/stop-all.sh ~/

echo "Sucecessfully Finished provisioning of vagrant."
echo "vagrant ssh to start using."








