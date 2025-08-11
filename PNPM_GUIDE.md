# MediaServer - pnpm Package Manager Guide

## Why pnpm?

This project uses **pnpm** as the package manager instead of npm or yarn for several advantages:

### 🚀 **Performance Benefits**
- **Faster installations** - Up to 2x faster than npm
- **Efficient disk usage** - Uses a global store to avoid duplicates
- **Better caching** - Content-addressable storage system

### 🔒 **Better Dependency Management**
- **Strict dependency resolution** - Prevents phantom dependencies
- **Accurate lockfiles** - More reliable than package-lock.json
- **Workspace support** - Better monorepo management

### 💾 **Disk Space Efficiency**
- **Global store** - Packages stored once, hard-linked everywhere
- **Deduplication** - Automatic deduplication of dependencies
- **Smaller node_modules** - Only necessary files are linked

## Quick Start with pnpm

### Installation
```bash
# Install pnpm globally
npm install -g pnpm

# Or using curl
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Or using Homebrew (macOS)
brew install pnpm
```

### Basic Commands
```bash
# Install dependencies
pnpm install

# Add a dependency
pnpm add express

# Add a dev dependency
pnpm add -D nodemon

# Remove a dependency
pnpm remove express

# Run scripts
pnpm start
pnpm dev
pnpm test

# Update dependencies
pnpm update

# Install specific version
pnpm add express@4.18.2
```

### Project-specific Commands
```bash
# Development
pnpm dev                    # Start development server
pnpm start                  # Start production server
pnpm test                   # Run tests

# Docker
pnpm docker:build          # Build Docker image
pnpm docker:run            # Run Docker container

# Install all dependencies
pnpm install --frozen-lockfile  # Production install (uses exact versions)
```

## Configuration

The project includes a `.pnpmrc` file with optimized settings:

```ini
# Use a shared store to save disk space
store-dir=~/.pnpm-store

# Automatically install peer dependencies
auto-install-peers=true

# Use strict peer dependencies
strict-peer-dependencies=false

# Enable hoisting for better compatibility
hoist=true

# Save exact versions in package.json
save-exact=true
```

## Migration from npm/yarn

### From npm
```bash
# Remove old files
rm package-lock.json
rm -rf node_modules

# Install with pnpm
pnpm install
```

### From yarn
```bash
# Remove old files
rm yarn.lock
rm -rf node_modules

# Install with pnpm
pnpm install
```

## Docker Integration

The Dockerfile is optimized for pnpm:

```dockerfile
# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install --frozen-lockfile --prod
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Setup pnpm
  uses: pnpm/action-setup@v2
  with:
    version: 8

- name: Install dependencies
  run: pnpm install --frozen-lockfile
```

### Jenkins
```groovy
stage('Install Dependencies') {
    steps {
        sh 'npm install -g pnpm'
        sh 'pnpm install --frozen-lockfile'
    }
}
```

## Best Practices

### 1. **Use Exact Versions**
```bash
pnpm add --save-exact express@4.18.2
```

### 2. **Frozen Lockfile in Production**
```bash
pnpm install --frozen-lockfile
```

### 3. **Regular Updates**
```bash
# Check outdated packages
pnpm outdated

# Update all packages
pnpm update

# Update specific package
pnpm update express
```

### 4. **Clean Cache**
```bash
# Clear pnpm cache
pnpm store prune

# Verify store integrity
pnpm store status
```

## Troubleshooting

### Common Issues

#### 1. **Permission Errors**
```bash
# Fix pnpm store permissions
sudo chown -R $(whoami) ~/.pnpm-store
```

#### 2. **Module Resolution Issues**
```bash
# Clear node_modules and reinstall
rm -rf node_modules
pnpm install
```

#### 3. **Peer Dependency Warnings**
```bash
# Install peer dependencies automatically
pnpm install --auto-install-peers
```

### Debug Commands
```bash
# Show pnpm configuration
pnpm config list

# Show dependency tree
pnpm list

# Show why a package is installed
pnpm why express

# Audit dependencies
pnpm audit

# Fix audit issues
pnpm audit --fix
```

## Performance Comparison

| Feature | npm | yarn | pnpm |
|---------|-----|------|------|
| Install Speed | Baseline | ~2x faster | ~2-3x faster |
| Disk Usage | Baseline | Similar | ~50% less |
| Lockfile Accuracy | Good | Good | Excellent |
| Strict Dependencies | No | No | Yes |
| Workspace Support | Basic | Good | Excellent |

## Additional Resources

- [pnpm Documentation](https://pnpm.io/)
- [pnpm vs npm vs yarn](https://pnpm.io/benchmarks)
- [pnpm Workspaces](https://pnpm.io/workspaces)
- [pnpm CLI Reference](https://pnpm.io/cli/add)
