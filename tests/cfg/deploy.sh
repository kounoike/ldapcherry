#!/bin/sh

if ! [ -z "$TRAVIS" ]
then
  DEBIAN_FRONTEND=noninteractive apt-get install ldap-utils slapd -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  -f -q -y
  DEBIAN_FRONTEND=noninteractive apt-get install lsb-base libattr1 -t wheezy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  -f -q -y
  DEBIAN_FRONTEND=noninteractive apt-get install samba python-samba samba-vfs-modules -t wheezy-backports -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  -f -q -y
else
  DEBIAN_FRONTEND=noninteractive apt-get install ldap-utils slapd samba python-samba samba-vfs-modules -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  -f -q -y
fi

rsync -a `dirname $0`/ /
cd `dirname $0`/../../
sudo sed -i "s%template_dir.*%template_dir = '`pwd`/resources/templates/'%" /etc/ldapcherry/ldapcherry.ini
sudo sed -i "s%tools.staticdir.dir.*%tools.staticdir.dir = '`pwd`/resources/static/'%" /etc/ldapcherry/ldapcherry.ini

chown -R openldap:openldap /etc/ldap/
rm /etc/ldap/slapd.d/cn\=config/*mdb*
/etc/init.d/slapd restart
ldapadd -H ldap://localhost:390  -x -D "cn=admin,dc=example,dc=org" -f /etc/ldap/content.ldif -w password
sed -i "s/\(127.0.0.1.*\)/\1 ldap.ldapcherry.org ad.ldapcherry.org/" /etc/hosts


mount -o remount,acl /

df -h

smbconffile=/etc/samba/smb.conf
domain=dc
realm=dc.ldapcherry.org
sambadns=SAMBA_INTERNAL
targetdir=/var/lib/samba/
role=dc
sambacmd=samba-tool
adpass=qwertyP455

echo "deploy AD"
printf '' > "${smbconffile}" && \
    ${sambacmd} domain provision ${hostip} \
    --domain="${domain}" --realm="${realm}" --dns-backend="${sambadns}" \
    --targetdir="${targetdir}" --workgroup="${domain}" --use-rfc2307 \
    --configfile="${smbconffile}" --server-role="${role}" -d 1 --adminpass="${adpass}"
    

echo "Move configuration"
mv "${targetdir}/etc/smb.conf" "${smbconffile}"

mv /var/lib/samba/private/krb5.conf /etc/krb5.conf


sleep 5
if ! [ -z "$TRAVIS" ]
then
  /usr/sbin/samba -D -s /etc/samba/smb.conf
  /usr/sbin/smbd -D --option=server role check:inhibit=yes --foreground
else
  sh -x /etc/init.d/samba start
  sh -x /etc/init.d/samba-ad-dc start
  sh -x /etc/init.d/smbd start
  sh -x /etc/init.d/nmbd start
fi

sleep 5

netstat -apn