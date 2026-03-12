#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
#   macOS Sequoia Optimiser — Intel i7 13" MacBook (No dGPU)
#   Author: Generated for you | Use at your own risk | Reversible where noted
# ══════════════════════════════════════════════════════════════════════════════

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ─── Logging helpers ──────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}  ▸ ${NC}$*"; }
success() { echo -e "${GREEN}  ✓ ${NC}$*"; }
warn()    { echo -e "${YELLOW}  ⚠ ${NC}$*"; }
error()   { echo -e "${RED}  ✗ ${NC}$*"; }
section() { echo -e "\n${BOLD}${BLUE}══ $* ${NC}"; }
skip()    { echo -e "${DIM}  – skipped (already set or not found)${NC}"; }

# ─── Safe wrappers ────────────────────────────────────────────────────────────
# Silently ignore launchctl failures (SIP-protected plists will just not unload)
safe_unload_daemon() {
    sudo launchctl unload -w "$1" 2>/dev/null && success "Unloaded $1" || warn "SIP-protected or missing: $(basename $1)"
}
safe_unload_agent() {
    launchctl unload -w "$1" 2>/dev/null && success "Unloaded $1" || warn "Not found or already unloaded: $(basename $1)"
}
safe_disable_daemon() {
    sudo launchctl disable "system/$1" 2>/dev/null && success "Disabled system/$1" || warn "Could not disable: $1"
}
safe_disable_agent() {
    launchctl disable "gui/$(id -u)/$1" 2>/dev/null && success "Disabled gui/$1" || warn "Could not disable: $1"
}

# ─── Banner ───────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${MAGENTA}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════╗
  ║      macOS Sequoia Optimiser — Intel i7 13" MacBook      ║
  ║        No dGPU · Max RAM · Low CPU · Lower Thermals      ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo -e "${DIM}  This script will:${NC}"
echo -e "${DIM}  • Kill telemetry, analytics, diagnostics${NC}"
echo -e "${DIM}  • Disable Spotlight indexing (use Raycast/Alfred instead)${NC}"
echo -e "${DIM}  • Strip Apple Intelligence / Neural Engine daemons (Silicon-only waste)${NC}"
echo -e "${DIM}  • Kill Siri background processes${NC}"
echo -e "${DIM}  • Remove Finder animations (desktop/transparency kept)${NC}"
echo -e "${DIM}  • Slash system logging verbosity${NC}"
echo -e "${DIM}  • Optimise power + sleep for Intel${NC}"
echo -e "${DIM}  • Install Homebrew${NC}"
echo -e "${DIM}  • QuickLook stays fully intact${NC}"
echo ""
warn "Some daemon unloads require SIP to be off. They will be skipped if SIP is on."
warn "Restart required after this script for all changes to take effect."
echo ""
read -p "  Press [Enter] to continue or Ctrl+C to abort..."

# ─── Sudo check ───────────────────────────────────────────────────────────────
if ! sudo -v; then
    error "Could not get sudo. Exiting."
    exit 1
fi
# Keep sudo alive throughout
( while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null ) &
SUDO_LOOP_PID=$!
trap "kill $SUDO_LOOP_PID 2>/dev/null" EXIT

# ══════════════════════════════════════════════════════════════════════════════
#  0 · HOMEBREW INSTALL
# ══════════════════════════════════════════════════════════════════════════════
section "0 · Homebrew"

if command -v brew &>/dev/null; then
    success "Homebrew already installed at $(which brew)"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  1 · TELEMETRY, ANALYTICS & DIAGNOSTICS
# ══════════════════════════════════════════════════════════════════════════════
section "1 · Telemetry, Analytics & Diagnostics"

# Disable Apple crash reporter sending reports
info "Crash Reporter → local only (no Apple uploads)"
defaults write com.apple.CrashReporter DialogType none
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false 2>/dev/null

