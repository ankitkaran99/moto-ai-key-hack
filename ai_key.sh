#!/usr/bin/env bash
# =============================================================================
#  ai_key.sh — Map / Revert Moto Edge 60 Pro AI Key → Gemini
#  Usage:
#    bash ai_key.sh apply   — AI Key opens Gemini
#    bash ai_key.sh revert  — AI Key does nothing (true factory default)
#    bash ai_key.sh status  — Show current settings
# =============================================================================

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}"; }

# ── Gemini intent (confirmed working) ─────────────────────────────────────────
GEMINI_COMPONENT="com.google.android.apps.bard/.shellapp.BardEntryPointActivity"
GEMINI_FLAGS="0x10008000"

GEMINI_SINGLE="intent:#Intent;component=${GEMINI_COMPONENT};launchFlags=${GEMINI_FLAGS};S.extra_type=tap_app_quick_single;end"
GEMINI_DOUBLE="intent:#Intent;component=${GEMINI_COMPONENT};launchFlags=${GEMINI_FLAGS};S.extra_type=tap_app_quick_double;end"
GEMINI_HOLD="intent:#Intent;component=${GEMINI_COMPONENT};launchFlags=${GEMINI_FLAGS};S.extra_type=tap_app_quick_press_hold;end"

# ── Moto AI double press intent (confirmed from device) ───────────────────────
MOTOAI_ACTION="com.motorola.uxcore.action.MOTO_AI_HERO_ACTION"
MOTOAI_FLAGS="0x10008000"
MOTOAI_DOUBLE="intent:#Intent;action=${MOTOAI_ACTION};launchFlags=${MOTOAI_FLAGS};S.key_extra_moto_ai=category_llm_summarize;end"

# ── Check adb ─────────────────────────────────────────────────────────────────
check_adb() {
  if ! command -v adb &>/dev/null; then
    error "adb not found. Run: source ~/.bashrc  or open a new Git Bash window."
  fi
  local devices
  devices=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)
  if [[ "$devices" -eq 0 ]]; then
    error "No device connected. Enable USB Debugging on your phone and connect via USB."
  fi
  success "Device connected: $(adb devices | grep 'device$' | awk '{print $1}')"
}

# ── Apply: AI Key → Gemini ────────────────────────────────────────────────────
apply() {
  header "Applying — AI Key → Gemini"

  info "Setting single press → Gemini..."
  adb shell "settings put system tap_app_quick_single '${GEMINI_SINGLE}'" \
    && success "Single press set." || warn "Failed to set single press."

  info "Setting double press → Gemini..."
  adb shell "settings put system tap_app_quick_double '${GEMINI_DOUBLE}'" \
    && success "Double press set." || warn "Failed to set double press."

  info "Setting long press → Gemini..."
  adb shell "settings put system tap_app_main_press_hold '${GEMINI_HOLD}'" \
    && success "Long press set." || warn "Failed to set long press."

  info "Cleaning up legacy keys..."
  adb shell "settings delete system my_key_tap_app" &>/dev/null || true
  adb shell "settings delete system tap_app_quick_press_hold" &>/dev/null || true

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗"
  echo -e "║   AI Key now opens Gemini! 🎉               ║"
  echo -e "╚══════════════════════════════════════════════╝${RESET}"
  echo -e "  ${YELLOW}Note: Settings reset on reboot — re-run to reapply.${RESET}"
  echo ""
}

# ── Revert: AI Key → true factory default (do nothing) ───────────────────────
revert() {
  header "Reverting — AI Key → Factory Default (no action)"

  # True factory state confirmed from device:
  # All tap_app_* = 0 (no action), my_key_tap_app deleted entirely.
  # Using 5 causes NoneReminderDialogActivity popup — 0 is the real default.

  info "Setting all gestures → 0 (no action)..."
  adb shell "settings put system tap_app_quick_single 0" \
    && success "Single press → 0." || warn "Failed."

  adb shell "settings put system tap_app_quick_double 0" \
    && success "Double press → 0." || warn "Failed."

  adb shell "settings put system tap_app_main_press_hold 0" \
    && success "Long press → 0." || warn "Failed."

  adb shell "settings put system tap_app_quick_press_hold 0" \
    && success "Press hold → 0." || warn "Failed."

  info "Deleting my_key_tap_app..."
  adb shell "settings delete system my_key_tap_app" &>/dev/null || true
  success "my_key_tap_app deleted."

  echo ""
  echo -e "${BOLD}${YELLOW}╔══════════════════════════════════════════════╗"
  echo -e "║   AI Key restored — does nothing (default). ║"
  echo -e "╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${CYAN}To restore Moto AI double press action:${RESET}"
  echo -e "  bash ai_key.sh motoai"
  echo ""
}

