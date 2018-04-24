#/bin/bash

if [ ! -d "/var/iacapp/" ]; then
  mkdir /var/iacapp/
fi;

mv /tmp/gs-spring-boot-0.1.0.jar /var/iacapp/
useradd iacapp
chown iacapp:iacapp /var/iacapp/gs-spring-boot-0.1.0.jar

cat <<EOF > /etc/systemd/system/iacapp.service;
[Unit]
Description=iacapp
After=syslog.target
[Service]
User=iacapp
ExecStart=/usr/bin/java -jar /var/iacapp/gs-spring-boot-0.1.0.jar
SuccessExitStatus=143
[Install]
WantedBy=multi-user.target
EOF

systemctl enable iacapp.service
systemctl daemon-reload
