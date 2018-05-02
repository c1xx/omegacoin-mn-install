#!/bin/bash

clear
# Declare STRING variables
STRING1="Make sure you double check before pressing enter! One chance at this only!"
STRING2="Updating system and installing required packages."
STRING3="Switching to Aptitude"
STRING4="Installing Firewall and Fail2Ban"
STRING5="Starting your masternode"
STRING6="Now, you need to finally start your masternode in the following order:"
STRING7="Go to your windows/mac wallet and modify masternode.conf as required, then restart and from the Control wallet debug console please enter"
STRING8="masternode start-alias <mymnalias>"
STRING9="where <mymnalias> is the name of your masternode alias (without brackets)"
STRING10="once completed please return to VPS and press the space bar"
STRING11=""
STRING12="Installing and configuring Sentinel"

# Declare Omegacoin variables
CORE_URL=https://github.com/omegacoinnetwork/omegacoin/releases/download/0.12.5.1/omagecoincore-0.12.5.1-linux64.zip
CORE_FILE=omagecoincore-0.12.5.1-linux64.zip
DATA_DIR=~/omega
CONF_DIR=~/.omegacoincore
CONF_FILE=omegacoin.conf
SENTINEL_CONF=$DATA_DIR/sentinel/sentinel.conf
PORT=7777

# Print variable on a screen
echo $STRING1
echo $STRING11

# Ask for important Data for configuring Masternode
read -e -p "Server IP Address : " VPS_IP
read -e -p "Masternode Private Key (e.g. 7sQ27dGdwwEGrAPHmfghBBfWZnC6K1rDATNvm986dDfsaw3Wws4 # THE KEY YOU GENERATED EARLIER) : " MN_PRIV_KEY

clear
echo $STRING2
sleep 10 

# Update package and upgrade Ubuntu and install required packages
echo $STRING11
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove
sudo apt-get install git unzip wget nano htop -y
sudo apt-get install automake build-essential libtool autotools-dev autoconf pkg-config libssl-dev -y
sudo apt-get install libboost-all-dev git npm nodejs nodejs-legacy libminiupnpc-dev redis-server -y
sudo apt-get install software-properties-common -y
sudo apt-get install libevent-dev -y
add-apt-repository ppa:bitcoin/bitcoin -y
apt-get update -y
apt-get install libdb4.8-dev libdb4.8++-dev -y
source ~/.profile
clear
echo $STRING3
apt-get -y install aptitude

echo $STRING4
echo $STRING11
sudo apt-get install ufw
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
sudo echo "y" | sudo ufw enable
sudo aptitude -y install fail2ban
sudo service fail2ban restart

# Generating Random Passwords
password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

wget $CORE_URL
unzip $CORE_FILE -d $DATA_DIR
sudo chmod +x $DATA_DIR/omegacoin-cli
sudo chmod +x $DATA_DIR/omegacoind
sudo chmod +x $DATA_DIR/omegacoin-qt
sudo mv $DATA_DIR/omegacoin-cli /usr/local/bin
sudo mv $DATA_DIR/omegacoind /usr/local/bin
sudo mv $DATA_DIR/omegacoin-qt /usr/local/bin
sudo rm $CORE_FILE
sudo ufw allow $PORT/tcp

# Create omegacoin.conf
sudo mkdir $CONF_DIR
sudo touch $CONF_DIR/$CONF_FILE
echo 'rpcuser='$password'
rpcpassword='$password2'
rpcallowip=127.0.0.1
externalip='$VPS_IP'
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=128
masternode=1

addnode=142.208.127.121
addnode=154.208.127.121
addnode=142.208.122.127

port='$PORT'
masternodeaddr=127.0.0.1:'$PORT'
masternodeprivkey='$MN_PRIV_KEY'
' | sudo -E tee $CONF_DIR/$CONF_FILE >/dev/null 2>&1
sudo chmod 0600 $CONF_DIR/$CONF_FILE

echo 'omegacoin.conf created'
sleep 40

clear

echo $STRING12
# Sentinel Installation / Configuration
cd $DATA_DIR
sudo apt-get -y install python-virtualenv virtualenv
git clone https://github.com/omegacoinnetwork/sentinel.git && cd sentinel
virtualenv ./venv
./venv/bin/pip install -r requirements.txt
./venv/bin/python bin/sentinel.py
echo "* * * * * cd $DATA_DIR/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> /var/spool/cron/crontabs/root

echo 'omegacoin_conf='$CONF_DIR'/omegacoin.conf
network=mainnet
db_name=database/sentinel.db
db_driver=sqlite' | sudo -E tee $SENTINEL_CONF >/dev/null 2>&1

clear
echo $STRING5
omegacoind -daemon

echo $STRING11
echo $STRING6
echo $STRING7
echo $STRING8
echo $STRING9
echo $STRING10
echo $STRING11

read -p "(this message will remain for at least 120 seconds) Then press any key to continue... " -n1 -s
sleep 120
echo $STRING11
omegacoin-cli masternode status
