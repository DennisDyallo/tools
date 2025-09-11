#!/bin/bash

# Safe Arch Linux upgrade script with rollback functionality
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOGFILE="$HOME/.cache/safe-upgrade-$(date +%Y%m%d-%H%M%S).log"
ROLLBACK_MODE=false

# Ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")"

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -r, --rollback      Enter rollback mode
    -l, --list          List available snapshots
    -d, --delete        Delete snapshots
    -c, --clear-cache   Clear package cache
    -h, --help          Show this help message

Examples:
    $0                  # Normal upgrade
    $0 --rollback       # Rollback system
    $0 --list          # List snapshots
    $0 --delete        # Delete old snapshots  
    $0 --clear-cache   # Clear corrupted cache
EOF
}

log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--rollback)
                ROLLBACK_MODE=true
                shift
                ;;
            -l|--list)
                list_snapshots
                exit 0
                ;;
            -d|--delete)
                delete_snapshots
                exit 0
                ;;
            -c|--clear-cache)
                clear_package_cache
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            upgrade|"")
                # Default mode - continue to main
                ;;
            *)
                log "${RED}[ERROR] Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

detect_snapshot_system() {
    if command -v timeshift &> /dev/null && [[ -d /timeshift/snapshots ]]; then
        echo "timeshift"
    elif command -v snapper &> /dev/null && [[ -d /.snapshots ]]; then
        echo "snapper"
    elif [[ -d /.snapshots ]] && findmnt -n -o FSTYPE / | grep -q btrfs; then
        echo "btrfs"
    else
        echo "none"
    fi
}

list_snapshots() {
    local system=$(detect_snapshot_system)
    log "${BLUE}[INFO] Available snapshots:${NC}"
    
    case "$system" in
        "timeshift")
            sudo timeshift --list
            ;;
        "snapper")
            sudo snapper list
            ;;
        "btrfs")
            sudo btrfs subvolume list / | grep snapshots
            ;;
        "none")
            log "${RED}[ERROR] No snapshot system detected.${NC}"
            return 1
            ;;
    esac
}

check_free_space() {
    local free_gb=$(df --output=avail / | tail -1 | awk '{printf "%.1f", $1/1024/1024}')
    local free_gb_int=$(printf "%.0f" "$free_gb")
    
    log "${BLUE}[INFO] Available disk space: ${free_gb}GB${NC}"
    
    if [[ $free_gb_int -lt 5 ]]; then
        log "${RED}[WARNING] Low disk space (${free_gb}GB)! Snapshots may fail.${NC}"
        log "${YELLOW}[SUGGESTION] Consider cleaning old snapshots with: $0 --delete${NC}"
        read -p "Continue anyway? [y/N]: " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "${YELLOW}[EXIT] Free up space and try again.${NC}"
            exit 1
        fi
    elif [[ $free_gb_int -lt 10 ]]; then
        log "${YELLOW}[WARNING] Disk space is getting low (${free_gb}GB).${NC}"
        log "${YELLOW}[SUGGESTION] Consider cleaning old snapshots after upgrade.${NC}"
    fi
}

delete_snapshots() {
    local system=$(detect_snapshot_system)
    
    if [[ "$system" == "none" ]]; then
        log "${RED}[ERROR] No snapshot system detected.${NC}"
        return 1
    fi
    
    log "${BLUE}[INFO] Snapshot cleanup${NC}"
    list_snapshots
    echo
    
    case "$system" in
        "timeshift")
            echo "Delete options:"
            echo "1. Delete specific snapshot"
            echo "2. Delete all except latest 3"
            echo "3. Delete all except latest 1"
            echo "4. Cancel"
            
            read -p "Choose option [1-4]: " choice
            
            case "$choice" in
                1)
                    read -p "Enter snapshot ID to delete: " snapshot_id
                    if [[ -n "$snapshot_id" ]]; then
                        read -p "Delete snapshot $snapshot_id? [y/N]: " confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            sudo timeshift --delete --snapshot "$snapshot_id"
                            log "${GREEN}[OK] Snapshot deleted.${NC}"
                        fi
                    fi
                    ;;
                2)
                    read -p "Keep only latest 3 snapshots? [y/N]: " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        sudo timeshift --delete-all --skip-latest 3
                        log "${GREEN}[OK] Old snapshots cleaned.${NC}"
                    fi
                    ;;
                3)
                    read -p "Keep only latest 1 snapshot? [y/N]: " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        sudo timeshift --delete-all --skip-latest 1
                        log "${GREEN}[OK] All but latest snapshot deleted.${NC}"
                    fi
                    ;;
                4)
                    log "${YELLOW}[INFO] Cleanup cancelled.${NC}"
                    ;;
            esac
            ;;
            
        "snapper")
            echo "Delete options:"
            echo "1. Delete specific snapshot"
            echo "2. Delete range of snapshots"
            echo "3. Cancel"
            
            read -p "Choose option [1-3]: " choice
            
            case "$choice" in
                1)
                    read -p "Enter snapshot number to delete: " snapshot_num
                    if [[ -n "$snapshot_num" ]]; then
                        read -p "Delete snapshot $snapshot_num? [y/N]: " confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            sudo snapper delete "$snapshot_num"
                            log "${GREEN}[OK] Snapshot deleted.${NC}"
                        fi
                    fi
                    ;;
                2)
                    read -p "Enter range (e.g., 1-10): " range
                    if [[ -n "$range" ]]; then
                        read -p "Delete snapshots $range? [y/N]: " confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            sudo snapper delete "$range"
                            log "${GREEN}[OK] Snapshots deleted.${NC}"
                        fi
                    fi
                    ;;
                3)
                    log "${YELLOW}[INFO] Cleanup cancelled.${NC}"
                    ;;
            esac
            ;;
            
        "btrfs")
            log "${YELLOW}[INFO] Manual BTRFS snapshot deletion required.${NC}"
            log "${YELLOW}[INFO] Use: sudo btrfs subvolume delete /.snapshots/snapshot-name${NC}"
            ;;
    esac
}

