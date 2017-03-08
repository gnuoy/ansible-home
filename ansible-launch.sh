#!/bin/bash

function run_shared {
    cname=$1
    adm_group=$2
    lxc exec $cname -- useradd -d /home/ansuser -m -g $adm_group -s /bin/bash ansuser
    lxc exec $cname -- mkdir -p /home/ansuser/.ssh
    lxc exec $cname -- chmod 700 /home/ansuser/.ssh
    lxc file push /home/liam/.ssh/id_rsa.pub $cname/home/ansuser/.ssh/authorized_keys
    lxc exec $cname -- chmod 600 /home/ansuser/.ssh/authorized_keys
    lxc exec $cname -- chown -R ansuser /home/ansuser/.ssh
    cip=$(lxc list -c4 $cname | awk '/eth/ {print $2}')
    ssh-keyscan $cip >> ~/.ssh/known_hosts
}
function run_ubuntu {
    cname=$1
    lxc exec $cname -- apt update
    lxc exec $cname -- sed -i -e "\$aansuser ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/90-cloud-init-users
    run_shared $cname adm
}
function run_ubuntu_trusty {
    cname=$1
    run_ubuntu $cname
}
function run_ubuntu_xenial {
    cname=$1
    run_ubuntu $cname
    lxc exec $cname -- apt install --yes python-simplejson
}
function run_centos {
    cname=$1
    lxc exec $cname -- yum update
    lxc exec $cname -- yum install -y openssh-server sudo
    lxc exec $cname -- systemctl start sshd.service
    lxc exec $cname -- sed -i -e '/NOPASSWD/s/^# //' /etc/sudoers
    run_shared $cname wheel
}
function launch {
    image=$1
    cname=$2
    lxc launch $image $cname
    while true; do
        cip=$(lxc list -c4 $cname | awk '/eth/ {print $2}')
        if [[ ! -z $cip ]]; then
            break
        fi
        sleep 0.2
    done
}
[ -z $1 ] && { echo "Please set a image"; exit 1; }
[ -z $2 ] && { echo "Please set a machine name(s)"; exit 1; }

#image=${2:-"ubuntu-daily:16.04"} 
image=$1
shift
names=$@
for name in $names; do
    cname="ans-$name"
    echo $cname
    launch $image $cname
    { echo $image | grep trusty; } && { run_ubuntu_trusty $cname; }
    { echo $image | grep xenial; } && { run_ubuntu_xenial $cname; }
    { echo $image | grep centos; } && { run_centos $cname; }
done

./write_ansible_hosts.py
#grep '\[anstest\]' /etc/ansible/hosts || { sudo bash -c 'echo "[anstest]" >> /etc/ansible/hosts'; }
#sudo bash -c 'echo "[anstest]" >> /etc/ansible/hosts';
