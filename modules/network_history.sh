#!/usr/bin/env bash

network_reports_dir() {
  local d="$BASE_DIR/reports/network"
  mkdir -p "$d" 2>/dev/null || true
  echo "$d"
}

network_latest_file() {
  echo "$(network_reports_dir)/latest.log"
}

network_saved_dir() {
  local d
  d="$(network_reports_dir)/saved"
  mkdir -p "$d" 2>/dev/null || true
  echo "$d"
}

network_saved_index() {
  echo "$(network_saved_dir)/index.tsv"
}

network__sanitize_name() {
  echo "$1" | tr -cd 'A-Za-z0-9._ -' | sed 's/[[:space:]]\+/_/g; s/^_//; s/_$//'
}

network_restore_tty() {
  stty echo 2>/dev/null || true
  tput cnorm 2>/dev/null || true
}

network_history__index_init() {
  mkdir -p "$(network_saved_dir)" 2>/dev/null || true
  [[ -f "$(network_saved_index)" ]] || : >"$(network_saved_index)"
}

network_history__list_newest_first() {
  network_history__index_init
  [[ -s "$(network_saved_index)" ]] || return 0
  sort -t $'\t' -k1,1nr "$(network_saved_index)"
}

network_history__print_top5() {
  local i=0
  while IFS=$'\t' read -r epoch id name file; do
    [[ -z "$id" ]] && continue
    i=$((i+1))
    local when
    when="$(date -d "@$epoch" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$epoch")"
    ui_echo " ${DIM}${i})${NC} ${BOLD}${name}${NC}  ${DIM}($when)${NC}"
    [[ $i -ge 5 ]] && break
  done < <(network_history__list_newest_first)

  [[ $i -eq 0 ]] && ui_echo " ${DIM}(none saved yet)${NC}"
}

network_history__print_all_numbered() {
  local n=0
  while IFS=$'\t' read -r epoch id name file; do
    [[ -z "$id" ]] && continue
    n=$((n+1))
    local when
    when="$(date -d "@$epoch" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$epoch")"
    ui_echo " ${BOLD}${n})${NC} ${name}  ${DIM}($when)${NC}"
  done < <(network_history__list_newest_first)

  [[ $n -eq 0 ]] && ui_echo "${DIM}(none saved yet)${NC}"
}

network_history__get_by_number() {
  local want="$1" n=0
  while IFS=$'\t' read -r epoch id name file; do
    [[ -z "$id" ]] && continue
    n=$((n+1))
    if [[ "$n" -eq "$want" ]]; then
      printf "%s\t%s\t%s\t%s\n" "$epoch" "$id" "$name" "$file"
      return 0
    fi
  done < <(network_history__list_newest_first)
  return 1
}

# ------------------------------------------------------------
# View a file with ENTER to return (NO less/pager)
# ------------------------------------------------------------
network_view_file_enter() {
  local f="$1"

  network_restore_tty
  ui_clear
  ui_echo "${BOLD}${CYAN}Viewing result${NC}"
  ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
  ui_echo

  if [[ ! -s "$f" ]]; then
    ui_echo "${YELLOW}[INFO]${NC} File not found or empty:"
    ui_echo "${DIM}$f${NC}"
    ui_echo
    ui_read -rp "Press ENTER to return... " _
    network_restore_tty
    return 0
  fi

  cat "$f"

  ui_echo
  ui_read -rp "Press ENTER to return... " _
  network_restore_tty
}

# ------------------------------------------------------------
# Latest result view (NO less)
# ------------------------------------------------------------
network_result() {
  local latest
  latest="$(network_latest_file)"

  network_restore_tty
  ui_clear
  ui_echo "${BOLD}${CYAN}Network result (latest)${NC}"
  ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
  ui_echo

  if [[ ! -s "$latest" ]]; then
    ui_echo "${YELLOW}[INFO]${NC} No latest result found yet."
    ui_echo "${DIM}Run a scan first.${NC}"
    ui_echo
    ui_read -rp "Press ENTER to return... " _
    network_restore_tty
    return 0
  fi

  network_view_file_enter "$latest"
  return 0
}

# ------------------------------------------------------------
# Choose a saved result to read (NO less)
# ------------------------------------------------------------
network_history_choose_read() {
  local choice row epoch id name file

  network_restore_tty
  ui_clear
  ui_echo "${BOLD}${CYAN}Choose network result to read${NC}"
  ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
  ui_echo

  network_history__print_all_numbered
  ui_echo
  ui_echo "q) Back"
  ui_echo

  ui_read -rp "Select number: " choice
  [[ "${choice,,}" == "q" ]] && return 0
  [[ "$choice" =~ ^[0-9]+$ ]] || return 0

  row="$(network_history__get_by_number "$choice")" || {
    ui_echo "${RED}Invalid selection.${NC}"
    sleep 1
    return 0
  }

  IFS=$'\t' read -r epoch id name file <<<"$row"
  network_view_file_enter "$file"
  return 0
}

