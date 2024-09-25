# Linux-Maintenance-Script
A comprehensive Bash script designed to perform various maintenance tasks on a Linux server. The script automates system updates, security scans, performance monitoring, backup routines, Docker maintenance, firewall checks, and more.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration](#configuration)
- [Warnings](#warnings)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Distribution Compatibility**: Supports Debian-based, Red Hat-based, SUSE-based, and Arch Linux systems.
- **Notification System**:
  - Sends email notifications for critical warnings or errors.
  - Uses `mailx` or `sendmail` to send logs to administrators.
- **Automated Backups**:
  - Performs backups of critical data before maintenance.
  - Stores backups in a date-stamped directory.
- **Docker and Container Support**:
  - Checks and performs maintenance on Docker containers and images.
  - Removes unused containers, images, volumes, and networks.
- **Firewall and Security Enhancements**:
  - Checks firewall status and configurations (`ufw`, `firewalld`).
  - Integrates with `fail2ban` for intrusion prevention.
- **Scheduler Integration**:
  - Can be run automatically via `cron` in non-interactive mode.
  - Skips user prompts when running non-interactively.
- **Security Updates and Scans**:
  - Performs security updates using appropriate tools.
  - Installs and runs Lynis for security auditing.
- **System Monitoring**:
  - Monitors CPU, memory, and disk usage.
  - Logs warnings if usage exceeds thresholds.
  - Generates detailed system performance reports.
- **Advanced Checks**:
  - Checks for failed services, zombie processes, full file systems, and hardware errors.
- **Maintenance Tasks**:
  - **System Updates**: Updates and upgrades system packages.
  - **Package Cleanup**: Removes unnecessary packages and cleans package caches.
  - **Cleanup Tasks**: Cleans up temporary files and old logs.
- **Logging**:
  - Enhanced logging with log levels and timestamps.
  - Archives logs older than 30 days.
  - Logs are stored in `/var/log/maintenance/`.

## Prerequisites

- **Root Privileges**: Must be run as root or with `sudo`.
- **Supported Linux Distribution**: Debian/Ubuntu, CentOS/RHEL/Fedora, SUSE, Arch Linux.
- **Internet Connection**: Required for updates and installing tools.
- **Utilities**:
  - `mailx` or `sendmail` for email notifications.
  - `bc`, `awk`, `grep`, `sed`, `ps`, `df`, `free`, `netstat`, `tar`, `docker` (optional).

## Usage

### Clone the Repository

```bash
git clone https://github.com/envisational/Linux-Maintenance-Script.git
```
### Navigate to the Directory

```bash
cd Linux-Maintenance-Script
```

### Make the Script Executable

```bash
chmod +x maintenance.sh
```

### Configure the Script

-   Edit the script to set the `ADMIN_EMAIL` variable with your email address.

```bash
ADMIN_EMAIL="admin@example.com"
```

### Run the Script as Root

Interactive Mode:

```bash
sudo ./maintenance.sh
```

Non-Interactive Mode (e.g., via cron):

-   Add the script to the crontab:

```bash
sudo crontab -e
```

-   Add the following line to run the script daily at 2 AM:

```bash
0 2 * * * /path/to/maintenance.sh
```

Configuration
-------------

-   **Email Notifications**: Ensure `mailx` or `sendmail` is installed and configured to send emails.
-   **Backup Directories**: Modify the `automated_backup` function to include directories you wish to back up.
-   **Docker Maintenance**: Adjust Docker maintenance tasks as needed for your environment.

Warnings
--------

-   **Data Loss Risk**: Be cautious with cleanup and backup routines. Ensure critical data is properly backed up.
-   **System Performance**: Maintenance tasks may consume resources. Schedule the script during off-peak hours.
-   **Email Configuration**: Email notifications require a configured MTA (Mail Transfer Agent).

Customization
-------------

-   **Enable/Disable Tasks**: Comment out or adjust functions to include or exclude specific tasks.
-   **Adjust Thresholds**: Modify thresholds for CPU, memory, and disk usage warnings.
-   **Add or Remove Checks**: Customize the script to include additional checks relevant to your environment.
-   **Logging Settings**: Adjust log retention periods or log file locations.

Contributing
------------

Contributions are welcome! Please open an issue or submit a pull request with suggestions or improvements.

License
-------

This project is licensed under the MIT License. See the <LICENSE> file for details.