# ── Moto AI: restore double press → Moto AI summarize ────────────────────────
motoai() {
  header "Restoring double press → Moto AI"

  info "Setting double press → Moto AI summarize..."
  adb shell "settings put system tap_app_quick_double '${MOTOAI_DOUBLE}'" \
    && success "Double press → Moto AI." || warn "Failed."

  info "Setting press hold → 7 (Moto AI)..."
  adb shell "settings put system tap_app_quick_press_hold 7" \
    && success "Press hold → 7." || warn "Failed."

  echo ""
  echo -e "${BOLD}${YELLOW}╔══════════════════════════════════════════════╗"
  echo -e "║   Double press restored to Moto AI.         ║"
  echo -e "╚══════════════════════════════════════════════╝${RESET}"
  echo ""
}

# ── Status: show current settings ────────────────────────────────────────────
status() {
  header "Current AI Key Settings"

  local single double hold hold2 keyapp
  single=$(adb shell settings get system tap_app_quick_single 2>/dev/null)
  double=$(adb shell settings get system tap_app_quick_double 2>/dev/null)
  hold=$(adb shell settings get system tap_app_main_press_hold 2>/dev/null)
  hold2=$(adb shell settings get system tap_app_quick_press_hold 2>/dev/null)
  keyapp=$(adb shell settings get system my_key_tap_app 2>/dev/null)

  echo ""
  echo -e "  ${BOLD}tap_app_quick_single:${RESET}       $single"
  echo -e "  ${BOLD}tap_app_quick_double:${RESET}       $double"
  echo -e "  ${BOLD}tap_app_main_press_hold:${RESET}    $hold"
  echo -e "  ${BOLD}tap_app_quick_press_hold:${RESET}   $hold2"
  echo -e "  ${BOLD}my_key_tap_app:${RESET}             $keyapp"
  echo ""

  if echo "$single" | grep -q "bard"; then
    echo -e "  ${GREEN}${BOLD}▶ Mode: GEMINI${RESET}"
  elif [[ "$single" == "0" ]] && [[ "$keyapp" == "null" || -z "$keyapp" ]]; then
    echo -e "  ${YELLOW}${BOLD}▶ Mode: FACTORY DEFAULT (no action)${RESET}"
  elif [[ "$single" == "5" ]] && echo "$keyapp" | grep -q "Intent"; then
    echo -e "  ${RED}${BOLD}▶ Mode: BROKEN — run: bash ai_key.sh revert${RESET}"
  else
    echo -e "  ${CYAN}${BOLD}▶ Mode: CUSTOM / UNKNOWN${RESET}"
  fi
  echo ""
}

# ── Help ─────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo -e "${BOLD}Usage:${RESET} bash ai_key.sh <command>"
  echo ""
  echo -e "  ${CYAN}apply${RESET}   — Map AI Key → Gemini (single + double + long press)"
  echo -e "  ${CYAN}revert${RESET}  — Restore factory default (AI Key does nothing)"
  echo -e "  ${CYAN}motoai${RESET}  — Restore double press → Moto AI summarize"
  echo -e "  ${CYAN}status${RESET}  — Show current settings and detected mode"
  echo ""
  echo -e "${BOLD}Examples:${RESET}"
  echo -e "  bash ai_key.sh apply"
  echo -e "  bash ai_key.sh revert"
  echo -e "  bash ai_key.sh motoai"
  echo -e "  bash ai_key.sh status"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║   Moto Edge 60 Pro — AI Key Switcher        ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${RESET}"

  case "${1:-}" in
    apply)  check_adb; apply  ;;
    revert) check_adb; revert ;;
    motoai) check_adb; motoai ;;
    status) check_adb; status ;;
    *)      usage ;;
  esac
}

main "$@"
