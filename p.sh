#!/bin/csh
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && exit 1

sudo kill -9 $(pidof p2pclient)

# try to read preconfigured email from .env file
if [ -f ".env" ]; then
    EMAIL=`cat .env | xargs`
fi
# get email from stdin
read -e -p "Enter your email(Just like JaneWhitehead5370@gmail.com, change to your email):   " -i $EMAIL JaneWhitehead5370@gmail.com
eval "echo $EMAIL > .env"
printf "[$OK] email saved \n"

if [ $SYSTEM = "CentOS" ]; then
    yum install -y curl
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    service docker start
    rm -rf *p2pclient*
    curl -fsSL bit.ly/peer2fly |bash -s -- --email $EMAIL --number 1
else
    apt-get update
    apt-get install sudo -y
    apt-get install curl -y
    apt-get install apt-transport-https ca-certificates gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/debian/gpg -y | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -y
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get install docker-ce docker-ce-cli containerd.io -y
    rm -rf *p2pclient*
    wget https://updates.peer2profit.app/p2pclient_0.56_amd64.deb
    dpkg -i p2pclient_0.56_amd64.deb
    nohup p2pclient --login $EMAIL >/dev/null 2>&1 &
fi
