# Security Architecture Checklist

Use this when reviewing the security posture of a system or planning a new deployment. Not every item applies to every system — scope the review to what's relevant.

## Authentication & Authorization

- [ ] Authentication is handled by a well-tested library or service, not hand-rolled
- [ ] Passwords are hashed with bcrypt, scrypt, or argon2 (never MD5/SHA without salt)
- [ ] Multi-factor authentication is available for privileged accounts
- [ ] Session tokens are cryptographically random, expire, and can be revoked
- [ ] JWT tokens (if used) have short expiry, are validated properly (algorithm, issuer, audience), and refresh tokens are stored securely
- [ ] Authorization checks happen on every request, server-side, not just in the UI
- [ ] Role/permission model follows least privilege
- [ ] Service-to-service auth uses mutual TLS or signed tokens, not shared secrets

## Input Validation & Injection

- [ ] All user input is validated at the trust boundary (type, length, format, range)
- [ ] SQL queries use parameterized statements, never string concatenation
- [ ] HTML output is escaped to prevent XSS (use framework defaults, don't bypass them)
- [ ] File uploads are validated (type, size, content) and stored outside the webroot
- [ ] Deserialization of untrusted data uses safe parsers (no `eval`, no `pickle` from user input)
- [ ] GraphQL queries are depth-limited and complexity-bounded
- [ ] API rate limiting is in place for all public endpoints

## Secrets Management

- [ ] No secrets in source code, environment variables in containers, or config files committed to git
- [ ] Secrets are stored in a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager, etc.)
- [ ] Credentials are rotated on a schedule and can be rotated immediately in an incident
- [ ] Access to secrets is audited
- [ ] Different environments (dev, staging, prod) use different credentials
- [ ] CI/CD secrets are scoped to the pipelines that need them

## Data Protection

- [ ] Sensitive data is classified (PII, PHI, financial, credentials)
- [ ] Data at rest is encrypted (database, backups, object storage)
- [ ] Data in transit uses TLS 1.2+ (no fallback to plaintext)
- [ ] PII has a defined retention policy and deletion process
- [ ] Database backups are encrypted and access-controlled
- [ ] Logs do not contain sensitive data (passwords, tokens, PII) — use structured logging with field redaction

## Infrastructure

- [ ] Network segmentation separates public-facing, application, and data tiers
- [ ] Default-deny firewall rules (only open what's explicitly needed)
- [ ] SSH access uses key-based auth, not passwords; root login is disabled
- [ ] Container images use minimal base images, are scanned for vulnerabilities, and don't run as root
- [ ] Dependencies are pinned and scanned for known CVEs (Dependabot, Snyk, Trivy, etc.)
- [ ] Infrastructure is defined as code and changes go through review

## Monitoring & Incident Response

- [ ] Security-relevant events are logged (auth failures, permission denials, admin actions)
- [ ] Alerts exist for anomalous patterns (brute force, privilege escalation, unusual data access)
- [ ] There's an incident response plan that's been tested (even if it's simple)
- [ ] You know how to revoke compromised credentials and rotate them quickly
- [ ] CORS, CSP, and other security headers are configured and tested

## Third-Party Dependencies

- [ ] Dependencies are reviewed before adoption (see technology-evaluation.md)
- [ ] Supply chain attacks are mitigated (lock files, checksum verification, private registries)
- [ ] Third-party scripts (analytics, CDN) use subresource integrity (SRI) where possible
- [ ] OAuth integrations request minimal scopes

## Common Oversights

These are the things that tend to get missed:

- **IDOR (Insecure Direct Object References)**: Every API endpoint that takes an ID must verify the caller has access to that object. This is the #1 most common vulnerability in web apps.
- **Mass assignment**: ORMs that auto-bind request parameters to model fields can allow privilege escalation. Whitelist assignable fields explicitly.
- **Race conditions**: TOCTOU bugs in authorization checks, double-spend in financial operations, concurrent writes without proper locking.
- **Error messages leaking information**: Stack traces, database errors, or detailed auth failure reasons exposed to clients.
- **Subdomain takeover**: Dangling DNS records pointing to deprovisioned cloud resources.
- **Overly permissive CORS**: `Access-Control-Allow-Origin: *` on authenticated endpoints.
