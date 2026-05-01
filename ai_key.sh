#!/usr/bin/env bash
# =============================================================================
# ai_key.sh — Moto Edge 60 Pro AI Key Switcher
#
# Usage:
#   bash ai_key.sh apply   — Single press → Gemini, Double press → Camera
#   bash ai_key.sh revert  — Single/Double disabled, Hold → None
#   bash ai_key.sh motoai  — Restore Moto AI on hold
#   bash ai_key.sh status  — Show current settings
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}"; }

GEMINI_INTENT="intent:#Intent;component=com.google.android.apps.bard/.shellapp.BardEntryPointActivity;launchFlags=0x10008000;S.extra_type=tap_app_quick_single;end"
CAMERA_INTENT="intent:#Intent;action=android.media.action.STILL_IMAGE_CAMERA;launchFlags=0x10008000;S.extra_type=tap_app_quick_double;end"
MOTOAI_DOUBLE="intent:#Intent;action=com.motorola.uxcore.action.MOTO_AI_HERO_ACTION;launchFlags=0x10008000;S.key_extra_moto_ai=category_llm_summarize;end"

check_adb() {
  command -v adb &>/dev/null || error "adb not found."

  local devices
  devices=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)

  [[ "$devices" -gt 0 ]] || error "No device connected. Enable USB Debugging and connect phone."

  success "Device connected: $(adb devices | grep 'device$' | awk '{print $1}')"
}

apply() {
  header "Applying — Single press → Gemini | Double press → Camera"

  adb shell "settings put system tap_app_quick_single '${GEMINI_INTENT}'" \
    && success "Single press → Gemini." || warn "Failed single press."

  adb shell "settings put system tap_app_quick_double '${CAMERA_INTENT}'" \
    && success "Double press → Camera." || warn "Failed double press."

  # Hold option removed from custom mapping.
  # Keep Moto AI default enabled for hold.
  adb shell "settings put system tap_app_quick_press_hold 7" \
    && success "Hold → Moto AI default." || warn "Failed hold default."

  adb shell "settings delete system tap_app_main_press_hold" &>/dev/null || true
  adb shell "settings delete system my_key_tap_app" &>/dev/null || true

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗"
  echo -e "║   AI Key mapped!                             ║"
  echo -e "║   Single press  → Gemini                     ║"
  echo -e "║   Double press  → Camera                     ║"
  echo -e "║   Hold          → Moto AI default            ║"
  echo -e "╚══════════════════════════════════════════════╝${RESET}"
}

revert() {
  header "Reverting — AI Key custom actions off"

  adb shell "settings put system tap_app_quick_single 0" \
    && success "Single press → 0." || warn "Failed."

  adb shell "settings put system tap_app_quick_double 0" \
    && success "Double press → 0." || warn "Failed."

  adb shell "settings put system tap_app_quick_press_hold 0" \
    && success "Hold → None." || warn "Failed."

  adb shell "settings delete system tap_app_main_press_hold" &>/dev/null || true
  adb shell "settings delete system my_key_tap_app" &>/dev/null || true

  success "Reverted."
}

motoai() {
  header "Restoring Moto AI"

  adb shell "settings put system tap_app_quick_double '${MOTOAI_DOUBLE}'" \
    && success "Double press → Moto AI." || warn "Failed."

  adb shell "settings put system tap_app_quick_press_hold 7" \
    && success "Hold → Moto AI." || warn "Failed."
}

status() {
  header "Current AI Key Settings"

  echo ""
  echo -e "${BOLD}tap_app_quick_single:${RESET}"
  adb shell settings get system tap_app_quick_single

  echo ""
  echo -e "${BOLD}tap_app_quick_double:${RESET}"
  adb shell settings get system tap_app_quick_double

  echo ""
  echo -e "${BOLD}tap_app_quick_press_hold:${RESET}"
  adb shell settings get system tap_app_quick_press_hold

  echo ""
  echo -e "${BOLD}tap_app_main_press_hold:${RESET}"
  adb shell settings get system tap_app_main_press_hold

  echo ""
  echo -e "${BOLD}my_key_tap_app:${RESET}"
  adb shell settings get system my_key_tap_app
  echo ""
}

usage() {
  echo ""
  echo -e "${BOLD}Usage:${RESET} bash ai_key.sh <command>"
  echo ""
  echo -e "  ${CYAN}apply${RESET}   — Single → Gemini | Double → Camera"
  echo -e "  ${CYAN}revert${RESET}  — Disable single/double/hold"
  echo -e "  ${CYAN}motoai${RESET}  — Restore Moto AI"
  echo -e "  ${CYAN}status${RESET}  — Show settings"
  echo ""
}

main() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║   Moto Edge 60 Pro — AI Key Switcher        ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${RESET}"

  case "${1:-}" in
    apply)  check_adb; apply ;;
    revert) check_adb; revert ;;
    motoai) check_adb; motoai ;;
    status) check_adb; status ;;
    *) usage ;;
  esac
}

main "$@"
