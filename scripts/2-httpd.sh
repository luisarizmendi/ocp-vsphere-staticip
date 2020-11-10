#!/bin/bash
set -x
yum install -y httpd

cat > /etc/httpd/conf/httpd.conf <<EOF
ServerRoot "/etc/httpd"
Listen 8080
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin root@localhost
<Directory />
    AllowOverride none
    Require all denied
</Directory>
DocumentRoot "/var/www/html"
<Directory "/var/www">
    AllowOverride None
    # Allow open access:
    Require all granted
</Directory>
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>
<Files ".ht*">
    Require all denied
</Files>
ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      # You need to enable mod_logio.c to use %I and %O
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>
<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>
<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>
<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>
AddDefaultCharset UTF-8
<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>
EnableSendfile on
IncludeOptional conf.d/*.conf
EOF










mkdir -p /var/www/html/install
mkdir -p  /var/www/html/ignition
restorecon -vR /var/www/html || true


mkdir -p /var/www/html/ignition


cat > ${MYPATH}/install/append-bootstrap.ign <<EOF
{
  "ignition": {
    "config": {
      "merge": [
        {
          "source": "http://${HTTP_SERVER}:8080/ignition/bootstrap.ign"
        }
      ]
    },
    "version": "3.1.0"
  }
}
EOF

cp ${MYPATH}/install/*ign /var/www/html/ignition/

#cp ${MYPATH}/install/artifacts/rhcos-rootfs.img /var/www/html/ignition/


chmod 644 /var/www/html/ignition/*



systemctl enable httpd
systemctl restart httpd
