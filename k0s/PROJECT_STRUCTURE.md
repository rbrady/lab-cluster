# k0s Ansible Project Structure

This document provides an overview of the project structure and explains the purpose of each file.

## Directory Structure

```
k0s/
├── playbook.yml                      # Main Ansible playbook
├── inventory.ini                     # Inventory file (localhost by default)
├── ansible.cfg                       # Ansible configuration
├── Makefile                          # Convenient command shortcuts
├── uninstall.yml                     # Uninstall playbook
├── vars.example.yml                  # Example variables file
├── README.md                         # Complete documentation
├── QUICKSTART.md                     # Quick start guide
├── PROJECT_STRUCTURE.md              # This file
├── .gitignore                        # Git ignore rules
└── roles/
    └── k0s/
        ├── defaults/
        │   └── main.yml              # Default variables
        ├── handlers/
        │   └── main.yml              # Service restart handlers
        ├── tasks/
        │   ├── main.yml              # Main task orchestration
        │   ├── preflight.yml         # System requirement checks
        │   ├── prerequisites.yml     # System preparation
        │   ├── install.yml           # k0s binary installation
        │   ├── configure.yml         # k0s configuration
        │   ├── service.yml           # Service management
        │   └── verify.yml            # Post-install verification
        └── templates/
            └── k0s.yaml.j2           # k0s configuration template
```

## File Descriptions

### Root Level Files

#### `playbook.yml`
The main Ansible playbook that orchestrates the k0s installation. It:
- Targets hosts defined in the `k0s_nodes` group
- Applies the k0s role
- Displays cluster status upon completion

#### `inventory.ini`
Defines the target hosts for Ansible. By default, it's configured for localhost installation:
- Sets `k0s_nodes` group with localhost
- Uses local connection for faster execution
- Configures Python interpreter path

#### `ansible.cfg`
Ansible configuration file that sets:
- Default inventory location
- Output formatting (YAML)
- Performance optimizations
- Logging settings
- SSH connection parameters

#### `Makefile`
Provides convenient shortcuts for common operations:
- `make install` - Run the installation
- `make uninstall` - Remove k0s
- `make status` - Check cluster status
- `make logs` - View service logs
- `make verify` - Verify installation
- And many more useful commands

#### `uninstall.yml`
Complete uninstallation playbook that:
- Stops and disables k0s service
- Runs k0s reset command
- Removes binaries, configs, and data
- Cleans up firewall rules
- Removes systemd service files

#### `vars.example.yml`
Comprehensive example of customizable variables:
- k0s version selection
- Network configuration
- Feature flags
- Resource limits
- Comments explaining each option

#### `README.md`
Complete documentation including:
- Installation instructions
- Configuration options
- Troubleshooting guide
- Common operations
- Resource considerations for limited hardware

#### `QUICKSTART.md`
Step-by-step quick start guide:
- Prerequisites check
- Installation steps
- First commands to run
- Deploy your first app
- Troubleshooting basics

#### `.gitignore`
Excludes from version control:
- Ansible retry files and logs
- Kubeconfig files
- Local variables (vars.yml)
- Backup and temporary files
- IDE configuration

### Role: k0s

The k0s role is organized following Ansible best practices.

#### `defaults/main.yml`
Default variables that can be overridden:
- **k0s_version**: Version to install (default: latest)
- **k0s_install_dir**: Binary installation path
- **k0s_config_dir**: Configuration directory
- **k0s_data_dir**: Data storage location
- **k0s_enable_controller**: Enable controller (true for single-node)
- **k0s_enable_worker**: Enable worker (true for single-node)
- **k0s_configure_firewall**: Auto-configure firewall rules
- **k0s_firewall_ports**: List of ports to open
- **k0s_selinux_permissive**: SELinux mode setting
- **k0s_config**: Nested configuration for k0s cluster
- **k0s_enable_metrics_server**: Enable resource monitoring

#### `handlers/main.yml`
Service management handlers triggered by task changes:
- **restart k0s**: Restarts the k0s service
- **reload firewalld**: Reloads firewall configuration
- **stop k0s**: Stops the k0s service
- **start k0s**: Starts the k0s service

#### `tasks/main.yml`
Main task orchestration that includes:
1. Preflight checks
2. Prerequisites installation
3. k0s binary installation
4. Configuration generation
5. Service startup
6. Verification

#### `tasks/preflight.yml`
Pre-installation system checks:
- Gather system facts (RAM, CPU, OS)
- Display system information
- Verify architecture compatibility
- Check minimum requirements
- Detect existing k0s installation
- Verify systemd availability