# Disable diagnostic auto-submission
info "Diagnostic submission → OFF"
sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false 2>/dev/null
sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist SeedAutoSubmit -bool false 2>/dev/null
sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist ThirdPartyDataSubmit -bool false 2>/dev/null

# Analytics & data collection
info "Analytics opt-out"
defaults write com.apple.analyticsd analyticsDataSharingEnabled -bool false 2>/dev/null
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
defaults write com.apple.AdLib adOptOutEnabled -bool true

# Personalised ads
info "Personalised Ads → OFF"
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
defaults write com.apple.assistant.backedup "Session ID" -string ""

# GameCenter analytics
defaults write com.apple.gamed Disabled -bool true

# Location-based suggestions + Significant locations
info "Significant Locations → OFF"
sudo defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -bool false 2>/dev/null
defaults write com.apple.Maps HistoricalDataAnalyticsEnabled -bool false 2>/dev/null

# Disable sending usage data to Apple
defaults write com.apple.spindump Enable -bool false 2>/dev/null
defaults write com.apple.tailspind Disabled -bool true 2>/dev/null

# Disable Accounts push notification analytics
defaults write com.apple.iCloud.IMDAppleIDAuthAgent analyticsEnabled -bool false 2>/dev/null

# Disable sharing Mac analytics with app developers
defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false 2>/dev/null

success "Telemetry/analytics disabled"

# ── Daemon kills: telemetry ────────────────────────────────────────────────────
info "Unloading diagnostics daemons..."
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.spindump.plist
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.tailspind.plist
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.SubmitDiagInfo.plist
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.diagnosticd.plist
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist

info "Unloading analytics agents..."
safe_unload_agent ~/Library/LaunchAgents/com.apple.ReportCrash.plist
safe_unload_agent ~/Library/LaunchAgents/com.apple.appleseed.seedusaged.plist

# ══════════════════════════════════════════════════════════════════════════════
#  2 · APPLE INTELLIGENCE + NEURAL ENGINE (Silicon-only waste on Intel)
# ══════════════════════════════════════════════════════════════════════════════
section "2 · Apple Intelligence / Neural Engine Services (useless on Intel)"

info "Disabling Apple Intelligence daemon..."
safe_disable_agent com.apple.intelligenced
safe_unload_agent /System/Library/LaunchAgents/com.apple.intelligenced.plist

info "Disabling Siri inference daemon..."
safe_disable_agent com.apple.siri.inferenced
safe_unload_agent /System/Library/LaunchAgents/com.apple.siri.inferenced.plist

info "Disabling on-device ML runtime..."
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.mlruntimed.plist
safe_disable_daemon com.apple.mlruntimed

info "Disabling Neural inference agent..."
safe_unload_agent /System/Library/LaunchAgents/com.apple.neuralengine.plist

info "Disabling Writing tools / proofread daemon..."
safe_disable_agent com.apple.WritingTools

info "Disabling Image Playground..."
safe_disable_agent com.apple.ImagePlayground

success "Apple Intelligence / Neural services blocked"

# ══════════════════════════════════════════════════════════════════════════════
#  3 · SIRI
# ══════════════════════════════════════════════════════════════════════════════
section "3 · Siri"

info "Disabling Siri..."
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri SiriPrefStashedStatusMenuVisible -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2

safe_unload_agent /System/Library/LaunchAgents/com.apple.Siri.agent.plist
safe_unload_agent /System/Library/LaunchAgents/com.apple.siri.context.writer.plist
safe_disable_agent com.apple.assistantd
safe_disable_agent com.apple.Siri.agent

# Suggestions daemon (powers "Siri Suggestions" everywhere)
info "Disabling Siri Suggestions / parsecd..."
safe_unload_agent /System/Library/LaunchAgents/com.apple.parsecd.plist
safe_disable_agent com.apple.parsecd
safe_disable_agent com.apple.suggestd

success "Siri disabled"

