#!/bin/bash


CONTAINER_TIMEZONE=Europe/Moscow
START_SCRIPT="docker-start.sh"
IDENAGO="https://github.com/idena-network/idena-go.git"
IDENAPATH="idena-go"
RPCPORT=9009
#PORT=50499
P2PPORT=40404
IPFSPORT=40405
DOCKERNAME="idena"


#color
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

CURRENTDIR=$(pwd)
SHELLPATH=$(dirname "$0")
IPADDRESS=$(curl -s4 icanhazip.com)
#while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $RPCPORT)" ]
#do
#(( RPCPORT--))
#done

#while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $IPFSPORT)" ]
#do
#(( IPFSPORT++))
#done

#while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $P2PPORT)" ]
#do
#(( P2PPORT++))
#done

apt update
apt install -y docker.io

echo -n -e "${YELLOW}Input Docker Container Name [default:$DOCKERNAME]:${NC}"
read DOCKERNAME
if [ -z $DOCKERNAME ]; then DOCKERNAME=idena; fi
echo -n -e "${YELLOW}Input RPC port number [default: $RPCPORT]:${NC}"
read ANSWER
if [[ ! ${ANSWER} =~ ^[0-9]+$ ]] ; then ANSWER=9009 ; fi
RPCPORT=$ANSWER
echo -n -e "${YELLOW}Input P2P port number [default: $P2PPORT]:${NC}"
read ANSWER
if [[ ! ${ANSWER} =~ ^[0-9]+$ ]] ; then ANSWER=40404 ; fi
P2PPORT=$ANSWER
echo -n -e "${YELLOW}Input IPFS port number [default: $IPFSPORT]:${NC}"
read ANSWER
if [[ ! ${ANSWER} =~ ^[0-9]+$ ]] ; then ANSWER=40405 ; fi
IPFSPORT=$ANSWER

sed -i "s/.*HTTPPort.*/   \x22HTTPPort\x22: $RPCPORT },/" $SHELLPATH/config.json
sed -i "s/.*IpfsPort.*/   \x22IpfsPort\x22: $IPFSPORT },/" $SHELLPATH/config.json
sed -i "s/.*ListenAddr.*/   \x22ListenAddr\x22: \x22: $P2PPORT\x22,/" $SHELLPATH/config.json

if [ -d $IDENAPATH ]; then cd $IDENAPATH && git fetch; else git clone $IDENAGO && cd $IDENAPATH; fi
LATEST_TAG=$(git tag --sort=-creatordate | head -1)
LATEST_TAG=${LATEST_TAG//v/}
cd $CURRENTDIR
sed -i "s/.*ARG VERSION=.*/ARG VERSION=${LATEST_TAG}/" $SHELLPATH/Dockerfile
if [ ! "$(docker images | grep postarc/idena)" ]; then 
     cd $SHELLPATH && docker build . --tag postarc/idena:latest
fi

cd $CURRENTDIR
echo -e "${GREEN}Writing a startup script...${NC}"
echo -e "docker run -d --name $DOCKERNAME  -p $RPCPORT:$RPCPORT -p $P2PPORT:$P2PPORT -p $IPFSPORT:$IPFSPORT \
-v /root/data/$DOCKERNAME:/root/.idena --restart unless-stopped --hostname idena postarc/idena:latest" >> $START_SCRIPT
chmod +x $START_SCRIPT

rm -rf idena-go
echo -e "${GREEN}Viewing logs:                         docker logs -f --tail 1000 $DOCKERNAME${NC}"
echo -e "${GREEN}Attach bash into running container :  docker exec -it $DOCKERNAME bash -l${NC}" 

if ! crontab -l | grep "$START_SCRIPT"; then
  (crontab -l ; echo "@reboot $CURRENTDIR/$START_SCRIPT") | crontab -
fi
bash $CURRENTDIR/$START_SCRIPT
rm -rf idena-docker