clear_package_cache() {
    log "${BLUE}[INFO] Package cache cleanup${NC}"
    
    # Show current cache size
    local cache_size=$(du -sh ~/.cache/yay 2>/dev/null | cut -f1 || echo "0")
    local pacman_cache_size=$(sudo du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "0")
    
    log "${BLUE}[INFO] Current cache sizes:${NC}"
    echo "  yay cache: $cache_size"
    echo "  pacman cache: $pacman_cache_size"
    echo
    
    echo "Cache clearing options:"
    echo "1. Clear corrupted cache (remove all cache, fresh start)"
    echo "2. Clean uninstalled packages only (yay -Sc)" 
    echo "3. Clean old package versions (keep latest 3)"
    echo "4. Nuclear option (clear everything, including databases)"
    echo "5. Cancel"
    
    read -p "Choose option [1-5]: " choice
    
    case "$choice" in
        1)
            log "${YELLOW}[WARNING] This will clear ALL package cache files.${NC}"
            read -p "Clear all cache? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                log "${YELLOW}[INFO] Clearing yay and pacman cache...${NC}"
                yay -Scc --noconfirm
                log "${GREEN}[OK] All cache cleared.${NC}"
            fi
            ;;
        2)
            log "${YELLOW}[INFO] Cleaning uninstalled packages from cache...${NC}"
            yay -Sc --noconfirm
            log "${GREEN}[OK] Uninstalled packages cleaned.${NC}"
            ;;
        3)
            log "${YELLOW}[INFO] Cleaning old package versions (keeping 3)...${NC}"
            if command -v paccache &> /dev/null; then
                sudo paccache -rk3
                log "${GREEN}[OK] Old package versions cleaned.${NC}"
            else
                log "${YELLOW}[INFO] paccache not found, using yay -Sc instead...${NC}"
                yay -Sc --noconfirm
                log "${GREEN}[OK] Cache cleaned with yay.${NC}"
            fi
            ;;
        4)
            log "${RED}[WARNING] NUCLEAR OPTION: This will clear cache AND reset package databases!${NC}"
            log "${RED}[WARNING] Only use if experiencing severe corruption issues.${NC}"
            read -p "Are you absolutely sure? [type 'NUCLEAR']: " confirm
            if [[ "$confirm" == "NUCLEAR" ]]; then
                log "${RED}[NUCLEAR] Clearing all cache and resetting databases...${NC}"
                
                # Clear all cache
                yay -Scc --noconfirm
                
                # Remove pacman lock files if they exist
                sudo rm -f /var/lib/pacman/db.lck
                
                # Refresh package databases  
                log "${YELLOW}[INFO] Refreshing package databases...${NC}"
                sudo pacman -Syy
                
                log "${GREEN}[OK] Nuclear cache clearing completed.${NC}"
                log "${YELLOW}[INFO] Try running upgrade now.${NC}"
            else
                log "${YELLOW}[INFO] Nuclear option cancelled.${NC}"
            fi
            ;;
        5)
            log "${YELLOW}[INFO] Cache cleanup cancelled.${NC}"
            ;;
    esac
}