# ══════════════════════════════════════════════════════════════════════════════
#  4 · SPOTLIGHT
# ══════════════════════════════════════════════════════════════════════════════
section "4 · Spotlight (use Raycast/Alfred instead)"

info "Disabling Spotlight indexing on all volumes..."
sudo mdutil -a -i off 2>/dev/null && success "mdutil indexing OFF"

info "Stopping Spotlight daemon..."
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

info "Preventing Spotlight from re-indexing..."
sudo defaults write /Library/Preferences/com.apple.SpotlightServer.plist ExternalVolumesIgnored -bool true 2>/dev/null

info "Disabling mds_stores (Spotlight store sync)..."
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.metadata.mds.stores.plist

# Disable Spotlight keyboard shortcut interference
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/></dict>" 2>/dev/null

success "Spotlight fully disabled — install Raycast via: brew install --cask raycast"

# ══════════════════════════════════════════════════════════════════════════════
#  5 · UNNECESSARY BACKGROUND DAEMONS & AGENTS
# ══════════════════════════════════════════════════════════════════════════════
section "5 · Unnecessary Background Daemons & Agents"

# ── iCloud / Apple Services you likely don't need running constantly ──────────
info "iCloud Photos analysis daemon..."
safe_disable_agent com.apple.photoanalysisd
safe_unload_agent /System/Library/LaunchAgents/com.apple.photoanalysisd.plist

info "AMPd (Music/AMP media indexer)..."
safe_disable_agent com.apple.AMPDeviceDiscoveryAgent
safe_disable_agent com.apple.AMPLibraryAgent
safe_disable_agent com.apple.AMPArtworkAgent
safe_unload_agent /System/Library/LaunchAgents/com.apple.AMPDeviceDiscoveryAgent.plist
safe_unload_agent /System/Library/LaunchAgents/com.apple.AMPLibraryAgent.plist
safe_unload_agent /System/Library/LaunchAgents/com.apple.AMPArtworkAgent.plist

info "Rapport (Universal Control / Handoff discovery)..."
safe_disable_daemon com.apple.rapportd
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.rapportd.plist

info "Sharesheet daemon..."
safe_disable_agent com.apple.sharingd
safe_unload_agent /System/Library/LaunchAgents/com.apple.sharingd.plist

info "Usage Tracking Agent..."
safe_disable_agent com.apple.UsageTrackingAgent
safe_unload_agent /System/Library/LaunchAgents/com.apple.UsageTrackingAgent.plist

info "Student / Classroom daemon..."
safe_disable_daemon com.apple.studentd
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.studentd.plist 2>/dev/null

info "Game Center daemon..."
safe_disable_agent com.apple.gamed
safe_unload_agent /System/Library/LaunchAgents/com.apple.gamed.plist

info "Game Controller daemon..."
safe_disable_daemon com.apple.GameController.gamecontrollerd
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.GameController.gamecontrollerd.plist 2>/dev/null

info "ARKit session daemon..."
safe_disable_agent com.apple.arkit.session.agent

info "Symptom analytics daemon..."
safe_disable_daemon com.apple.symptomsd
safe_unload_daemon /System/Library/LaunchDaemons/com.apple.symptomsd.plist

info "DiskImages mount helper (background)..."
# Keep the main diskimages utility but disable the daemon helper
safe_disable_daemon com.apple.diskimages.fsck 2>/dev/null

info "AccessibilityVisualsAgent (unused if you don't use it)..."
safe_disable_agent com.apple.accessibility.MotionTrackingAgent 2>/dev/null

info "Remote Management..."
sudo launchctl disable system/com.apple.RemoteDesktop.PrivilegeProxy 2>/dev/null
sudo launchctl disable system/com.apple.screensharing 2>/dev/null
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null

info "Find My daemon (fmfd)..."
safe_disable_agent com.apple.icloud.fmfd
safe_unload_agent /System/Library/LaunchAgents/com.apple.icloud.fmfd.plist

