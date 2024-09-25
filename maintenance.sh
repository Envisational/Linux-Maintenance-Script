#!/bin/bash
# maintenance.sh - Comprehensive Linux Server Maintenance Script

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run with sudo."
    exit 1
fi

# Set up logging
LOG_DIR="/var/log/maintenance"
LOG_FILE="$LOG_DIR/maintenance_$(date '+%Y%m%d').log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Notification email
ADMIN_EMAIL="admin@example.com"

# Set non-interactive mode if running via cron
if [[ -z $PS1 ]]; then
    NON_INTERACTIVE=true
else
    NON_INTERACTIVE=false
fi

# Function to write logs with log levels
log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIMESTAMP [$LEVEL] $MESSAGE" | tee -a "$LOG_FILE"
    if [[ "$LEVEL" == "ERROR" ]] || [[ "$LEVEL" == "WARNING" ]]; then
        send_notification "$LEVEL" "$MESSAGE"
    fi
}

# Function to send email notifications
send_notification() {
    local LEVEL="$1"
    local MESSAGE="$2"
    if command -v mailx &> /dev/null; then
        echo "$MESSAGE" | mailx -s "[$HOSTNAME] Maintenance Script $LEVEL Alert" "$ADMIN_EMAIL"
    elif command -v sendmail &> /dev/null; then
        echo -e "Subject: [$HOSTNAME] Maintenance Script $LEVEL Alert\n\n$MESSAGE" | sendmail "$ADMIN_EMAIL"
    else
        log "INFO" "No mail utility found. Unable to send email notification."
    fi
}

# Function to archive old logs
archive_old_logs() {
    find "$LOG_DIR" -type f -name "maintenance_*.log" -mtime +30 -exec rm {} \;
}

# Function to detect Linux distribution and set package manager commands
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO=$(uname -s)
    fi

    case "$DISTRO" in
        ubuntu|debian)
            PKG_UPDATE="apt-get update"
            PKG_UPGRADE="apt-get upgrade -y"
            PKG_CLEAN="apt-get autoclean -y && apt-get autoremove -y"
            PKG_INSTALL="apt-get install -y"
            ;;
        centos|rhel|fedora)
            PKG_UPDATE="yum check-update"
            PKG_UPGRADE="yum update -y"
            PKG_CLEAN="yum clean all"
            PKG_INSTALL="yum install -y"
            ;;
        opensuse|suse)
            PKG_UPDATE="zypper refresh"
            PKG_UPGRADE="zypper update -y"
            PKG_CLEAN="zypper clean --all"
            PKG_INSTALL="zypper install -y"
            ;;
        arch)
            PKG_UPDATE="pacman -Sy"
            PKG_UPGRADE="pacman -Syu --noconfirm"
            PKG_CLEAN="pacman -Sc --noconfirm"
            PKG_INSTALL="pacman -S --noconfirm"
            ;;
        *)
            log "ERROR" "Unsupported Linux distribution."
            exit 1
            ;;
    esac
    log "INFO" "Detected Linux distribution: $DISTRO"
}

# Function to execute commands with error handling and retries
execute_command() {
    local COMMAND="$1"
    local TASK_NAME="$2"
    local MAX_RETRIES="${3:-1}"
    local RETRY_INTERVAL="${4:-5}"

    local ATTEMPT=1
    while [ $ATTEMPT -le $MAX_RETRIES ]; do
        OUTPUT=$(eval "$COMMAND" 2>&1)
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            log "INFO" "$TASK_NAME completed successfully."
            log "INFO" "$TASK_NAME output: $OUTPUT"
            return 0
        else
            log "ERROR" "$TASK_NAME attempt $ATTEMPT failed: $OUTPUT"
            if [ $ATTEMPT -lt $MAX_RETRIES ]; then
                log "INFO" "Retrying in $RETRY_INTERVAL seconds..."
                sleep "$RETRY_INTERVAL"
            else
                log "ERROR" "$TASK_NAME failed after $MAX_RETRIES attempts."
                return $RESULT
            fi
        fi
        ((ATTEMPT++))
    done
}