rollback_system() {
    local system=$(detect_snapshot_system)
    
    if [[ "$system" == "none" ]]; then
        log "${RED}[ERROR] No snapshot system available for rollback.${NC}"
        return 1
    fi
    
    log "${YELLOW}[WARNING] System rollback will revert filesystem changes.${NC}"
    log "${YELLOW}[WARNING] Current data since snapshot will be lost!${NC}"
    
    list_snapshots
    echo
    
    case "$system" in
        "timeshift")
            read -p "Enter snapshot ID to rollback to (or 'cancel'): " snapshot_id
            if [[ "$snapshot_id" == "cancel" ]]; then
                log "${YELLOW}[INFO] Rollback cancelled.${NC}"
                return 0
            fi
            
            read -p "Are you absolutely sure? This cannot be undone! [type 'YES']: " confirm
            if [[ "$confirm" != "YES" ]]; then
                log "${YELLOW}[INFO] Rollback cancelled.${NC}"
                return 0
            fi
            
            log "${RED}[ROLLBACK] Starting Timeshift rollback...${NC}"
            sudo timeshift --restore --snapshot "$snapshot_id" --skip-grub
            ;;
            
        "snapper")
            read -p "Enter snapshot number to rollback to (or 'cancel'): " snapshot_num
            if [[ "$snapshot_num" == "cancel" ]]; then
                log "${YELLOW}[INFO] Rollback cancelled.${NC}"
                return 0
            fi
            
            read -p "Are you absolutely sure? This cannot be undone! [type 'YES']: " confirm
            if [[ "$confirm" != "YES" ]]; then
                log "${YELLOW}[INFO] Rollback cancelled.${NC}"
                return 0
            fi
            
            log "${RED}[ROLLBACK] Starting Snapper rollback...${NC}"
            sudo snapper undochange "$snapshot_num..0"
            ;;
            
        "btrfs")
            log "${YELLOW}[INFO] BTRFS rollback requires manual intervention.${NC}"
            log "${YELLOW}[INFO] Boot from live USB and manually restore subvolume.${NC}"
            log "${YELLOW}[INFO] Refer to: https://wiki.archlinux.org/title/Btrfs#Snapshots${NC}"
            ;;
    esac
}

rollback_packages() {
    log "${BLUE}[INFO] Package rollback options:${NC}"
    
    # Check for cache corruption before attempting rollback
    if ! yay -Qq &>/dev/null; then
        log "${RED}[ERROR] Package database corrupted - cannot perform package rollback!${NC}"
        log "${YELLOW}[SUGGESTION] Try: $0 --clear-cache first${NC}"
        return 1
    fi
    
    echo "1. Rollback specific packages"
    echo "2. Rollback all packages from pacman cache"
    echo "3. Cancel"
    
    read -p "Choose option [1-3]: " choice
    
    case "$choice" in
        1)
            log "${YELLOW}[INFO] Recently upgraded packages:${NC}"
            grep -E "upgraded|installed" /var/log/pacman.log | tail -20
            echo
            read -p "Enter package names to downgrade (space separated): " packages
            if [[ -n "$packages" ]]; then
                sudo downgrade $packages
            fi
            ;;
        2)
            log "${RED}[WARNING] This will attempt to downgrade ALL recently upgraded packages!${NC}"
            read -p "Continue? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                # Get list of recently upgraded packages
                local recent_packages=$(grep "upgraded" /var/log/pacman.log | tail -20 | awk '{print $4}' | sort -u)
                if [[ -n "$recent_packages" ]]; then
                    sudo downgrade $recent_packages
                else
                    log "${YELLOW}[INFO] No recent package upgrades found.${NC}"
                fi
            fi
            ;;
        3)
            log "${YELLOW}[INFO] Package rollback cancelled.${NC}"
            ;;
    esac
}

check_arch_news() {
    log "${YELLOW}[INFO] Checking Arch Linux news...${NC}"
    echo "Visit: https://archlinux.org/news/"
    read -p "Have you checked recent Arch news for breaking changes? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "${RED}[EXIT] Please check Arch news first.${NC}"
        exit 1
    fi
}

check_cache_corruption() {
    log "${YELLOW}[INFO] Checking for package cache issues...${NC}"
    
    # Test if yay can read package databases
    if ! yay -Qq &>/dev/null; then
        log "${RED}[ERROR] Package database appears corrupted!${NC}"
        log "${YELLOW}[SUGGESTION] Run: $0 --clear-cache${NC}"
        read -p "Clear cache now and continue? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log "${YELLOW}[INFO] Clearing corrupted cache...${NC}"
            yay -Scc --noconfirm
            sudo pacman -Syy  # Refresh databases
            log "${GREEN}[OK] Cache cleared, continuing upgrade.${NC}"
        else
            log "${RED}[EXIT] Please fix cache issues first.${NC}"
            exit 1
        fi
    fi
    
    # Check for package database locks
    if [[ -f /var/lib/pacman/db.lck ]]; then
        log "${YELLOW}[WARNING] Pacman database is locked.${NC}"
        log "${YELLOW}[INFO] This might be from a previous interrupted upgrade.${NC}"
        read -p "Remove lock file and continue? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            sudo rm -f /var/lib/pacman/db.lck
            log "${GREEN}[OK] Lock file removed.${NC}"
        else
            log "${RED}[EXIT] Please resolve lock file issue first.${NC}"
            exit 1
        fi
    fi
}