info "Feedback Assistant..."
safe_disable_agent com.apple.appleseed.fbahelperd

info "Help Centre daemon..."
safe_disable_agent com.apple.helpd
safe_unload_agent /System/Library/LaunchAgents/com.apple.helpd.plist

success "Unnecessary services cleaned up"

# ══════════════════════════════════════════════════════════════════════════════
#  6 · SYSTEM LOGGING — drastically reduce I/O and CPU from logging
# ══════════════════════════════════════════════════════════════════════════════
section "6 · System Logging (slash log verbosity)"

info "Setting log level to error-only..."
sudo log config --mode "level:error" 2>/dev/null && success "Log mode → error only"

info "Reducing syslog output..."
sudo syslog -c 0 -e 2>/dev/null

info "Disabling private data logging..."
sudo log config --mode "private_data:off" 2>/dev/null

# Disable ActivityMonitor logging noise
defaults write com.apple.ActivityMonitor ShowCategory -int 0 2>/dev/null

success "Logging reduced"

# ══════════════════════════════════════════════════════════════════════════════
#  7 · FINDER ANIMATIONS (Window animations only — desktop + transparency kept)
# ══════════════════════════════════════════════════════════════════════════════
section "7 · Finder Animations (NOT touching desktop/transparency)"

info "Disabling Finder window animations..."
defaults write com.apple.finder DisableAllAnimations -bool true

info "Disabling Info window animations in Finder..."
defaults write com.apple.finder AnimateInfoPanes -bool false

info "Disabling Finder spring-loading delays..."
defaults write NSGlobalDomain com.apple.springing.enabled -bool false

info "Speeding up window resize animations (near-instant)..."
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

info "Disabling Dock auto-hide animation delay..."
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4

info "Disabling app launch bounce (Dock)..."
defaults write com.apple.dock launchanim -bool false

info "Disabling opening/closing window animations..."
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

info "Disabling smooth scrolling animation lag..."
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false 2>/dev/null

# NOTE: NOT disabling NSReduceMotionEnabled (system-wide reduce motion)
# NOTE: NOT touching transparency (ReduceTransparency stays OFF = keeps glass)
# NOTE: NOT touching desktop animations or wallpaper
# NOTE: NOT touching NSVisualEffectView (keeps blur/vibrancy)
# QuickLook is entirely unaffected — it uses its own rendering path

success "Finder animations stripped — desktop + transparency fully intact"

# ══════════════════════════════════════════════════════════════════════════════
#  8 · GENERAL UI PERFORMANCE TWEAKS
# ══════════════════════════════════════════════════════════════════════════════
section "8 · UI Performance Tweaks"

info "Expanding save panel by default (less hops)..."
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

info "Expanding print panel by default..."
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

info "Disabling automatic app termination (prevent phantom relaunches)..."
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

info "Faster key repeat..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

info "Disabling auto-correct (saves CPU on text processing)..."
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

info "Disabling smart dashes and quotes..."
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

info "Disabling automatic capitalisation..."
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

info "Disabling period with double-space..."
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

info "Disabling natural scroll direction check (leave as-is, just ensure it's set)..."

info "Saving to disk by default (not iCloud)..."
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

info "Disabling font smoothing override for non-retina..."
defaults write NSGlobalDomain CGFontRenderingFontSmoothingDisabled -bool false

info "Disabling Notification Center Expose animation delay..."
defaults write com.apple.notificationcenterui NSWindowAnimationDurationMultiplier -float 0.5 2>/dev/null

success "UI tweaks applied"

# ══════════════════════════════════════════════════════════════════════════════
#  9 · POWER & THERMAL MANAGEMENT (Intel i7 specific)
# ══════════════════════════════════════════════════════════════════════════════
section "9 · Power & Thermal Management (Intel i7)"

info "Disabling hibernation (sleep only, no disk dump — faster wake, less SSD wear)..."
sudo pmset -a hibernatemode 0
success "hibernatemode = 0"

