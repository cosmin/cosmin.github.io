#!/bin/bash

function install_deps() {
    sudo add-apt-repository ppa:swift-core/ppa
    sudo apt-get update
    sudo apt-get install -y curl gcc bzr memcached python-configobj python-coverage python-dev python-nose python-setuptools python-simplejson python-xattr sqlite3 xfsprogs python-webob python-eventlet python-greenlet python-pastedeploy
}

function create_loopback() {
    user=$1
    group=$2

    sudo dd if=/dev/zero of=/srv/swift-disk bs=1024 count=0 seek=1000000
    sudo mkfs.xfs -i size=1024 /srv/swift-disk
    echo "/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0" | sudo tee -a /etc/fstab > /dev/null
    sudo mkdir /mnt/sdb1
    sudo mount /mnt/sdb1
    sudo mkdir /mnt/sdb1/1 /mnt/sdb1/2 /mnt/sdb1/3 /mnt/sdb1/4 /mnt/sdb1/test
    sudo chown $user:$group /mnt/sdb1/*

    for x in {1..4}; do 
        sudo ln -s /mnt/sdb1/$x /srv/$x; 
    done

    sudo mkdir -p /etc/swift/object-server /etc/swift/container-server /etc/swift/account-server /srv/1/node/sdb1 /srv/2/node/sdb2 /srv/3/node/sdb3 /srv/4/node/sdb4 /var/run/swift
    sudo chown -R $user:$group /etc/swift /srv/[1-4]/ /var/run/swift

    #if grep -q /var/run/swift /etc/rc.local; then
    #    echo "/etc/rc.local already configured"
    #else
    sudo sed -i /etc/rc.local -e "/^exit 0/ {
      i mkdir /var/run/swift
      i chown $user:$group /var/run/swift
    }"
    #fi
}

function setup_rsync() {
    user=$1
    group=$2

    cat > /tmp/rsyncd.conf <<EOF
uid = $user
gid = $group
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 127.0.0.1

[account6012]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/account6012.lock

[account6022]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/account6022.lock

[account6032]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/account6032.lock

[account6042]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/account6042.lock


[container6011]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/container6011.lock

[container6021]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/container6021.lock

[container6031]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/container6031.lock

[container6041]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/container6041.lock


[object6010]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/object6010.lock

[object6020]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/object6020.lock

[object6030]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/object6030.lock

[object6040]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/object6040.lock
EOF
    sudo mv /tmp/rsyncd.conf /etc/rsyncd.conf

    sudo sed -i /etc/default/rsync -e '/^RSYNC_ENABLE/ { 
      x
      i RSYNC_ENABLE=true
    }'

    sudo service rsync restart
}

function checkout_git() {
    sudo apt-get install -y git-core
    git clone https://github.com/openstack/swift.git
}

function setup_checkout() {
    checkout=$1
    cd $checkout
    sudo python setup.py develop
    
    cat > ~/.bashrc <<"EOF"
export PATH_TO_TEST_XFS=/mnt/sdb1/test
export SWIFT_TEST_CONFIG_FILE=/etc/swift/func_test.conf
export PATH=${PATH}:~/bin
EOF

    . ~/.bashrc    
}

function configure_node() {
    user=$1
    admin_key=$2

    cat > /tmp/auth-server.conf <<EOF
[DEFAULT]
user = $user

[pipeline:main]
pipeline = auth-server

[app:auth-server]
use = egg:swift#auth
default_cluster_url = http://127.0.0.1:8080/v1
# Highly recommended to change this.
super_admin_key = $2
EOF

    sudo mv /tmp/auth-server.conf /etc/swift/auth-server.conf

    cat > /tmp/proxy-server.conf <<EOF
[DEFAULT]
bind_port = 8080
user = $user

[pipeline:main]
pipeline = healthcheck cache auth proxy-server

[app:proxy-server]
use = egg:swift#proxy

[filter:auth]
use = egg:swift#auth

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:cache]
use = egg:swift#memcache
EOF

    sudo mv /tmp/proxy-server.conf /etc/swift/proxy-server.conf

    cat > /tmp/swift.conf <<EOF
[swift-hash]
# random unique string that can never change (DO NOT LOSE)
swift_hash_path_suffix = `head -c 20 /dev/urandom | md5sum | cut -d" " -f 1`
EOF

    sudo mv /tmp/swift.conf /etc/swift/swift.conf

    for x in {1..4}; do 
        cat > account-server.conf <<EOF
[DEFAULT]
devices = /srv/${x}/node
mount_check = false
bind_port = 60${x}2
user = $user

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]
vm_test_mode = yes

[account-auditor]

[account-reaper]
EOF
        sudo mv account-server.conf /etc/swift/account-server/${x}.conf

        cat > container-server.conf <<EOF
[DEFAULT]
devices = /srv/${x}/node
mount_check = false
bind_port = 60${x}1
user = $user

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]
vm_test_mode = yes

[container-updater]

[container-auditor]
EOF

        sudo mv container-server.conf /etc/swift/container-server/${x}.conf

        cat > object-server.conf <<EOF
[DEFAULT]
devices = /srv/${x}/node
mount_check = false
bind_port = 60${x}0
user = ${user}

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]
vm_test_mode = yes

[object-updater]

[object-auditor]
EOF

        sudo mv object-server.conf /etc/swift/object-server/${x}.conf
    done
}

function setup_scripts() {
    user=$1
    group=$2
    key=$3

    mkdir ~/bin
    cat > ~/bin/resetswift <<EOF
#!/bin/bash

swift-init all stop
sleep 5
sudo umount /mnt/sdb1
sudo mkfs.xfs -f -i size=1024 /srv/swift-disk
sudo mount /mnt/sdb1
sudo mkdir /mnt/sdb1/1 /mnt/sdb1/2 /mnt/sdb1/3 /mnt/sdb1/4 /mnt/sdb1/test
sudo chown <your-user-name>:<your-group-name> /mnt/sdb1/*
mkdir -p /srv/1/node/sdb1 /srv/2/node/sdb2 /srv/3/node/sdb3 /srv/4/node/sdb4
sudo rm -f /var/log/debug /var/log/messages /var/log/rsyncd.log /var/log/syslog
sudo service rsyslog restart
sudo service memcached restart
EOF

    cat > ~/bin/remakerings <<EOF
#!/bin/bash

cd /etc/swift

rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add z1-127.0.0.1:6010/sdb1 1
swift-ring-builder object.builder add z2-127.0.0.1:6020/sdb2 1
swift-ring-builder object.builder add z3-127.0.0.1:6030/sdb3 1
swift-ring-builder object.builder add z4-127.0.0.1:6040/sdb4 1
swift-ring-builder object.builder rebalance
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add z1-127.0.0.1:6011/sdb1 1
swift-ring-builder container.builder add z2-127.0.0.1:6021/sdb2 1
swift-ring-builder container.builder add z3-127.0.0.1:6031/sdb3 1
swift-ring-builder container.builder add z4-127.0.0.1:6041/sdb4 1
swift-ring-builder container.builder rebalance
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add z1-127.0.0.1:6012/sdb1 1
swift-ring-builder account.builder add z2-127.0.0.1:6022/sdb2 1
swift-ring-builder account.builder add z3-127.0.0.1:6032/sdb3 1
swift-ring-builder account.builder add z4-127.0.0.1:6042/sdb4 1
swift-ring-builder account.builder rebalance
EOF

    cat > ~/bin/startmain <<EOF
#!/bin/bash

swift-init auth-server start
swift-init proxy-server start
swift-init account-server start
swift-init container-server start
swift-init object-server start
EOF

    cat > ~/bin/startrest <<EOF
#!/bin/bash

# Replace devauth with whatever your super_admin key is (recorded in
# /etc/swift/auth-server.conf).
swift-auth-recreate-accounts -K $key
swift-init object-updater start
swift-init container-updater start
swift-init object-replicator start
swift-init container-replicator start
swift-init account-replicator start
swift-init object-auditor start
swift-init container-auditor start
swift-init account-auditor start
swift-init account-reaper start
EOF
    chmod +x ~/bin/*
}

function start() {
    remakerings
    startmain
}

function things_to_try() {
    cat - <<EOF
Swift is now installed and ready for development"

echo "Other things you could try"


swift-auth-add-user -K devauth -a test tester testing # Replace devauth with whatever your super_admin key is (recorded in /etc/swift/auth-server.conf).
Get an X-Storage-Url and X-Auth-Token: curl -v -H 'X-Storage-User: test:tester' -H 'X-Storage-Pass: testing' http://127.0.0.1:11000/v1.0

Check that you can GET account: curl -v -H 'X-Auth-Token: <token-from-x-auth-token-above>' <url-from-x-storage-url-above>

Check that st works: st -A http://127.0.0.1:11000/v1.0 -U test:tester -K testing stat

swift-auth-add-user -K devauth -a test2 tester2 testing2 # Replace devauth with whatever your super_admin key is (recorded in /etc/swift/auth-server.conf).
swift-auth-add-user -K devauth test tester3 testing3 # Replace devauth with whatever your super_admin key is (recorded in /etc/swift/auth-server.conf).

cp ~/swift/trunk/test/functional/sample.conf /etc/swift/func_test.conf
cd ~/swift/trunk; ./.functests (Note: functional tests will first delete everything in the configured accounts.)
cd ~/swift/trunk; ./.probetests (Note: probe tests will reset your environment as they call resetswift for each test.)
EOF
}

admin_key=$1
if [ -z $admin_key ]; then
    echo "You must supply an admin key"
    exit 1
fi

user=$USER
group=` groups | cut -d" " -f 1`

echo "** Installing dependencies for Swift **"
install_deps

echo "** Creating loopback device **"
create_loopback $user $group

echo "** Setting up rsync **"
setup_rsync $user $group

echo "** Checking out from Git **"
checkout_git

echo "** Setting up the checkout **"
setup_checkout $HOME/swift

echo "** Configuring the node **"
configure_node $user $admin_key

echo "** Setting up the scripts **"
setup_scripts $user $group $admin_key

echo "** Starting swift **"
start

echo ""
echo ""

things_to_try
