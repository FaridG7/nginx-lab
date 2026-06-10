# nginx-lab

A local development lab for learning and experimenting with production-grade Nginx configuration — containerized with Docker and served over HTTPS with a self-signed certificate.

Built around the [h5bp/server-configs-nginx](https://github.com/h5bp/server-configs-nginx) reference configuration, this project explores security headers, TLS setup, virtual hosting, and web performance best practices hands-on.

---

## What this project covers

**TLS / HTTPS**
Setting up a self-signed certificate with OpenSSL, configuring SSL session caching, OCSP stapling, and choosing between strict and balanced TLS policies.

**Security headers**
Applying the full modern security header stack: `Content-Security-Policy`, `Permissions-Policy`, `Referrer-Policy`, `Strict-Transport-Security`, `X-Frame-Options`, `X-Content-Type-Options`, and Cross-Origin policies (COEP / COOP / CORP).

**Virtual hosting**
Configuring named virtual hosts (`nginx-lab.local`), handling www → non-www redirects, HTTP → HTTPS redirects, and dropping requests for unknown hosts with a `444` default server.

**Web performance**
Gzip compression with fine-grained MIME-type targeting, far-future cache expiration via `expires` maps, `Cache-Control` directives per content type, file descriptor caching, and pre-compressed content support.

**Docker integration**
Wiring Nginx into a Docker Compose setup with volume mounts for both the config directory and the web root, making config changes instantly testable without rebuilding the image.

---

## Project structure

```
.
├── docker-compose.yml         # Spins up Nginx on ports 80 and 443
├── setup-cert.sh              # Generates a self-signed TLS certificate
├── nginx/
│   ├── nginx.conf             # Main config: workers, logging, http-block maps
│   ├── mime.types             # Comprehensive MIME type table
│   ├── conf.d/
│   │   ├── default.conf       # Drop-all default server (host-header attack protection)
│   │   ├── nginx-lab.local.conf   # Lab virtual host (HTTP→HTTPS + www redirect)
│   │   ├── no-ssl.default.conf    # Non-SSL drop-all fallback
│   │   └── templates/         # Reusable server block templates
│   └── h5bp/                  # Modular config snippets (security, TLS, performance)
│       ├── basic.conf
│       ├── security/
│       ├── tls/
│       ├── web_performance/
│       ├── media_types/
│       ├── cross-origin/
│       ├── errors/
│       └── location/
└── nginx-lab.local/
    └── public/
        └── index.html         # Demo static site (photographer portfolio)
```

---

## Quick start

**Prerequisites:** Docker, Docker Compose, and OpenSSL.

```bash
# 1. Clone the repository
git clone https://github.com/FaridG7/nginx-lab.git
cd nginx-lab

# 2. Generate the self-signed TLS certificate
chmod +x setup-cert.sh
./setup-cert.sh

# 3. Add the local hostname to /etc/hosts
echo "127.0.0.1  nginx-lab.local www.nginx-lab.local" | sudo tee -a /etc/hosts

# 4. Start the container
docker compose up -d
```

Then open [https://nginx-lab.local](https://nginx-lab.local) in your browser.
Accept the browser warning for the self-signed certificate (expected in local development).

**Verify the config without restarting:**
```bash
docker compose exec web nginx -t
docker compose exec web nginx -s reload
```

---

## Key configuration decisions

### Default server drops unknown hosts
Any request arriving with an unrecognized `Host` header is dropped silently with a `444 No Response`. This prevents host-header injection attacks and is a recommended production practice.

```nginx
server {
  listen [::]:443 ssl default_server;
  server_name _;
  return 444;
}
```

### Security headers are MIME-type aware
Rather than applying security headers globally (which can interfere with APIs and assets), headers are set via `map` blocks keyed on `$sent_http_content_type`. This means `Content-Security-Policy` only fires on HTML and JavaScript responses, not on images or fonts.

### TLS policy: balanced vs. strict
Two TLS profiles are available under `h5bp/tls/`:
- `policy_balanced.conf` — TLSv1.2 only, supports a wider range of clients including Edge and Safari
- `policy_strict.conf` — TLSv1.2 + TLSv1.3 with X25519 only; highest security, may reject older clients

The lab uses the balanced policy. Switching is a one-line include change.

### Cache-Control per content type
Static assets (images, fonts, JS, CSS) are served with `immutable` and a 1-year expiry. HTML documents use `private, must-revalidate`. JSON and XML responses get `no-cache`. All of this is driven by a single `map` block in `nginx.conf`.

---

## What I learned

This project was built as a learning exercise to go beyond basic Nginx tutorials and understand how a well-structured production configuration actually works. Key takeaways:

- The difference between `nginx.conf` (global/http context) and `conf.d/` (server context) and why mixing them causes subtle bugs
- Why `add_header` in a child `location` block silently drops all headers inherited from the parent — and how to structure configs to avoid this
- How `map` blocks enable conditional header logic without using `if` (which Nginx docs explicitly warn against)
- The trust model behind HSTS: once sent, a browser enforces it strictly, so `max-age` and `includeSubDomains` require deliberate commitment
- How OCSP stapling moves certificate validation out of the client's TLS handshake and onto the server, reducing latency and improving privacy

---

## Technologies

| Tool | Role |
|------|------|
| Nginx 1.8+ | Web server and reverse proxy |
| Docker / Docker Compose | Local containerized environment |
| OpenSSL | Self-signed certificate generation |
| h5bp/server-configs-nginx | Reference configuration baseline |
| HTML / CSS | Demo static site served by the lab |

---

## Possible extensions

- Add a second virtual host to practice multi-site setups
- Swap the self-signed cert for a locally-trusted cert using [mkcert](https://github.com/FiloSottile/mkcert)
- Configure Nginx as a reverse proxy in front of a local app server
- Add rate limiting (`limit_req_zone`) and explore DoS mitigation
- Test the security header configuration against [securityheaders.com](https://securityheaders.com) or Mozilla Observatory

---

## References

- [Nginx documentation](https://nginx.org/en/docs/)
- [h5bp/server-configs-nginx](https://github.com/h5bp/server-configs-nginx)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)
- [MDN: HTTP Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)

---

## License

The Nginx configuration files in `nginx/` are derived from [h5bp/server-configs-nginx](https://github.com/h5bp/server-configs-nginx) and are released under the [MIT License](nginx/LICENSE.txt).