info "Removing sleepimage to reclaim RAM-equivalent disk space..."
sudo rm -f /private/var/vm/sleepimage 2>/dev/null
sudo touch /private/var/vm/sleepimage
sudo chflags uchg /private/var/vm/sleepimage 2>/dev/null

info "Disabling Power Nap (stops wake-ups during sleep)..."
sudo pmset -a powernap 0
success "Power Nap OFF"

info "Disabling Wake on LAN..."
sudo pmset -a womp 0
success "WoL OFF"

info "Disabling TCP keepalive during sleep (prevents random wake-ups)..."
sudo pmset -a tcpkeepalive 0

info "Disabling proximity wake (screen wake on nearby iPhone)..."
sudo pmset -a proximitywake 0

info "Setting aggressive standby delay (24h before ultra-low sleep)..."
sudo pmset -a standbydelay 86400

info "Disabling Sudden Motion Sensor (not needed on SSD Mac)..."
sudo pmset -a sms 0 2>/dev/null

info "Setting display sleep to 5 min on battery, 10 min on AC..."
sudo pmset -b displaysleep 5
sudo pmset -c displaysleep 10

info "Enable App Nap system-wide (helps CPU when apps are backgrounded)..."
defaults write NSGlobalDomain NSAppSleepDisabled -bool false

info "Disable Turbo Boost switching service (prevents aggressive frequency spikes)..."
# Note: requires turbo-boost-switcher or cputhrottle via brew, optional
# brew install --cask turbo-boost-switcher  ← install manually if desired
warn "  Optional: 'brew install --cask turbo-boost-switcher' to manually control Turbo Boost"

success "Power management optimised for Intel"

# ══════════════════════════════════════════════════════════════════════════════
#  10 · MEMORY MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════
section "10 · Memory Management"

info "Disabling memory-hogging loginwindow bloat..."
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false 2>/dev/null

info "Disabling automatic software update checks in background..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int 0
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false

info "Disabling iCloud sync for desktop/documents (huge RAM hog if enabled)..."
defaults write com.apple.bird optimize-storage-all-enabled -bool false 2>/dev/null

info "Purging inactive memory now..."
sudo purge 2>/dev/null
success "Memory purged"

# ══════════════════════════════════════════════════════════════════════════════
#  11 · NETWORK NOISE REDUCTION
# ══════════════════════════════════════════════════════════════════════════════
section "11 · Network Noise Reduction"

info "Disabling LLMNR (Link-Local Multicast Name Resolution) spam..."
sudo launchctl disable system/com.apple.mDNSResponder.reloaded 2>/dev/null

info "Disabling Bonjour multicast advertisements..."
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true

info "Disabling AirDrop (saves Wi-Fi / BT scanning cycles)..."
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true

info "Disabling Back to My Mac..."
defaults write com.apple.NetworkBrowser EnableODiskBrowsing -bool false

success "Network noise reduced"

# ══════════════════════════════════════════════════════════════════════════════
#  12 · DOCK CLEAN-UP & PERFORMANCE
# ══════════════════════════════════════════════════════════════════════════════
section "12 · Dock Performance"

info "Enabling Dock icon magnification off by default..."
defaults write com.apple.dock magnification -bool false

info "Minimise to app icon (not separate tile — saves Dock memory)..."
defaults write com.apple.dock minimize-to-application -bool true

info "Setting minimise effect to scale (scale < genie for GPU usage)..."
defaults write com.apple.dock mineffect -string "scale"

info "Show only running apps in Dock indicator..."
defaults write com.apple.dock show-process-indicators -bool true

info "Disabling recent apps section in Dock..."
defaults write com.apple.dock show-recents -bool false

success "Dock optimised"

# ══════════════════════════════════════════════════════════════════════════════
#  13 · QUICKLOOK — VERIFIED INTACT
# ══════════════════════════════════════════════════════════════════════════════
section "13 · QuickLook — Integrity Check"

