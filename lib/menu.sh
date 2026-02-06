#!/usr/bin/env bash

main_menu() {

    local modules_to_run=()
    local choice status module

    # ---------------
    # Signal handlers
    # ---------------
    handle_sigint() {
        echo -e "\n${YELLOW}Ctrl+C detected. Exiting LimeSeeker...${NC}" > /dev/tty
        echo -e "${YELLOW}Clearing sudo privileges...${NC}" > /dev/tty
        log_event "User aborted LimeSeeker (Ctrl+C)"
        sudo -k
        exit 0
    }
    trap handle_sigint SIGINT

    handle_eof() {
        echo -e "\n${YELLOW}Ctrl+D detected. Exiting LimeSeeker...${NC}" > /dev/tty
        echo -e "${YELLOW}Clearing sudo privileges...${NC}" > /dev/tty
        log_event "User exited LimeSeeker via Ctrl+D (EOF)"
        sudo -k
        exit 0
    }

    handle_sigtstp() {
        echo -e "\n${YELLOW}Ctrl+Z detected. Exiting for security...${NC}" > /dev/tty
        echo -e "${YELLOW}Clearing sudo privileges...${NC}" > /dev/tty
        log_event "User attempted to suspend script (SIGTSTP)"
        sudo -k
        exit 1
    }
    trap handle_sigtstp SIGTSTP


    # ==========================
    # MAIN MENU MODULE STATUS
    # ==========================
    declare -A MODULE_STATUS=(
        [local_inventory]="– not run"
        [local_security]="– not run"
        [system_hardening]="– not run"
        [network]="– not run"
        [wifi]="– not run"
    )

    status_color() {
        case "$1" in
            "– not run") echo -e "${DIM}[ ] not run${NC}" ;;
            "✔ done")    echo -e "[${GREEN}✔${NC}] ${GREEN}done${NC}" ;;
            "✖ failed")  echo -e "[${RED}✖${NC}] ${RED}failed${NC}" ;;
            *)           echo "$1" ;;
        esac
    }


    # ==========================
    # WIFI SUBMODULE STATUS
    # ==========================
    declare -A WIFI_STATUS=(
        [wifi_discovery]="– not run"
        [wifi_analysis]="– not run"
        [wifi_history]="– not run"
        [wifi_baseline_create]="– not run"
        [wifi_baseline_check]="– not run"
        [wifi_baseline_delete]="– not run"
    )

    wifi_status_color() {
        case "$1" in
            "– not run") echo -e "${DIM}[ ] not run${NC}" ;;
            "✔ done")    echo -e "[${GREEN}✔${NC}] ${GREEN}done${NC}" ;;
            "✖ failed")  echo -e "[${RED}✖${NC}] ${RED}failed${NC}" ;;
            *)           echo "$1" ;;
        esac
    }

    wifi_set_status() {
        local key="$1" rc="$2"
        if [[ "$rc" -eq 0 ]]; then
            WIFI_STATUS["$key"]="✔ done"
        else
            WIFI_STATUS["$key"]="✖ failed"
        fi
    }


    # ==========================
    # NETWORK SUBMODULE STATUS
    # ==========================
    declare -A NETWORK_STATUS=(
        [network_discovery]="– not run"
        )

    network_status_color() {
        case "$1" in
            "– not run") echo -e "${DIM}[ ] not run${NC}" ;;
            "✔ done")    echo -e "[${GREEN}✔${NC}] ${GREEN}done${NC}" ;;
            "✖ failed")  echo -e "[${RED}✖${NC}] ${RED}failed${NC}" ;;
            *)           echo "$1" ;;
        esac
    }

    network_set_status() {
        local key="$1" rc="$2"
        if [[ "$rc" -eq 0 ]]; then
            NETWORK_STATUS["$key"]="✔ done"
        else
            NETWORK_STATUS["$key"]="✖ failed"
        fi
    }


    # ==========================
    # RESET ALL STATUSES
    # ==========================
    reset_module_status() {
        ui_clear
        ui_echo
        ui_echo "${BOLD}${YELLOW}Reset module status${NC}"
        ui_echo
        ui_echo "This will mark all modules as '${DIM}not run${NC}'."
        ui_echo "Includes WiFi and Network sub-modules."
        ui_echo "No scans will be executed."
        ui_echo "Log files will NOT be deleted."
        ui_echo
        ui_read -rp "Type YES to confirm: " confirm

        if [[ "${confirm,,}" == "yes" ]]; then
            for m in "${!MODULE_STATUS[@]}"; do
                MODULE_STATUS["$m"]="– not run"
            done

            for k in "${!WIFI_STATUS[@]}"; do
                WIFI_STATUS["$k"]="– not run"
            done

            for k in "${!NETWORK_STATUS[@]}"; do
                NETWORK_STATUS["$k"]="– not run"
            done

            ui_echo
            ui_echo "${GREEN}Module status reset successfully.${NC}"
            log_event "Module status reset by user."
            sleep 1
        else
            ui_echo
            ui_echo "${YELLOW}Reset cancelled.${NC}"
            sleep 1
        fi
    }


    # ==========================
    # MODULE INFO VIEW
    # ==========================
    show_module_info() {
        local module="$1"

        local NAME_VAR="${module}_NAME"
        local DESC_VAR="${module}_DESC"
        local SAFETY_VAR="${module}_SAFETY"

        ui_clear
        ui_echo "${BOLD}${CYAN}_    _ _  _ ____ ____ ____ ____ _  _ ____ ____${NC}"
        ui_echo "${BOLD}${CYAN}|    | |\\/| |___ [__  |___ |___ |_/  |___ |__/ ${NC}"
        ui_echo "${BOLD}${CYAN}|___ | |  | |___ ___] |___ |___ | \\_ |___ |  \\ ${NC}${BOLD}${!NAME_VAR}${NC}"
        ui_echo "${CYAN}------------------------------------------------------------------------${NC}"
        ui_status_block
        ui_echo
        ui_echo "${!DESC_VAR}"
        ui_echo

        if [[ -n "${!SAFETY_VAR}" ]]; then
            ui_echo "${YELLOW}${BOLD}Safety notice:${NC}"
            ui_echo "${!SAFETY_VAR}"
            ui_echo
        fi

        ui_read -rp "Press ENTER to return"
    }

    info_menu() {
        local ichoice imod

        while true; do
            ui_clear
	    ui_echo
            ui_echo "${BOLD}${CYAN}        _____ _______ _______ _______ _______ _______ _     _ _______  ______" 
            ui_echo " |        |   |  |  | |______ |______ |______ |______ |____/  |______ |_____/"
            ui_echo " |_____ __|__ |  |  | |______ ______| |______ |______ |    \_ |______ |    \_"
            ui_echo "        Module information                                     version ${LIMESEEKER_VERSION}"
	    ui_echo "-----------------------------------------------------------------------------${NC}"
            ui_status_block
            ui_echo
            ui_echo "${BOLD}${CYAN}System:${NC}"
            ui_echo "1) Local inventory"
            ui_echo "2) Local security"
            ui_echo "3) System hardening"
            ui_echo
            ui_echo "${BOLD}${CYAN}Network:${NC}"
            ui_echo "4) Network tools (overview)"
            ui_echo "5) Network vulnerability"
            ui_echo
            ui_echo "${BOLD}${CYAN}WiFi:${NC}"
            ui_echo "6) WiFi tools (overview)"
            ui_echo "7) WiFi discovery"
            ui_echo "8) WiFi analysis"
            ui_echo "9) WiFi baseline create"
            ui_echo "10) WiFi baseline check"
            ui_echo
            ui_echo "q) Back to main menu"
            ui_echo
            ui_echo
            ui_read -rp "Select option: " choice

            case "$choice" in
                1)  module="local_inventory" ;;
                2)  module="local_security" ;;
                3)  module="system_hardening" ;;

                4)  module="network_tools" ;;
                5)  module="network_vulnerability" ;;

                6)  module="wifi_tools" ;;
                7)  module="wifi_discovery" ;;
                8) module="wifi_analysis" ;;
                9) module="wifi_baseline_create" ;;
                10) module="wifi_baseline_check" ;;

                q|Q) return ;;
                *) ui_echo "${RED}Invalid choice${NC}"; sleep 1; continue ;;
            esac

            show_module_info "$module"
        done
    }

    # ==========================
    # WIFI BASELINE HELPERS
    # ==========================
    : "${WIFI_BASELINE_FORCE_OVERWRITE:=0}"

    wifi_baseline_root() {
        echo "$BASE_DIR/reports/baselines/wifi"
    }

    wifi_list_baseline_locations() {
        local root
        root="$(wifi_baseline_root)"
        [[ ! -d "$root" ]] && return 0
        find "$root" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort
    }

    wifi_baseline_location_last_updated() {
        local loc="$1"
        local root path latest_epoch
        root="$(wifi_baseline_root)"
        path="$root/$loc"

        [[ ! -d "$path" ]] && { echo ""; return 0; }

        latest_epoch=$(find "$path" -type f -name "*.baseline" -printf "%T@\n" 2>/dev/null | sort -nr | head -n1)
        [[ -z "$latest_epoch" ]] && { echo ""; return 0; }

        latest_epoch=${latest_epoch%.*}
        date -d "@$latest_epoch" "+%Y-%m-%d %H:%M" 2>/dev/null
    }

    wifi_print_baseline_overview() {
        local root locations loc
        root="$(wifi_baseline_root)"

        ui_echo "${BOLD}${CYAN}Existing WiFi baselines:${NC}"
        ui_echo "------------------------------------------------------------"

        if [[ ! -d "$root" ]]; then
            ui_echo "${DIM}(none found yet)${NC}"
            return 0
        fi

        locations=$(wifi_list_baseline_locations)
        if [[ -z "$locations" ]]; then
            ui_echo "${DIM}(none found yet)${NC}"
            return 0
        fi

        while read -r loc; do
            [[ -z "$loc" ]] && continue

            local ifaces iface_count last iface_line
            ifaces=$(ls -1 "$root/$loc"/*.baseline 2>/dev/null \
                | sed -n 's#.*/##; s/\.baseline$//p' \
                | sort)

            iface_count=$(echo "$ifaces" | sed '/^$/d' | wc -l 2>/dev/null)
            last="$(wifi_baseline_location_last_updated "$loc")"
            [[ -z "$last" ]] && last="unknown"
            iface_line=$(echo "$ifaces" | tr '\n' ' ')

            ui_echo "• ${BOLD}$loc${NC}  ${DIM}(${iface_count} iface)${NC}"
            ui_echo "  ${DIM}Interfaces:${NC} ${iface_line:-none}"
            ui_echo "  ${DIM}Last updated:${NC} $last"
        done <<< "$locations"
    }

    wifi_prompt_existing_location() {
        local arr=() idx=1 choice loc
        mapfile -t arr < <(wifi_list_baseline_locations)

        if (( ${#arr[@]} == 0 )); then
            ui_echo "${YELLOW}[INFO]${NC} No baselines exist yet."
            echo ""
            return 1
        fi

        ui_echo
        ui_echo "${BOLD}${CYAN}Select baseline location:${NC}"
        for loc in "${arr[@]}"; do
            ui_echo "  $idx) $loc"
            ((idx++))
        done
	ui_echo
        ui_echo "  q) Cancel"
        ui_echo
	ui_echo

        if ! ui_read -rp "Choose: " choice; then
            echo ""
            return 1
        fi

        case "$choice" in
            q|Q) echo ""; return 1 ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    local sel=$((choice-1))
                    if (( sel >= 0 && sel < ${#arr[@]} )); then
                        echo "${arr[$sel]}"
                        return 0
                    fi
                fi
                ui_echo "${RED}Invalid choice${NC}"
                echo ""
                return 1
                ;;
        esac
    }

    wifi_prompt_new_location() {
        local newloc
        ui_echo
        ui_echo "${BOLD}${CYAN}Create new baseline location${NC}"
        ui_echo "${DIM}Tip: use simple names like home/office/lab${NC}"
        ui_echo

        if ! ui_read -rp "Enter location name: " newloc; then
            echo ""
            return 1
        fi

        newloc="${newloc// /_}"
        [[ -z "$newloc" ]] && { ui_echo "${RED}Invalid location name${NC}"; echo ""; return 1; }

        echo "$newloc"
        return 0
    }

    # Delete location (with dry-run preview built-in)
    wifi_delete_location() {
        local loc="$1"
        local root path files count confirm

        root="$(wifi_baseline_root)"
        path="$root/$loc"

        [[ -z "$loc" ]] && return 1

        if [[ ! -d "$path" ]]; then
            ui_echo "${YELLOW}[INFO]${NC} Location does not exist: $loc"
            log_to_file "[INFO] Baseline delete: location not found ($loc)"
            return 1
        fi

        mapfile -t files < <(find "$path" -type f 2>/dev/null)
        count="${#files[@]}"

        ui_echo
        ui_echo "${YELLOW}${BOLD}[DRY-RUN] Baseline deletion preview${NC}"
        ui_echo "------------------------------------------------------------"
        ui_echo "${BOLD}Location:${NC} $loc"
        ui_echo "${BOLD}Path:${NC}     $path"
        ui_echo "${BOLD}Files:${NC}    $count"
        ui_echo

        if (( count == 0 )); then
            ui_echo "${DIM}(no files found)${NC}"
        else
            for f in "${files[@]}"; do
                ui_echo "  • ${f#$path/}"
            done
        fi

        ui_echo
        ui_echo "${YELLOW}${BOLD}[WARNING]${NC} This action is irreversible."
        ui_echo "${YELLOW}All files listed above will be permanently deleted.${NC}"
        ui_echo

        ui_read -rp "Type YES to delete this location: " confirm
        if [[ "${confirm^^}" != "YES" ]]; then
            ui_echo "${YELLOW}[INFO]${NC} Delete cancelled."
            log_to_file "[INFO] Baseline delete cancelled ($loc)"
            return 1
        fi

        rm -rf -- "$path"
        if [[ -d "$path" ]]; then
            ui_echo "${RED}[ERROR]${NC} Failed to delete location: $loc"
            log_to_file "[ERROR] Baseline delete failed ($loc)"
            return 1
        fi

        ui_echo "${GREEN}[OK]${NC} Deleted baseline location: $loc"
        log_to_file "[OK] Deleted baseline location: $loc"
        log_event "Baseline location deleted: $loc"
        return 0
    }

    # ==========================
    # WIFI BASELINE MANAGER
    # ==========================
    wifi_baseline_manager() {
        local action loc status

        while true; do
            ui_clear
            ui_echo
	    ui_echo "${BOLD}${CYAN}_    _ _  _ ____ ____ ____ ____ _  _ ____ ____"
            ui_echo "|    | |\/| |___ [__  |___ |___ |_/  |___ |__/"
            ui_echo "|___ | |  | |___ ___] |___ |___ | \_ |___ |  \ WiFi baseline manager"
            ui_echo "------------------------------------------------------------------------${NC}"
            ui_status_block
            ui_echo

            wifi_print_baseline_overview

            ui_echo
            ui_echo "${BOLD}${CYAN}Actions:${NC}"
            ui_echo "1) Create/Update baseline      (new location)"
            ui_echo "2) Check against baseline      (compare scan vs location)"
            ui_echo "3) Delete baseline             (choose existing location)"
            ui_echo
            ui_echo "q) Back"
            ui_echo
            ui_echo

            if ! ui_read -rp "Select option: " action; then
                handle_eof
            fi

            case "$action" in
                1)
                    loc="$(wifi_prompt_new_location)"
                    [[ -z "$loc" ]] && { sleep 1; continue; }

                    # Overwrite warning only ONCE per run (inside baseline_create, you can check WIFI_BASELINE_FORCE_OVERWRITE if you want)
                    if [[ "${WIFI_BASELINE_FORCE_OVERWRITE}" -ne 1 ]]; then
                        local basepath
                        basepath="$(wifi_baseline_root)/$loc"
                        if [[ -d "$basepath" && -n "$(ls -1 "$basepath"/*.baseline 2>/dev/null)" ]]; then
                            ui_echo
                            ui_echo "${YELLOW}${BOLD}[WARNING]${NC} Baseline files already exist for location: ${BOLD}$loc${NC}"
                            ui_echo "${YELLOW}If you continue, existing baseline files may be overwritten.${NC}"
                            ui_echo
                            ui_read -rp "Overwrite existing baseline(s) for this run? Type YES to confirm: " confirm_overwrite
                            if [[ "${confirm_overwrite^^}" != "YES" ]]; then
                                ui_echo "${YELLOW}[INFO]${NC} Baseline create cancelled."
                                log_to_file "[INFO] Baseline overwrite cancelled ($loc)"
                                sleep 1
                                continue
                            fi
                            WIFI_BASELINE_FORCE_OVERWRITE=1
                            export WIFI_BASELINE_FORCE_OVERWRITE
                            ui_echo "${YELLOW}[INFO]${NC} Overwrite confirmed for this run (no more prompts)."
                            log_to_file "[INFO] Baseline overwrite confirmed for this run"
                            ui_echo
                        fi
                    fi

                    log_section "Running module: wifi_baseline_create ($loc)"
                    wifi_baseline_create "$loc"
                    status=$?
                    wifi_set_status "wifi_baseline_create" "$status"

                    ui_echo
                    if [[ $status -eq 0 ]]; then
                        ui_echo "[${GREEN}✔${NC}] ${GREEN}Baseline created/updated for location: ${BOLD}$loc${NC}"
                        log_event "[OK] WiFi baseline create ($loc)"
                    else
                        ui_echo "[${RED}✖${NC}] ${RED}Baseline create failed or cancelled (${BOLD}$loc${NC}${RED})${NC}"
                        log_event "[FAIL] WiFi baseline create ($loc)"
                    fi
                    ui_echo
                    pause
                    ;;
                2)
                    loc="$(wifi_prompt_existing_location)"
                    [[ -z "$loc" ]] && { sleep 1; continue; }

                    log_section "Running module: wifi_baseline_check ($loc)"
                    wifi_baseline_check "$loc"
                    status=$?
                    wifi_set_status "wifi_baseline_check" "$status"

                    ui_echo
                    if [[ $status -eq 0 ]]; then
                        ui_echo "[${GREEN}✔${NC}] ${GREEN}Baseline comparison completed for: ${BOLD}$loc${NC}"
                        log_event "[OK] WiFi baseline check ($loc)"
                    else
                        ui_echo "[${RED}✖${NC}] ${RED}Baseline comparison failed for: ${BOLD}$loc${NC}"
                        log_event "[FAIL] WiFi baseline check ($loc)"
                    fi
                    ui_echo
                    pause
                    ;;
                3)
                    loc="$(wifi_prompt_existing_location)"
                    [[ -z "$loc" ]] && { sleep 1; continue; }

                    log_section "Baseline delete requested: $loc"
                    wifi_delete_location "$loc"
                    status=$?
                    wifi_set_status "wifi_baseline_delete" "$status"

                    ui_echo
                    if [[ $status -eq 0 ]]; then
                        ui_echo "[${GREEN}✔${NC}] ${GREEN}Deleted baseline location: ${BOLD}$loc${NC}"
                        log_event "[OK] Baseline location deleted ($loc)"
                    else
                        ui_echo "[${YELLOW}!${NC}] ${YELLOW}Delete cancelled or failed for: ${BOLD}$loc${NC}"
                        log_event "[INFO] Baseline delete cancelled/failed ($loc)"
                    fi
                    ui_echo
                    pause
                    ;;
                q|Q)
                    return 0
                    ;;
                *)
                    ui_echo "${RED}Invalid choice${NC}"
                    sleep 1
                    ;;
            esac
        done
    }


    # ==========================
    # WIFI SUBMENU
    # ==========================
    wifi_menu() {
        local wchoice status

        # mark main module "wifi" as touched when entering
        MODULE_STATUS[wifi]="✔ done"

        while true; do
            ui_clear
            ui_echo
	    ui_echo "${BOLD}${CYAN}        _____ _______ _______ _______ _______ _______ _     _ _______  ______"
            ui_echo " |        |   |  |  | |______ |______ |______ |______ |____/  |______ |_____/"
            ui_echo " |_____ __|__ |  |  | |______ ______| |______ |______ |    \\_ |______ |    \\_"
            ui_echo "        WiFi tools                                             version ${LIMESEEKER_VERSION}"
            ui_echo "-----------------------------------------------------------------------------${NC}"
            ui_status_block
            ui_echo

            ui_echo "${BOLD}${CYAN}WiFi modules:${NC}"
            ui_echo "1) WiFi discovery    (collect raw scan data)        $(wifi_status_color "${WIFI_STATUS[wifi_discovery]}")"
            ui_echo "2) WiFi analysis     (analyze scan)                 $(wifi_status_color "${WIFI_STATUS[wifi_analysis]}")"
            ui_echo "3) Scan all modules"
            ui_echo
            ui_echo "${BOLD}${CYAN}Baselines:${NC}"
	    ui_echo "4) Baseline manager  (save results                  $(wifi_status_color "${WIFI_STATUS[wifi_baseline_check]}")"
            ui_echo
            ui_echo "q) Back to main menu"
            ui_echo
            ui_echo

            if ! ui_read -rp "Select option: " wchoice; then
                handle_eof
            fi

            status=0

            case "$wchoice" in
                1)
                    log_section "Running module: wifi_discovery"
                    wifi_discovery
                    status=$?
                    wifi_set_status "wifi_discovery" "$status"
                    ;;
                2)
                    log_section "Running module: wifi_analysis"
                    wifi_analysis
                    status=$?
                    wifi_set_status "wifi_analysis" "$status"
                    ;;
                3)
                    log_section "Running module: wifi_discovery"
                    wifi_discovery
                    status=$?
                    wifi_set_status "wifi_discovery" "$status"
                    if [[ $status -ne 0 ]]; then
                        ui_echo
                        ui_echo "[${RED}✖${NC}] ${RED}WiFi discovery failed${NC}"
                        log_event "[FAIL] WiFi discovery failed"
                        ui_echo
                        pause
                        continue
                    fi

                    log_section "Running module: wifi_analysis"
                    wifi_analysis
                    status=$?
                    wifi_set_status "wifi_analysis" "$status"
                    if [[ $status -ne 0 ]]; then
                        ui_echo
                        ui_echo "[${RED}✖${NC}] ${RED}WiFi analysis failed${NC}"
                        log_event "[FAIL] WiFi analysis failed"
                        ui_echo
                        pause
                        continue
                    fi

                    ui_echo
                    if [[ $status -eq 0 ]]; then
                        ui_echo "[${GREEN}✔${NC}] ${GREEN}WiFi scan-all completed${NC}"
                        log_event "[OK] WiFi scan-all completed"
                    else
                        ui_echo "[${RED}✖${NC}] ${RED}WiFi scan-all finished with errors${NC}"
                        log_event "[FAIL] WiFi scan-all finished with errors"
                    fi
                    ui_echo
                    pause
                    continue
                    ;;
                4)
                    wifi_baseline_manager
                    status=$?
                    # baseline manager is a menu, not a single module run
                    ;;
                q|Q)
                    return 0
                    ;;
                *)
                    ui_echo "${RED}Invalid choice${NC}"
                    sleep 1
                    continue
                    ;;
            esac

            ui_echo
            if [[ $status -eq 0 ]]; then
                ui_echo "[${GREEN}✔${NC}] ${GREEN}WiFi task completed successfully${NC}"
                log_event "[OK] WiFi task completed successfully"
            else
                ui_echo "[${RED}✖${NC}] ${RED}WiFi task failed or was aborted${NC}"
                log_event "[FAIL] WiFi task failed or aborted"
            fi
            ui_echo
            pause
        done
    }


