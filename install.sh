#!/bin/bash

# Run the Anthem docker image
# (c) Anthem Displays, 2016

read -p "Verify host configuration? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    # Set aliases on the host
    grep "alias enter" ~/.bashrc > /dev/null
    if [ $? -ne 0 ]; then
        # The alias is not there, set it up
        echo alias enter=\"docker exec -it \`docker ps -lq\` /home/anthem/module_control/docker/shell.sh\" >> ~/.bashrc
    fi

    # Using MySQL in a docker container in privileged mode requires disabling
    # MySQL for apparmor.
    if [ ! -f /etc/apparmor.d/disable/usr.sbin.mysqld ]; then
        echo sudo cp /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
             sudo cp /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
        if [ $? -ne 0 ]; then echo "ERROR: Could not disable apparmor MySQL"; fi
    fi
else
    echo "Skipping host config"
fi


read -p "Pull the latest docker image? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    echo sudo -u anthem docker login
         sudo -u anthem docker login
    if [ $? -ne 0 ]; then echo "ERROR: Could not login to docker"; exit -1; fi

    echo sudo -u anthem docker pull anthemdocker/anthem
         sudo -u anthem docker pull anthemdocker/anthem
    if [ $? -ne 0 ]; then echo "ERROR: Could not pull docker image"; exit -1; fi
else
    echo "Skipping docker pull"
fi


read -p "Run the docker image? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    sudo -u anthem ps | grep anthem > /dev/null
    if [ $? -eq 1 ]; then
        echo "Stopping and removing running image"
        echo sudo -u anthem docker stop `docker ps -lq`
        sudo -u anthem docker stop `docker ps -lq`
        echo sudo -u anthem docker stop `docker ps -lq`
        sudo -u anthem docker rm   `docker ps -lq`
    fi

    echo "Running docker image..."
    sudo -u anthem docker run -d --privileged=true --restart=always \
        -v /dev/bus/usb:/dev/bus/usb \
        -v /etc/udev/rules.d:/etc/udev/rules.d \
        -v /var/log/supervisor:/var/log/supervisor \
        -v /home/anthem/config:/home/anthem/config \
        -p 80:80 \
        -p 445:445 \
        -p 139:139 \
        -i -t anthemdocker/anthem \
        /home/anthem/module_control/docker/start.sh
   echo "Log out and back in to get the 'enter' alias working."
else
    echo "Skipping docker run"
fi

read -p "Setup Django? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    echo "Setting up Django..."
    sudo -u anthem docker exec -it `docker ps -lq` sudo -u anthem /home/anthem/module_control/display_control/util/system_controller_setup/non_priv_setup.sh
    echo "Restarting display, relay, lightsensor"
    sudo -u anthem docker exec -it `docker ps -lq` supervisorctl reload
else
    echo "Skipping Django setup"
fi

# Pass the return value of above command as this script's return value
exit $?
