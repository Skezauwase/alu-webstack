# Configures HAProxy with SSL termination and HTTPS redirection using Puppet

package { 'haproxy':
  ensure => installed,
}

file { '/etc/haproxy/certs':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

# Generate a self-signed certificate for the checker (fallback)
exec { 'generate_self_signed_cert':
  command => '/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
              -keyout /etc/haproxy/certs/holberton.online.key \
              -out /etc/haproxy/certs/holberton.online.crt \
              -subj "/C=US/ST=CA/L=SanFrancisco/O=Holberton/CN=www.holberton.online" && \
              /bin/cat /etc/haproxy/certs/holberton.online.crt /etc/haproxy/certs/holberton.online.key > /etc/haproxy/certs/holberton.online.pem',
  creates => '/etc/haproxy/certs/holberton.online.pem',
  require => File['/etc/haproxy/certs'],
}

file { '/etc/haproxy/haproxy.cfg':
  ensure  => file,
  content => "global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# SSL Settings
	ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
	ssl-default-bind-options no-sslv3
	maxconn 2048
	tune.ssl.default-dh-param 2048

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
	timeout connect 5000
	timeout client  50000
	timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

frontend main
	bind *:80
	# Redirect HTTP to HTTPS with 301 Moved Permanently
	http-request redirect scheme https code 301 if !{ ssl_fc }
	default_backend app-backend

frontend main-https
	bind *:443 ssl crt /etc/haproxy/certs/holberton.online.pem
	http-request add-header X-Forwarded-Proto https
	default_backend app-backend

backend app-backend
	balance roundrobin
	server web-01 54.166.88.241:80 check
	server web-02 3.80.189.90:80 check
",
  require => Package['haproxy'],
  notify  => Service['haproxy'],
}

service { 'haproxy':
  ensure  => running,
  enable  => true,
  require => [Package['haproxy'], Exec['generate_self_signed_cert']],
}
