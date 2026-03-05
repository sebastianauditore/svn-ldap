FROM httpd:2.4

# Install subversion and LDAP modules
RUN apt-get update && \
    apt-get install -y \
        subversion \
        libapache2-mod-svn \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Enable the config
RUN echo "Include conf/extra/vife.conf" >> /usr/local/apache2/conf/httpd.conf

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["httpd-foreground"]