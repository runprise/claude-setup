---
name: deploy
description: Review Dockerfile and docker-compose.yml for production readiness
disable-model-invocation: true
---
Review and optimize the Docker configuration in this project for Coolify deployment:

1. **Dockerfile Analysis**:
   - Check for multi-stage build pattern
   - Verify non-root user is configured
   - Check .dockerignore exists and covers node_modules, .git, .env
   - Validate health check is defined
   - Check for proper SIGTERM handling

2. **docker-compose.yml Analysis**:
   - Verify environment variables use ${} syntax (Coolify-compatible)
   - Check resource limits are defined
   - Validate volume mounts for persistent data
   - Check network configuration
   - Verify restart policy

3. **Security Check**:
   - No secrets in Dockerfile or docker-compose.yml
   - Base images are pinned to specific versions
   - No unnecessary ports exposed

4. **Optimization**:
   - Layer caching optimized (dependencies before source code)
   - Final image size minimized (alpine/slim base, no dev dependencies)
   - Build args used for dynamic values

Report findings and suggest fixes for any issues found.