# ==========================
# NETWORK SUBMENU
# ==========================
network_menu() {
    local nchoice status

MODULE_STATUS[network]="✔ done"

while true; do
    network_restore_tty
    ui_clear
    ui_echo
    ui_echo "${BOLD}${CYAN}        _____ _______ _______ _______ _______ _______ _     _ _______  ______"
    ui_echo " |        |   |  |  | |______ |______ |______ |______ |____/  |______ |_____/"
    ui_echo " |_____ __|__ |  |  | |______ ______| |______ |______ |    \\_ |______ |    \\_"
    ui_echo "        Network tools                                          version ${LIMESEEKER_VERSION}"
    ui_echo "-----------------------------------------------------------------------------${NC}"
    ui_status_block
    ui_echo

    ui_echo "${BOLD}${CYAN}Network modules:${NC}"
    ui_echo "1) Network vulnerability scan   (scan local network)   $(wifi_status_color "${WIFI_STATUS[network_vulnerability]}")"

    ui_echo "2) Network result               (analyze scan)         $(wifi_status_color "${WIFI_STATUS[network_result]}")"

    ui_echo
    ui_echo "${BOLD}${CYAN}Results:${NC}"
    ui_echo "3) Network history              (save results)         $(wifi_status_color "${WIFI_STATUS[network_history_menu]}")"

    ui_echo
    ui_echo "q) Back to main menu"
    ui_echo
    ui_echo

    ui_read -rp "Select option: " nchoice

    status=0
    case "${nchoice,,}" in
      1) network_vulnerability; status=$? ;;
      2) network_result; status=$? ;;
      3) network_history_menu; status=$? ;;
    Q|q) return 0 ;;
      *) ui_echo "${RED}Invalid choice${NC}"; sleep 1 ;;
    esac
  done
}



    # ==========================
    # MAIN MENU LOOP
    # ==========================
    show_intro

    while true; do
        modules_to_run=()

        ui_clear
        show_intro
        log_pause

        ui_echo "${BOLD}${CYAN}System Analysis:${NC}"
        ui_echo "1) Local inventory              $(status_color "${MODULE_STATUS[local_inventory]}")"
        ui_echo "2) Local security               $(status_color "${MODULE_STATUS[local_security]}")"
        ui_echo "3) System hardening             $(status_color "${MODULE_STATUS[system_hardening]}")"
        ui_echo "4) Scan all system modules"
        ui_echo
        ui_echo "${BOLD}${CYAN}Network & WiFi Analysis:${NC}"
        ui_echo "5) Network tools                $(status_color "${MODULE_STATUS[network]}")"
        ui_echo "6) WiFi tools                   $(status_color "${MODULE_STATUS[wifi]}")"
        ui_echo
        ui_echo "${BOLD}${CYAN}Options:${NC}"
        ui_echo "i) Module information"
        ui_echo "c) Clear module status"
        ui_echo
        ui_echo "q) Quit"
        ui_echo
        ui_echo

        if ! ui_read -rp "Select option: " choice; then
            handle_eof
        fi

        case "$choice" in
            1) modules_to_run=(local_inventory) ;;
            2) modules_to_run=(local_security) ;;
            3) modules_to_run=(system_hardening) ;;
            4) modules_to_run=(local_inventory local_security system_hardening) ;;
            5)
                network_menu
                continue
                ;;
            6)
                wifi_menu
                continue
                ;;
            i|I)
                info_menu
                continue
                ;;
            c|C)
                reset_module_status
                continue
                ;;
            q|Q)
                ui_echo "${YELLOW}Exiting LimeSeeker...${NC}"
                ui_echo "${YELLOW}Clearing sudo privileges...${NC}"
                log_footer
                log_event "User exited LimeSeeker"
                sudo -k
                return 0
                ;;
            *)
                ui_echo "${RED}Invalid choice${NC}"
                sleep 1
                continue
                ;;
        esac

        for module in "${modules_to_run[@]}"; do
            log_section "Running module: $module"
            $module
            status=$?

            if [[ $status -eq 0 ]]; then
                MODULE_STATUS["$module"]="✔ done"
                ui_echo
                ui_echo "[${GREEN}✔${NC}] ${GREEN}${module//_/ } completed successfully${NC}"
                log_event "[OK] $module completed successfully"
            else
                MODULE_STATUS["$module"]="✖ failed"
                ui_echo
                ui_echo "[${RED}✖${NC}] ${RED}${module//_/ } failed or was aborted${NC}"
                log_event "[FAIL] $module failed or aborted"
            fi
        done

        ui_echo
        pause
    done
}
