#!/usr/bin/env bash

# -------------
# Status flags
# -------------
FLAG_HANDLED=false

# ---------------
# Logging on/off
# ---------------
LIME_NO_LOG=0

# ---------
# Parsning
# ---------
parse_flags() {
	while [[ $# -gt 0 ]]; do
            case "$1" in
            -n|--no-log)
                LOGGING_ENABLED=false
                ;;
	    -h|--help)
	        show_help
                FLAG_HANDLED=true
                exit 0
                ;;		
            -v|--version)
                show_version
                FLAG_HANDLED=true
                exit 0
                ;;
            -m|--modules)
                show_modules
                FLAG_HANDLED=true
                exit 0
                ;;
	    -l|--legal)
                show_legal
		FLAG_HANDLED=true
		exit 0
		;;
	    -a|--about)
		show_about    
	        FLAG_HANDLED=true
                exit 0
                ;;	
            *)
                echo "Unknown option: $1"
                echo "Use --help for available options"
                exit 1
                ;;
        esac
        shift
    done
}

# ----------------
# Help, -h/--help
# ----------------
show_help() {
    clear
    echo
    echo "    _    _ _  _ ____ ____ ____ ____ _  _ ____ ____ "
    echo "    |    | |\/| |___ [__  |___ |___ |_/  |___ |__/ "
    echo "    |___ | |  | |___ ___] |___ |___ | \_ |___ |  \  Help"
    echo "-------------------------------------------------------------"
    echo
    echo "LimeSeeker is a interactive Linux and network vulnerability"
    echo "scanning tool."
    echo "Use only on systems you own or have permission to test."
    echo
    echo
    echo -e "${BOLD}Requirements:${NC}"
    echo
    echo "  • Must be run with sudo privileges"
    echo "  • Linux system with standard utilities"
    echo
    echo
    echo -e "${BOLD}Options:${NC}"
    echo
    echo "  -h, --help       Show this help message and exit"
    echo "  -a, --about      Show the purpose and philosophy behind LimeSeeker"
    echo "  -v, --version    Show script version and author"
    echo "  -l, --leagl      Show legal notive and usage authorization"
    echo "  -m, --modules    List available modules and their descriptions"
    echo "  -n, --no-log     Run the script without creating a log file"
    echo
    echo
    echo "------------------------------------------------------------"
}

# ----------------------
# Version, -v/--version
# ----------------------
show_version() {
    clear
    echo
    echo "    _    _ _  _ ____ ____ ____ ____ _  _ ____ ____ "
    echo "    |    | |\/| |___ [__  |___ |___ |_/  |___ |__/ "
    echo "    |___ | |  | |___ ___] |___ |___ | \_ |___ |  \  Version"
    echo "-------------------------------------------------------------"
    echo
    echo -e "${BOLD}Version :${NC} ${LIMESEEKER_VERSION}"
    echo
    echo -e "${BOLD}Author  :${NC} ${LIMESEEKER_AUTHOR}"
    echo
    echo
    echo "------------------------------------------------------------"
}

# ----------------------
# Modules, -m/--modules
# ----------------------
show_modules() {
    
    local modules=("local_inventory" "local_security" "system_hardening" "network_vulnerability" "wifi_tools" "wifi_discovery" "wifi_analysis" "wifi_baseline_create" "wifi_baseline_check")

    clear
    echo
    echo "    _    _ _  _ ____ ____ ____ ____ _  _ ____ ____ "
    echo "    |    | |\/| |___ [__  |___ |___ |_/  |___ |__/ "
    echo "    |___ | |  | |___ ___] |___ |___ | \_ |___ |  \  Modules" 
    echo "-------------------------------------------------------------"
    
    for mod in "${modules[@]}"; do
        
        local DESC_VAR="${mod}_DESC"
        local PRIV_VAR="${mod}_PRIVILEGES"
        local SAFETY_VAR="${mod}_SAFETY"
        
        
        local display_name=$(echo "$mod" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        
        
        echo -e "${BOLD}$display_name${NC}"
        
        echo -e "  ${!DESC_VAR:-No description available.}"
        
        
        if [[ -n "${!PRIV_VAR}" ]]; then
            echo -e "  Privileges: ${!PRIV_VAR}"
        fi

        if [[ -n "${!SAFETY_VAR}" ]]; then
            echo -e "  Safety: ${!SAFETY_VAR}"
        fi
        
        echo 
    done
    
    echo "-------------------------------------------------------------"
    exit 0
}

# -----------------
# Legal, -l/--legal
# -----------------
show_legal() {
    clear
    echo
    echo "    _    _ _  _ ____ ____ ____ ____ _  _ ____ ____ "
    echo "    |    | |\/| |___ [__  |___ |___ |_/  |___ |__/ "
    echo "    |___ | |  | |___ ___] |___ |___ | \_ |___ |  \  Legal"
    echo "-------------------------------------------------------------"
    echo
    echo "LimeSeeker is not an exploitation framework."
    echo "It does not perform active attacks or privilege escalation."
    echo "The user is solely responsible for ensuring that scans are"
    echo "conducted only on systems and networks they own or have" 
    echo "explicit authorization to test."
    echo
    echo
    echo "-------------------------------------------------------------"
}
# ------------------
# About, a-/--about
# ------------------
show_about() {
    clear
    echo
    echo "    _    _ _  _ ____ ____ ____ ____ _  _ ____ ___  "
    echo "    |    | |\/| |___ [__  |___ |___ |_/  |___ |__/ "
    echo "    |___ | |  | |___ ___] |___ |___ | \_ |___ |  \  About" 
    echo "-------------------------------------------------------------"
    echo
    echo "LimeSeeker is a modular Linux and network security scanning tool"
    echo "designed for reconnaissance, auditing, and situational awareness."
    echo
    echo "The tool provides a structured overview of a system’s configuration,"
    echo "security posture, network exposure, and wireless environment through"
    echo "a clean, menu-driven interface."
    echo
    echo
    echo -e "${BOLD}Purpose:${NC}"
    echo
    echo "LimeSeeker is intended to assist with:"
    echo
    echo "  • Local system reconnaissance"
    echo "  • Security posture assessment"
    echo "  • Network and service discovery"
    echo "  • Wireless environment mapping"
    echo "  • Pre-audit and post-installation checks"
    echo
    echo "It is suitable for:"
    echo "  • Security testing labs"
    echo "  • System hardening verification"
    echo "  • Educational use"
    echo "  • Controlled penetration testing environments"
    echo
    echo
    echo -e "${BOLD}Design Philosophy:${NC}"
    echo
    echo "LimeSeeker is designed to answer one fundamental question:"
    echo "What does this system and its environment look like from a security" 
    echo "perspective?"
    echo
    echo "It provides clarity, not exploitation, and serves as a foundation"
    echo "for informed security decisions."
    echo
    echo "LimeSeeker follows a few core principles:"
    echo
    echo "  • Modular: Each scan is self-contained and can be extended or replaced."
    echo "  • Transparent: Output is readable and logged without obfuscation."
    echo "  • Minimal assumptions: The tool does not exploit vulnerabilities,"
    echo "    but identifies conditions that may require attention."
    echo "  • Privilege-aware: Root access is only required where technically"
    echo "    necessary."
    echo
    echo
    echo -e "${BOLD}Disclaimer:${NC}"
    echo
    echo "LimeSeeker is not an exploitation framework."
    echo "It does not perform active attacks or privilege escalation."
    echo "The user is solely responsible for ensuring that scans are conducted only" 
    echo "on systems and networks they own or have explicit authorization to test" 
    echo 
    echo
    echo "-------------------------------------------------------------"
}