network_history_list_menu() {
  network_restore_tty
  ui_clear
  ui_echo "${BOLD}${CYAN}Network results list${NC}"
  ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
  ui_echo

  network_history__print_all_numbered
  ui_echo
  ui_read -rp "Press ENTER to return... " _
  network_restore_tty
  return 0
}

network_history_save_latest() {
  local latest name safe outdir ts epoch id file

  latest="$(network_latest_file)"
  if [[ ! -s "$latest" ]]; then
    ui_echo "${YELLOW}[INFO]${NC} No latest result to save."
    sleep 1
    return 1
  fi

  ui_echo
  ui_read -rp "Enter a name for this result: " name
  safe="$(network__sanitize_name "$name")"
  if [[ -z "$safe" ]]; then
    ui_echo "${RED}Invalid name.${NC}"
    sleep 1
    return 1
  fi

  outdir="$(network_saved_dir)"
  ts="$(date +%Y%m%d_%H%M%S)"
  epoch="$(date +%s)"
  id="$ts"
  file="$outdir/${id}_${safe}.log"

  cp -f "$latest" "$file" 2>/dev/null || {
    ui_echo "${RED}[ERROR]${NC} Could not save result."
    sleep 1
    return 1
  }

  network_history__index_init
  printf "%s\t%s\t%s\t%s\n" "$epoch" "$id" "$safe" "$file" >>"$(network_saved_index)"

  ui_echo "${GREEN}[OK]${NC} Saved result: ${BOLD}${safe}${NC}"
  log_to_file "[OK] Network result saved: name=$safe file=$file"
  sleep 1
  return 0
}

network_history_delete_result() {
  local choice row epoch id name file confirm tmp

  network_restore_tty
  ui_clear
  ui_echo "${BOLD}${CYAN}Delete saved result${NC}"
  ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
  ui_echo

  network_history__print_all_numbered
  ui_echo
  ui_echo "q) Back"
  ui_echo

  ui_read -rp "Enter number to delete: " choice
  [[ "${choice,,}" == "q" ]] && return 0
  [[ "$choice" =~ ^[0-9]+$ ]] || return 0

  row="$(network_history__get_by_number "$choice")" || {
    ui_echo "${RED}Invalid selection.${NC}"
    sleep 1
    return 0
  }

  IFS=$'\t' read -r epoch id name file <<<"$row"

  ui_echo
  ui_echo "${YELLOW}${BOLD}[WARNING]${NC} Delete saved result:"
  ui_echo "  ${BOLD}${name}${NC}"
  ui_echo
  ui_read -rp "Type YES to confirm delete: " confirm
  [[ "${confirm^^}" != "YES" ]] && {
    ui_echo "${YELLOW}Cancelled.${NC}"
    sleep 1
    return 0
  }

  rm -f -- "$file" 2>/dev/null || true

  tmp="$(mktemp)"
  awk -F'\t' -v del="$id" 'NF>=4 && $2!=del {print $0}' "$(network_saved_index)" >"$tmp"
  mv "$tmp" "$(network_saved_index)"

  ui_echo "${GREEN}[OK]${NC} Deleted: ${BOLD}${name}${NC}"
  log_to_file "[OK] Network result deleted: name=$name file=$file"
  sleep 1
  return 0
}

network_history_menu() {
  local choice

  while true; do
    network_restore_tty
    ui_clear
    ui_echo "${BOLD}${CYAN}Network history${NC}"
    ui_echo "${CYAN}-----------------------------------------------------------------------------${NC}"
    ui_echo
    ui_echo "${BOLD}${CYAN}5 latest saved results:${NC}"
    ui_echo "------------------------------------------------------------"
    network_history__print_top5
    ui_echo
    ui_echo "${BOLD}${CYAN}Actions:${NC}"
    ui_echo "1) Choose network result to read"
    ui_echo "2) Network results list"
    ui_echo "3) Save latest result"
    ui_echo "4) Delete saved result"
    ui_echo
    ui_echo "q) Back"
    ui_echo
    ui_read -rp "Select option: " choice

    case "${choice,,}" in
      1) network_history_choose_read ;;
      2) network_history_list_menu ;;
      3) network_history_save_latest ;;
      4) network_history_delete_result ;;
      q) return 0 ;;
      *) ui_echo "${RED}Invalid choice${NC}"; sleep 1 ;;
    esac
  done
}