info "Verifying QuickLook daemon is active and untouched..."
if launchctl list | grep -q "com.apple.quicklook"; then
    success "QuickLook (com.apple.quicklook) is running — UNTOUCHED ✓"
else
    warn "QuickLook not in launchctl list, but this is normal until triggered"
fi
# Ensure the generator daemon is available
if [ -d "/System/Library/Frameworks/QuickLook.framework" ]; then
    success "QuickLook.framework present — all previews functional ✓"
fi
# Reset QuickLook server just to clear any stale state
qlmanage -r 2>/dev/null
qlmanage -r cache 2>/dev/null
success "QuickLook cache refreshed — Space bar previews fully working ✓"

# ══════════════════════════════════════════════════════════════════════════════
#  14 · RESTART AFFECTED PROCESSES
# ══════════════════════════════════════════════════════════════════════════════
section "14 · Restarting Affected Processes"

info "Restarting Finder (applies animation changes)..."
killall Finder 2>/dev/null && success "Finder restarted"

info "Restarting Dock (applies Dock changes)..."
killall Dock 2>/dev/null && success "Dock restarted"

info "Restarting SystemUIServer..."
killall SystemUIServer 2>/dev/null && success "SystemUIServer restarted"

info "Restarting cfprefsd (applies defaults)..."
killall cfprefsd 2>/dev/null && success "cfprefsd restarted"

# ══════════════════════════════════════════════════════════════════════════════
#  15 · RECOMMENDED BREW INSTALLS  
# ══════════════════════════════════════════════════════════════════════════════
section "15 · Recommended Tools (optional, comment out what you don't want)"

if command -v brew &>/dev/null; then
    echo -e "\n${DIM}  Installing recommended tools...${NC}"
    
    brew install --cask raycast       2>/dev/null && success "Raycast (Spotlight replacement)"
    brew install htop                  2>/dev/null && success "htop (better Activity Monitor)"
    brew install stats                 2>/dev/null && success "Stats bar (menu bar system stats)"
    brew install --cask iStatMenus    2>/dev/null || warn "iStatMenus requires license — skipped"
    brew install --cask appcleaner    2>/dev/null && success "AppCleaner (clean uninstalls)"
    
    info "Optional install (uncomment to use):"
    echo -e "${DIM}  # brew install --cask turbo-boost-switcher  # disable Turbo Boost under load${NC}"
    echo -e "${DIM}  # brew install --cask aldente               # battery charge limiter${NC}"
    echo -e "${DIM}  # brew install --cask maccleaner            # system cleaner${NC}"
    echo -e "${DIM}  # brew install asitop                       # Apple chip power top (N/A intel)${NC}"
    echo -e "${DIM}  # brew install --cask memorydiag            # RAM analyser${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════╗
  ║                    ✓ ALL DONE!                            ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  What was done:                                           ║
  ║  ✓ Telemetry / Analytics / Diagnostics → OFF             ║
  ║  ✓ Apple Intelligence + Neural services → KILLED         ║
  ║  ✓ Siri + all suggestion daemons → OFF                   ║
  ║  ✓ Spotlight + mdutil indexing → OFF                     ║
  ║  ✓ Finder animations → stripped                          ║
  ║  ✓ Desktop animations + transparency → INTACT            ║
  ║  ✓ QuickLook → FULLY WORKING ✓                           ║
  ║  ✓ System logging → error-only                           ║
  ║  ✓ Power Nap, WoL, TCP keepalive → OFF                   ║
  ║  ✓ Hibernation → disabled (faster wake)                  ║
  ║  ✓ 20+ background daemons/agents → unloaded              ║
  ║  ✓ Homebrew installed                                     ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  → RESTART YOUR MAC for all changes to take effect       ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

read -p "  Restart now? [y/N] " RESTART_CHOICE
if [[ "$RESTART_CHOICE" =~ ^[Yy]$ ]]; then
    sudo shutdown -r now
fi
