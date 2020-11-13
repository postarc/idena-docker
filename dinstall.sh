#!/bin/bash


CONTAINER_TIMEZONE=Europe/Moscow
START_SCRIPT="docker-start.sh"
IDENAGO="https://github.com/idena-network/idena-go.git"
IDENAPATH="idena-go"
RPCPORT=9009
#PORT=50499
P2PPORT=40404
IPFSPORT=40405

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

echo -n -e "${YELLOW}Input Docker Container Name:${NC}"
read DOCKER_NAME
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

if [ -d $IDENAPATH ]; then git fetch; else git clone $IDENAGO; fi
cd $IDENAPATH
LATEST_TAG=$(git tag --sort=-creatordate | head -1)
cd $CURRENTDIR
sed -i "s/.*ARG VERSION=.*/ARG VERSION= ${LATEST_TAG}/" $SHELLPATH/Dockerfile
docker build $SHELLPATH/Dockerfile --tag postarc/idena:latest

cd $CURRENTDIR
echo -e "${GREEN}Writing a startup script...${NC}"
echo -e "docker run -d --name $DOCKER_NAME  -p $RPCPORT:$RPCPORT -p $P2PPORT:$P2PPORT -p $IPFSPORT:$IPFSPORT \
-v $CURRENTDIR/data/$DOCKER_NAME:/root/.idena -w /root/.idena --restart unless-stopped --hostname idena \
-it postarc/idena idena-go --config=/root/.idena/config.json" >> $START_SCRIPT
