# ----------------
# Module metadata
# ----------------
wifi_baseline_create_NAME="WiFi baseline create"
wifi_baseline_create_DESC="
Creates or updates a known-good WiFi baseline for a location.

Highlights:
• Saves approved APs/settings as a baseline snapshot
• Supports per-location baselines (and per-interface if configured)

Use this after a trusted scan to establish 'normal'.
"

#!/usr/bin/env bash

wifi_baseline_create() {

    WIFI_BASELINE_FORCE_OVERWRITE=0
    export WIFI_BASELINE_FORCE_OVERWRITE

    LOCATION="$1"

    ui_clear
    ui_echo "${CYAN}${BOLD}Creating WiFi baseline...${NC}"
    log_to_file "▶ WiFi baseline creation started"
    echo

    [[ -z "$LOCATION" ]] && {
        ui_echo "${RED}[ERROR]${NC} Location name required (e.g. home/office/lab)"
        log_to_file "[ERROR] Location name required"
        return 1
    }

    WIFI_RAW_DIR="$BASE_DIR/reports/limeseeker_wifi"
    BASELINE_DIR="$BASE_DIR/reports/baselines/wifi/$LOCATION"

    [[ ! -d "$WIFI_RAW_DIR" ]] && {
        ui_echo "${RED}[ERROR]${NC} No WiFi scan data found – run wifi_discovery first"
        log_to_file "[ERROR] No WiFi scan data found"
        return 1
    }

    mkdir -p "$BASELINE_DIR"

    WLAN_IFACES=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}')
    [[ -z "$WLAN_IFACES" ]] && {
        ui_echo "${YELLOW}[INFO]${NC} No wireless interfaces detected"
        log_to_file "[INFO] No wireless interfaces detected"
        return 0
    }

    for IFACE in $WLAN_IFACES; do

        
        CUR_RAW=$(ls -t "$WIFI_RAW_DIR"/"${IFACE}_"*.raw 2>/dev/null | head -n 1)
        [[ -z "$CUR_RAW" ]] && {
            ui_echo "${YELLOW}[INFO]${NC} No scan data found for $IFACE"
            log_to_file "[INFO] No scan data found for $IFACE"
            continue
        }

        BASELINE_FILE="$BASELINE_DIR/$IFACE.baseline"
        if [[ -f "$BASELINE_FILE" ]]; then
            ui_echo "${YELLOW}${BOLD}[WARNING]${NC} Baseline already exists for: ${BOLD}$LOCATION / $IFACE${NC}"
            ui_echo "${YELLOW}File:${NC} $BASELINE_FILE"
            ui_echo
            ui_read -rp "Overwrite existing baseline? Type YES to confirm: " confirm_overwrite

            if [[ "${confirm_overwrite^^}" != "YES" ]]; then
                ui_echo "${YELLOW}[INFO]${NC} Baseline overwrite cancelled for $LOCATION / $IFACE"
                log_to_file "[INFO] Baseline overwrite cancelled: $LOCATION / $IFACE"
                echo
                continue
            fi

            ui_echo "${YELLOW}[INFO]${NC} Overwriting baseline for $LOCATION / $IFACE"
            log_to_file "[INFO] Overwriting baseline: $LOCATION / $IFACE"
            echo
        fi

        {
            echo "# LimeSeeker WiFi Baseline"
            echo "# Location: $LOCATION"
            echo "# Interface: $IFACE"
            echo "# Source: $CUR_RAW"
            echo "# Created: $(date)"
            echo

            awk '
            /BSS/ {bssid=$2}
            /SSID:/ {
                ssid=$0
                sub(/^SSID: /,"",ssid)
                enc="OPEN"
                wps="no"
                chan="?"
            }
            /DS Parameter set/ {chan=$5}
            /RSN:/ {enc="WPA2/WPA3"}
            /WPA:/ {enc="WPA"}
            /WEP/ {enc="WEP"}
            /WPS:/ {wps="yes"}
            /SSID:/ {
                printf "AP|SSID=%s|BSSID=%s|ENC=%s|CHAN=%s|WPS=%s\n",
                ssid,bssid,enc,chan,wps
            }' "$CUR_RAW"

        } > "$BASELINE_FILE"

        ui_echo "${GREEN}[OK]${NC} Baseline created: $LOCATION / $IFACE"
        ui_echo "  → $BASELINE_FILE"
        log_to_file "[BASELINE] Created: $BASELINE_FILE"
        echo
    done

    ui_echo "${CYAN}${BOLD}WiFi baseline creation completed.${NC}"
    log_to_file "✔ WiFi baseline creation completed"  
  
    return 0
}