#### `tasks/prerequisites.yml`
System preparation tasks:
- Update package cache
- Install required packages (curl, iptables, etc.)
- Configure firewall rules (if firewalld is active)
- Set SELinux to permissive mode
- Enable IP forwarding
- Load br_netfilter kernel module
- Configure bridge networking for Kubernetes
- Create k0s directories

#### `tasks/install.yml`
k0s binary installation:
- Check for existing installation
- Download k0s installation script
- Install k0s (latest or specific version)
- Verify binary installation
- Set proper permissions
- Display installed version

#### `tasks/configure.yml`
k0s cluster configuration:
- Generate configuration from template
- Validate configuration file
- Check service status
- Install k0s as controller+worker
- Update configuration if changed
- Trigger service restart if needed

#### `tasks/service.yml`
Service management:
- Enable k0s systemd service
- Start k0s service
- Wait for API server to be ready
- Display service status

#### `tasks/verify.yml`
Post-installation verification:
- Wait for node to be ready
- Display node information
- Show system pods status
- Verify API endpoint health
- Export kubeconfig for user access
- Display verification summary

#### `templates/k0s.yaml.j2`
Jinja2 template for k0s configuration:
- API server settings (address, port, SANs)
- Storage configuration (etcd)
- Network settings (provider, CIDRs)
- Pod security policies
- Telemetry settings
- Extensions configuration (Helm repos, metrics-server)
- Konnectivity settings

## Execution Flow

1. **Playbook Start** (`playbook.yml`)
   - Reads inventory and variables
   - Applies k0s role

2. **Preflight Checks** (`tasks/preflight.yml`)
   - Validates system meets requirements
   - Displays warnings if resources are limited

3. **Prerequisites** (`tasks/prerequisites.yml`)
   - Installs dependencies
   - Configures system (firewall, SELinux, networking)

4. **Installation** (`tasks/install.yml`)
   - Downloads and installs k0s binary

5. **Configuration** (`tasks/configure.yml`)
   - Generates k0s.yaml from template
   - Installs k0s service

6. **Service Start** (`tasks/service.yml`)
   - Starts k0scontroller service
   - Waits for API server

7. **Verification** (`tasks/verify.yml`)
   - Confirms cluster is healthy
   - Exports kubeconfig

8. **Completion**
   - Displays cluster status
   - Shows next steps

## Customization

### Override Default Variables

Create a `vars.yml` file:

```yaml
---
k0s_version: v1.29.1+k0s.0
k0s_enable_metrics_server: true
```

Run with:
```bash
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

### Remote Installation

Modify `inventory.ini`:

```ini
[k0s_nodes]
192.168.1.100 ansible_user=fedora ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Multi-Node Setup (Future)

For multi-node clusters, you can extend this playbook by:
1. Creating separate controller and worker groups
2. Generating join tokens on controllers
3. Using tokens to join workers

## Dependencies

### System Requirements
- Fedora 42 (or similar RHEL-based OS)
- systemd init system
- 1GB+ RAM (2GB+ recommended)
- 1+ CPU cores (2+ recommended)
- x86_64 or aarch64 architecture

### Ansible Requirements
- Ansible 2.9+
- Python 3.6+
- Required Ansible modules (included in base):
  - ansible.builtin.dnf
  - ansible.builtin.systemd
  - ansible.builtin.firewalld
  - ansible.builtin.selinux
  - ansible.builtin.command
  - ansible.builtin.template
  - ansible.builtin.file

## Troubleshooting Files

When troubleshooting, check:

1. **Ansible log**: `./ansible.log`
2. **k0s service logs**: `sudo journalctl -u k0scontroller`
3. **k0s status**: `sudo k0s status`
4. **Configuration**: `/etc/k0s/k0s.yaml`

## Maintenance

### Updating k0s

To update to a newer version:

```bash
# Set new version in vars.yml
echo "k0s_version: v1.30.0+k0s.0" > vars.yml

# Re-run playbook
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

### Backup

Important files to backup:
- `/etc/k0s/k0s.yaml` - Configuration
- `/var/lib/k0s/` - Cluster data (especially etcd)
- Kubeconfig files

## Testing

### Syntax Check
```bash
ansible-playbook --syntax-check playbook.yml
```

### Dry Run
```bash
ansible-playbook -i inventory.ini playbook.yml --check
```

### Using Makefile
```bash
make check          # Run preflight checks
make install-dry    # Dry run installation
make install        # Full installation
make verify         # Verify installation
```

## Contributing

When extending this playbook:

1. Follow Ansible best practices
2. Keep tasks idempotent
3. Add appropriate error handling
4. Update documentation
5. Test on target platform (Fedora 42)
6. Consider resource constraints (4GB RAM)

## License

This project is provided as-is for educational purposes.

## References

- [k0s Documentation](https://docs.k0sproject.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)