# Function to prompt user for confirmation
prompt_user() {
    local MESSAGE="$1"
    if [ "$NON_INTERACTIVE" = true ]; then
        return 0  # Automatically proceed in non-interactive mode
    fi
    while true; do
        read -rp "$MESSAGE (y/n): " RESPONSE
        case "$RESPONSE" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Function to perform automated backups
automated_backup() {
    if prompt_user "Do you want to perform a backup of critical data?"; then
        BACKUP_DIR="/backup/$(date '+%Y%m%d')"
        mkdir -p "$BACKUP_DIR"
        # Example backup commands (modify paths as needed)
        execute_command "tar -czf $BACKUP_DIR/etc_backup.tar.gz /etc" "Backup /etc" 1 5
        execute_command "tar -czf $BACKUP_DIR/home_backup.tar.gz /home" "Backup /home" 1 5
        # Add more backup commands as needed
        log "INFO" "Backup completed. Files stored in $BACKUP_DIR"
    else
        log "INFO" "Skipping backup."
    fi
}

# Function to perform Docker maintenance
docker_maintenance() {
    if command -v docker &> /dev/null; then
        if prompt_user "Do you want to perform Docker maintenance?"; then
            # Remove unused images, containers, volumes, and networks
            execute_command "docker system prune -af --volumes" "Docker System Prune" 1 5
            # Check for stopped containers
            STOPPED_CONTAINERS=$(docker ps -a -f status=exited -q)
            if [ -n "$STOPPED_CONTAINERS" ]; then
                log "INFO" "Removing stopped Docker containers."
                execute_command "docker rm $STOPPED_CONTAINERS" "Remove Stopped Containers" 1 5
            fi
            # Check for dangling images
            DANGLING_IMAGES=$(docker images -f dangling=true -q)
            if [ -n "$DANGLING_IMAGES" ]; then
                log "INFO" "Removing dangling Docker images."
                execute_command "docker rmi $DANGLING_IMAGES" "Remove Dangling Images" 1 5
            fi
            # Restart containers if necessary
            # Add commands to update or restart containers as needed
        else
            log "INFO" "Skipping Docker maintenance."
        fi
    else
        log "INFO" "Docker not installed. Skipping Docker maintenance."
    fi
}

# Function to check firewall status and configurations
firewall_check() {
    log "INFO" "Checking firewall status and configurations."
    if command -v ufw &> /dev/null; then
        FIREWALL_STATUS=$(ufw status verbose)
        log "INFO" "UFW Firewall Status:\n$FIREWALL_STATUS"
    elif command -v firewall-cmd &> /dev/null; then
        FIREWALL_STATUS=$(firewall-cmd --state)
        log "INFO" "FirewallD Status: $FIREWALL_STATUS"
    else
        log "WARNING" "No recognized firewall software found."
    fi
}

# Function to integrate with fail2ban
fail2ban_check() {
    if command -v fail2ban-client &> /dev/null; then
        log "INFO" "Checking fail2ban status."
        FAIL2BAN_STATUS=$(fail2ban-client status)
        log "INFO" "Fail2Ban Status:\n$FAIL2BAN_STATUS"
    else
        log "INFO" "Fail2Ban not installed."
        if prompt_user "Do you want to install Fail2Ban?"; then
            execute_command "$PKG_INSTALL fail2ban" "Install Fail2Ban" 1 5
            systemctl enable fail2ban
            systemctl start fail2ban
            log "INFO" "Fail2Ban installed and started."
        else
            log "INFO" "Skipping Fail2Ban installation."
        fi
    fi
}

# Scheduler Integration (non-interactive mode)
# This is handled at the beginning of the script by setting NON_INTERACTIVE=true when run via cron.

# Main Script Execution

archive_old_logs
log "INFO" "Maintenance script started."

detect_distro

# Environment Checks
log "INFO" "Performing environment checks."
# Check free disk space on root partition
FREE_SPACE=$(df / | tail -1 | awk '{print $4}')
if [ "$FREE_SPACE" -lt 10485760 ]; then  # 10 GB in KB
    log "WARNING" "Less than 10 GB free on root partition."
fi

# Automated Backup
automated_backup

# System Update Path
system_update() {
    if prompt_user "Do you want to update the system packages?"; then
        execute_command "$PKG_UPDATE && $PKG_UPGRADE" "System Update" 1 5
    else
        log "INFO" "Skipping system update."
    fi
}
system_update

# Security Updates and Scans
security_updates_and_scans

# Package Cleanup
package_cleanup

# Firewall and Security Enhancements
firewall_check
fail2ban_check

# Docker Maintenance
docker_maintenance

# System Monitoring
system_monitoring

# Issue Checks
issue_checks

# Performance Report
performance_report

# Cleanup Tasks
cleanup_tasks

log "INFO" "Maintenance script completed."
exit 0