create_snapshot() {
    log "${YELLOW}[INFO] Creating system snapshot...${NC}"
    
    # Check available space first
    check_free_space
    
    if command -v timeshift &> /dev/null; then
        sudo timeshift --create --comments "Pre-upgrade $(date)"
        log "${GREEN}[OK] Timeshift snapshot created.${NC}"
    elif [[ -d /.snapshots ]]; then
        sudo snapper create --description "Pre-upgrade $(date)"
        log "${GREEN}[OK] Snapper snapshot created.${NC}"
    else
        log "${YELLOW}[WARN] No snapshot tool found. Consider installing timeshift or snapper.${NC}"
        read -p "Continue without snapshot? [y/N]: " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

review_upgrades() {
    log "${YELLOW}[INFO] Reviewing packages to upgrade...${NC}"
    yay -Syu --print
    
    read -p "Proceed with these upgrades? [Y/n]: " response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        log "${RED}[EXIT] Upgrade cancelled by user.${NC}"
        exit 1
    fi
}

perform_upgrade() {
    log "${YELLOW}[INFO] Starting system upgrade...${NC}"
    log "${YELLOW}[INFO] Logging to: $LOGFILE${NC}"
    
    # Clean package cache first (light cleanup)
    log "${YELLOW}[INFO] Cleaning uninstalled packages from cache...${NC}"
    yay -Sc --noconfirm
    
    # Perform upgrade with error handling
    log "${YELLOW}[INFO] Running system upgrade...${NC}"
    if ! yay -Syu --devel --timeupdate --noconfirm 2>&1 | tee -a "$LOGFILE"; then
        log "${RED}[ERROR] Upgrade failed!${NC}"
        log "${YELLOW}[INFO] Check log file: $LOGFILE${NC}"
        log "${YELLOW}[SUGGESTION] If cache corruption suspected, try: $0 --clear-cache${NC}"
        log "${YELLOW}[SUGGESTION] For rollback, try: $0 --rollback${NC}"
        exit 1
    fi
    
    log "${GREEN}[OK] Upgrade completed successfully!${NC}"
}

main() {
    if [[ "$ROLLBACK_MODE" == true ]]; then
        log "${GREEN}=== Arch Linux Rollback Started: $(date) ===${NC}"
        echo "Rollback options:"
        echo "1. Filesystem rollback (from snapshot)"
        echo "2. Package rollback (downgrade packages)"
        echo "3. Both"
        echo "4. Cancel"
        
        read -p "Choose option [1-4]: " choice
        
        case "$choice" in
            1)
                rollback_system
                ;;
            2)
                rollback_packages
                ;;
            3)
                rollback_packages
                echo
                log "${YELLOW}[INFO] After reboot, you may need to run package rollback again.${NC}"
                rollback_system
                ;;
            4)
                log "${YELLOW}[INFO] Rollback cancelled.${NC}"
                ;;
            *)
                log "${RED}[ERROR] Invalid option.${NC}"
                exit 1
                ;;
        esac
    else
        # Normal upgrade mode
        log "${GREEN}=== Safe Arch Upgrade Started: $(date) ===${NC}"
        
        check_arch_news
        check_cache_corruption
        create_snapshot
        review_upgrades
        perform_upgrade
        
        log "${GREEN}=== Upgrade process completed: $(date) ===${NC}"
        log "${YELLOW}[INFO] Reboot recommended if kernel was upgraded.${NC}"
        
        if grep -q "linux " "$LOGFILE"; then
            read -p "Kernel appears to be upgraded. Reboot now? [y/N]: " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sudo reboot
            fi
        fi
    fi
}

# Check if running as regular user
if [[ $EUID -eq 0 ]]; then
    echo "Don't run this script as root. It will use sudo when needed."
    exit 1
fi

# Install downgrade if not present (for package rollback functionality)
if ! command -v downgrade &> /dev/null; then
    echo "Installing 'downgrade' for package rollback functionality..."
    yay -S downgrade --noconfirm
fi

# Parse arguments first, then run main logic
parse_args "$@"
main