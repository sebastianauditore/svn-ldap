# SVN + LDAP Docker

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/r/yourusername/svn-ldap)
[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/yourusername/svn-ldap-docker)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)

A lightweight, production-ready SVN (Subversion) server with LDAP authentication support. Built on Apache httpd:2.4 with minimal configuration required.

## ✨ Features

- 🔐 **LDAP Authentication** - Integrate with your existing LDAP/Active Directory
- 🚀 **Easy Setup** - Configure via environment variables
- 🔒 **SSL Proxy Support** - Works seamlessly behind nginx/traefik reverse proxy
- 📦 **Auto Repository Creation** - Default repository created on first run
- 🐳 **Docker Native** - Single container, easy deployment
- ⚡ **Lightweight** - Based on official httpd:2.4 image
- 🔧 **Flexible** - Supports multiple repositories via SVNParentPath

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [LDAP Setup](#ldap-setup)
- [Reverse Proxy](#reverse-proxy)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Quick Start

### Using Docker Compose (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/svn-ldap-docker.git
   cd svn-ldap-docker
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   ```

3. **Edit `.env` with your LDAP settings**
   ```bash
   nano .env
   ```

4. **Start the service**
   ```bash
   docker-compose up -d
   ```

5. **Access your SVN repository**
   ```bash
   svn checkout http://localhost:8080/svn/repository --username yourldapuser
   ```

### Using Docker Run

```bash
docker run -d \
  --name svn-ldap \
  -p 8080:80 \
  -e AuthLDAPURL="ldap://ldap.example.com:389/dc=example,dc=com?uid?sub?(objectClass=person)" \
  -e AuthLDAPBindDN="cn=readonly,dc=example,dc=com" \
  -e AuthLDAPBindPassword="yourpassword" \
  -e RequireLDAPGroup="svn-users" \
  -e LDAPBaseDN="dc=example,dc=com" \
  -v ./svn-data:/var/svn \
  yourusername/svn-ldap:latest
```

### Using Pre-built Image from Docker Hub

```bash
docker pull yourusername/svn-ldap:latest
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `SVN_ROOT` | `/var/svn` | No | Root directory for SVN repositories |
| `AuthLDAPURL` | - | Yes | LDAP server URL with search parameters |
| `AuthLDAPBindDN` | - | Yes | Distinguished Name for LDAP bind |
| `AuthLDAPBindPassword` | - | Yes | Password for LDAP bind user |
| `RequireLDAPGroup` | `svn-users` | No | LDAP group required for access |
| `LDAPBaseDN` | - | Yes | Base DN for LDAP searches |
| `AuthName` | `Subversion Repository` | No | Authentication realm displayed to users |
| `BehindSSLProxy` | `true` | No | Enable fixes for SSL-terminating proxies |

### Example .env File

```bash
# SVN Configuration
SVN_ROOT=/var/svn

# LDAP Server Configuration
AuthLDAPURL=ldap://ldap.company.com:389/dc=company,dc=com?uid?sub?(objectClass=person)
AuthLDAPBindDN=cn=svn-readonly,ou=service-accounts,dc=company,dc=com
AuthLDAPBindPassword=SecurePassword123

# LDAP Authorization
RequireLDAPGroup=developers
LDAPBaseDN=dc=company,dc=com

# UI Configuration
AuthName=Company Source Code Repository

# Proxy Configuration
BehindSSLProxy=true
```

## 🔐 LDAP Setup

### LDAP URL Format

```
ldap://hostname:port/basedn?attribute?scope?filter
```

**Components:**
- `hostname:port` - LDAP server address (default port: 389, SSL: 636)
- `basedn` - Base DN for user searches
- `attribute` - Attribute to match username (usually `uid` or `sAMAccountName`)
- `scope` - Search scope (`sub` for subtree, `one` for one level)
- `filter` - Additional LDAP filter (optional)

### Common Examples

#### OpenLDAP
```bash
AuthLDAPURL=ldap://openldap.example.com:389/dc=example,dc=com?uid?sub?(objectClass=person)
AuthLDAPBindDN=cn=readonly,dc=example,dc=com
RequireLDAPGroup=svn-users
LDAPBaseDN=dc=example,dc=com
```

#### Active Directory
```bash
AuthLDAPURL=ldap://ad.company.com:389/dc=company,dc=com?sAMAccountName?sub?(objectClass=user)
AuthLDAPBindDN=CN=SVN Service,OU=Service Accounts,DC=company,DC=com
RequireLDAPGroup=SVN-Developers
LDAPBaseDN=dc=company,dc=com
```

#### FreeIPA
```bash
AuthLDAPURL=ldap://ipa.example.com:389/dc=example,dc=com?uid?sub?(objectClass=inetOrgPerson)
AuthLDAPBindDN=uid=svn-bind,cn=sysaccounts,cn=etc,dc=example,dc=com
RequireLDAPGroup=svn-users
LDAPBaseDN=dc=example,dc=com
```

### Testing LDAP Connection

```bash
# Test LDAP bind
ldapsearch -x -H ldap://ldap.example.com:389 \
  -D "cn=readonly,dc=example,dc=com" \
  -w "password" \
  -b "dc=example,dc=com" \
  "(uid=testuser)"

# Test group membership
ldapsearch -x -H ldap://ldap.example.com:389 \
  -D "cn=readonly,dc=example,dc=com" \
  -w "password" \
  -b "dc=example,dc=com" \
  "(cn=svn-users)"
```

## 🔄 Reverse Proxy

### Nginx Configuration

```nginx
upstream svn_backend {
    server svn-ldap:80;
}

server {
    listen 80;
    server_name svn.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name svn.example.com;
    
    ssl_certificate /etc/nginx/ssl/svn.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/svn.example.com.key;
    
    # Important for large commits
    client_max_body_size 100M;
    
    # Timeouts for long operations
    proxy_connect_timeout 600;
    proxy_send_timeout 600;
    proxy_read_timeout 600;
    
    location / {
        proxy_pass http://svn_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Critical for SVN operations
        proxy_set_header Destination $http_destination;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

### Traefik Configuration

```yaml
services:
  svn:
    image: yourusername/svn-ldap:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.svn.rule=Host(`svn.example.com`)"
      - "traefik.http.routers.svn.entrypoints=websecure"
      - "traefik.http.routers.svn.tls.certresolver=letsencrypt"
      - "traefik.http.services.svn.loadbalancer.server.port=80"
    environment:
      - BehindSSLProxy=true
```

## 📚 Usage Examples

### Basic SVN Operations

```bash
# Checkout repository
svn checkout http://svn.example.com/svn/repository myproject

# Add files
cd myproject
echo "Hello World" > README.md
svn add README.md

# Commit changes
svn commit -m "Initial commit"

# Update from repository
svn update

# Check status
svn status

# View log
svn log
```

### Creating Additional Repositories

```bash
# Access container
docker exec -it svn-ldap bash

# Create new repository
svnadmin create /var/svn/newproject

# Create standard directory structure
svn mkdir -m "Initial structure" \
  file:///var/svn/newproject/trunk \
  file:///var/svn/newproject/branches \
  file:///var/svn/newproject/tags

# Access it at: http://svn.example.com/svn/newproject
```

### Backup and Restore

```bash
# Backup repository
docker exec svn-ldap svnadmin dump /var/svn/repository > backup-$(date +%Y%m%d).dump

# Restore repository
cat backup-20240101.dump | docker exec -i svn-ldap svnadmin load /var/svn/repository

# Incremental backup
docker exec svn-ldap svnadmin dump /var/svn/repository --incremental \
  --revision 100:HEAD > incremental-backup.dump
```

### Repository Maintenance

```bash
# Verify repository integrity
docker exec svn-ldap svnadmin verify /var/svn/repository

# Pack repository (optimize storage)
docker exec svn-ldap svnadmin pack /var/svn/repository

# View repository info
docker exec svn-ldap svnlook info /var/svn/repository

# View youngest revision
docker exec svn-ldap svnlook youngest /var/svn/repository
```

## 🐛 Troubleshooting

### Authentication Fails

**Problem:** Users cannot authenticate

**Solutions:**
1. Test LDAP connection from container:
   ```bash
   docker exec -it svn-ldap bash
   apt-get update && apt-get install -y ldap-utils
   ldapsearch -x -H "$AuthLDAPURL" -D "$AuthLDAPBindDN" -w "$AuthLDAPBindPassword" -b "$LDAPBaseDN" "(uid=testuser)"
   ```

2. Check Apache logs:
   ```bash
   docker logs svn-ldap
   docker exec svn-ldap tail -f /usr/local/apache2/logs/error_log
   ```

3. Verify LDAP group membership:
   - Ensure user is member of `RequireLDAPGroup`
   - Check group DN format matches your LDAP schema

### 502 Bad Gateway on COPY/MOVE Operations

**Problem:** SVN copy/move/branch operations fail with 502 error

**Solution:** Ensure `BehindSSLProxy=true` is set when using HTTPS reverse proxy

```yaml
environment:
  - BehindSSLProxy=true
```

### Permission Denied Errors

**Problem:** Cannot commit changes

**Solutions:**
1. Check repository permissions:
   ```bash
   docker exec svn-ldap ls -la /var/svn/repository
   docker exec svn-ldap chown -R daemon:daemon /var/svn/repository
   ```

2. Verify LDAP authorization in logs

### Large File Upload Fails

**Problem:** Commits fail for large files

**Solutions:**
1. Increase nginx client_max_body_size:
   ```nginx
   client_max_body_size 500M;
   ```

2. Increase timeouts:
   ```nginx
   proxy_read_timeout 3600;
   proxy_send_timeout 3600;
   ```

### Container Crashes on Startup

**Problem:** Container exits immediately

**Solutions:**
1. Check logs:
   ```bash
   docker logs svn-ldap
   ```

2. Verify environment variables are set correctly

3. Test configuration:
   ```bash
   docker run --rm -it yourusername/svn-ldap:latest bash
   httpd -t
   ```

## 🔍 Monitoring and Logs

### View Logs

```bash
# Container logs
docker logs -f svn-ldap

# Apache access log
docker exec svn-ldap tail -f /usr/local/apache2/logs/access_log

# Apache error log
docker exec svn-ldap tail -f /usr/local/apache2/logs/error_log
```

### Health Check

Add to `docker-compose.yml`:

```yaml
services:
  svn:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## 🏗️ Building from Source

```bash
# Clone repository
git clone https://github.com/yourusername/svn-ldap-docker.git
cd svn-ldap-docker

# Build image
docker build -t mycompany/svn-ldap:custom .

# Or with docker-compose
docker-compose build
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

Based on [Edirom/subversion-ldap-httpd](https://github.com/Edirom/subversion-ldap-httpd) with improvements for better configurability and production use.

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/svn-ldap-docker/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/svn-ldap-docker/discussions)
- **Docker Hub:** [yourusername/svn-ldap](https://hub.docker.com/r/yourusername/svn-ldap)

## 🗺️ Roadmap

- [ ] Add support for custom authz files
- [ ] Multi-architecture builds (ARM support)
- [ ] Prometheus metrics endpoint
- [ ] Automated backup scheduling
- [ ] Web UI for repository browsing
- [ ] Git-SVN bridge support

---

**Made with ❤️ for the SVN community**
