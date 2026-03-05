#!/bin/sh
set -e

# Environment variables with defaults
: ${SVN_ROOT:=/var/svn}
: ${AuthLDAPURL:=ldap://ldap.example.com:389/dc=example,dc=com?uid?sub?(objectClass=person)}
: ${AuthLDAPBindDN:=cn=readonly,dc=example,dc=com}
: ${AuthLDAPBindPassword:=password}
: ${RequireLDAPGroup:=svn-users}
: ${LDAPBaseDN:=dc=example,dc=com}
: ${AuthName:=Subversion Repository}
: ${BehindSSLProxy:=true}

# Create SVN root if it doesn't exist
if [ ! -d "$SVN_ROOT" ]; then
    mkdir -p "$SVN_ROOT"
    svnadmin create "$SVN_ROOT/repository"
fi

# Generate Apache config
cat <<EOF > /usr/local/apache2/conf/extra/vife.conf
LoadModule      dav_module           modules/mod_dav.so
LoadModule      dav_svn_module       /usr/lib/apache2/modules/mod_dav_svn.so
LoadModule      authz_svn_module     /usr/lib/apache2/modules/mod_authz_svn.so
LoadModule      ldap_module          modules/mod_ldap.so
LoadModule      authnz_ldap_module   modules/mod_authnz_ldap.so

EOF

# Add SSL proxy fix if enabled
if [ "$BehindSSLProxy" = "true" ]; then
cat <<EOF >> /usr/local/apache2/conf/extra/vife.conf
# Fix for SSL-terminating reverse proxy
RequestHeader edit Destination ^https: http: early

EOF
fi

cat <<EOF >> /usr/local/apache2/conf/extra/vife.conf
<Location />
    DAV svn
    SVNParentPath $SVN_ROOT
    SVNListParentPath On
    AuthName "$AuthName"
    AuthBasicProvider ldap
    AuthType Basic
    AuthLDAPGroupAttribute member
    AuthLDAPGroupAttributeIsDN on
    AuthLDAPURL ${AuthLDAPURL}
    AuthLDAPBindDN "${AuthLDAPBindDN}"
    AuthLDAPBindPassword "${AuthLDAPBindPassword}"
    Require ldap-group CN=${RequireLDAPGroup},CN=Users,${LDAPBaseDN}
</Location>
EOF

exec "$@"