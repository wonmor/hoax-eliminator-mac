#!/bin/bash
# ------------------------------------------------------------------------------
#  hoax-eliminator  —  구라제거기 for Mac
#
#  Finds and removes the Korean "security" agents that banks, card companies and
#  government sites force-install on macOS (keyboard encryptors, IP collectors,
#  certificate relays, "integrated security module managers", ...).
#
#  Usage:
#      hoax-eliminator.sh scan                 # list what is installed (no root)
#      sudo hoax-eliminator.sh remove          # remove everything found (asks first)
#      sudo hoax-eliminator.sh remove --yes    # no questions
#      sudo hoax-eliminator.sh remove --only astx,nxkey
#      sudo hoax-eliminator.sh remove --dry-run
#      hoax-eliminator.sh list                 # show the catalog
#      hoax-eliminator.sh scan --deep          # also hunt for unknown suspects
#
#  Works on macOS 10.13+ with the stock /bin/bash 3.2. No dependencies.
#  https://github.com/wonmor/hoax-eliminator-mac   (MIT)
# ------------------------------------------------------------------------------
set -u
VERSION="1.0.0"

# ------------------------------------------------------------------------------
#  Catalog
#  One record per line:  id|Name|Vendor|paths|launchd plists|process regex|uninstaller
#    - fields separated by "|", multiple paths by ";"
#    - "~" is the *logged-in* user's home (not root's), globs are allowed
#    - launchd plists: filenames or globs inside /Library/Launch{Agents,Daemons}
#      and ~/Library/LaunchAgents
# ------------------------------------------------------------------------------
CATALOG='
astx|AhnLab Safe Transaction (ASTx)|AhnLab|/Applications/AhnLab;/Library/Application Support/ahnlab;~/Library/Application Support/AhnLab;/tmp/astxd;~/Library/Preferences/com.ahnlab.*;~/Library/Preferences/com.astx.*|com.ahnlab.astxd.plist;com.ahnlab.astxagent.plist;com.ahnlab.*.plist;com.astx.*.plist|astxd|astxAgent|/Applications/AhnLab/ASTx/Uninstaller.app
nxkey|TouchEn nxKey (keyboard encryption)|RaonSecure|/Applications/TouchEn nxKey;/Applications/raonk;/Library/Application Support/raonsecure;/Library/Internet Plug-Ins/npraontouchenex.plugin;~/Library/Preferences/com.raon.*|com.raon.touchen.nxkey.plist;com.raon.agent.touchen.nxkey.plist;com.raon.touchen.UserAgent.plist;com.raon.*.plist;com.raonsecure.*.plist|TEK_Daemon|TEK_UserAgent|TouchEn|/Applications/TouchEn nxKey/TKUninstall.app
crosswebex|INISAFE CrossWeb EX|INITECH|/Applications/CrossWebEX;/Library/Application Support/iniLINE/CrossWebEX;/Library/Frameworks/CrossWebEXFramework.framework;/Library/Internet Plug-Ins/npCrossWebEXPlugin.plugin;/Library/Internet Plug-Ins/npinilinecrosswebex.plugin;~/Library/Preferences/com.initech.*|com.initech.*.plist|INISAFECrossWebEXSvc|/Applications/CrossWebEX/UnInstallCrossEX.app
crossex|iniLINE CrossEX / CrossWarpEX (browser relay)|iniLINE (INITECH)|/Applications/CrossEX;/Applications/CrossWarpEX;/Library/Application Support/iniLINE/CrossEX;~/Library/Preferences/com.iniline.*;~/Library/Preferences/kr.co.iniline.*|com.iniline.*.plist;kr.co.iniline.*.plist|CrossEXService|CrossWarpEX|/Applications/CrossEX/crossex/UnInstallCrossEX.app
veraport|Veraport (integrated security-module manager)|Wizvera|/Applications/Veraport;/Library/Application Support/wizvera/veraport;~/Library/Preferences/com.wizvera.veraport*|com.wizvera.veraport*.plist|veraport|
delfino|Delfino (certificate / e-signature)|Wizvera|/Applications/Delfino;/Library/Application Support/wizvera/delfino;~/Library/Preferences/com.wizvera.delfino*|com.wizvera.delfino*.plist|delfino|/Applications/Delfino/DelfinoUninstaller.app
ipinside|IPinside LWS Agent (IP / environment collector)|Interezen|/Applications/IPinside.app;~/Library/Preferences/com.interezen.*|com.interezen.*.plist|NWSDaemon|IPinside|
anysign|AnySign4PC (certificate / e-signature)|SoftForum (HancomWITH)|/Applications/SoftForum;/Library/Application Support/SoftForum;~/Library/Application Support/SoftForum;~/Library/Preferences/com.softforum.*|com.softforum.*.plist|AnySign|/Applications/SoftForum/Uninstaller_AnySign4PC.app
xecureweb|XecureWeb Unified|SoftForum|/Applications/XecureWebUnified;/Library/Application Support/XecureWeb*|com.softforum.xecure*.plist;com.xecure*.plist|XecureWeb|/Applications/XecureWebUnified/Uninstaller.app
nprotect|nProtect Online Security|INCA Internet|/Applications/nProtect;/Library/Application Support/nProtect;/Library/Application Support/INCA*;~/Library/Caches/com.nprotect.*;~/Library/Caches/*.com.nprotect.*;~/Library/Preferences/com.nprotect.*;~/Library/Preferences/com.inca.*|com.inca.*.plist;com.nprotect.*.plist|nosintgdmn|nosuninst|nProtect|/Applications/nProtect/nProtect Online Security V1/NOS/nosuninst.app
magicline|MagicLine4NX (certificate / e-signature)|DreamSecurity|/Applications/MagicLine4NX*;/Applications/DreamSecurity;/Library/Application Support/DreamSecurity;/Library/Application Support/MagicLine*;~/Library/Preferences/com.dreamsecurity.*|com.dreamsecurity.*.plist;com.magicline*.plist|MagicLine|
epagesafer|ePageSafer / MaSaferJS (print & screen control)|MarkAny|/Applications/MarkAny*;/Applications/ePageSafer*;/Library/Application Support/MarkAny*;~/Library/Preferences/com.markany.*|com.markany.*.plist|ePageSafer|MaSafer|
ksign|KSign (KSignSWFT / CertRelay)|KSign|/Applications/KSign*;/Library/Application Support/KSign*;~/Library/Preferences/com.ksign.*|com.ksign.*.plist|KSign|
unisign|UniSign / UniSignMulti (certificate)|CrossCert|/Applications/UniSign*;/Applications/CrossCert*;/Library/Application Support/CrossCert*;~/Library/Preferences/com.crosscert.*|com.crosscert.*.plist|UniSign|
vestcert|VestCert (certificate)|Yettiesoft|/Applications/VestCert*;/Applications/Yettiesoft*;/Library/Application Support/Yettiesoft*;~/Library/Preferences/com.yettiesoft.*|com.yettiesoft.*.plist|VestCert|
secukit|SecuKit NX (keyboard / certificate)|SGA Solutions|/Applications/SecuKit*;/Library/Application Support/SGA*;~/Library/Preferences/com.sga.*|com.sga.*.plist;com.secukit*.plist|SecuKit|
'

# Keywords used by "scan --deep" to flag things the catalog does not know yet.
DEEP_KEYWORDS='ahnlab|astx|raon|touchen|nxkey|wizvera|veraport|delfino|initech|inisafe|iniline|crossweb|crossex|crosswarp|interezen|ipinside|softforum|anysign|xecure|nprotect|inca\.|dreamsecurity|magicline|markany|epagesafer|masafer|ksign|crosscert|unisign|yettie|vestcert|secukit|sgasol|kica|signgate|moasign|ubikey|hancomwith|securekey|keysharp|nppfs|ezpdf'

# ------------------------------------------------------------------------------
#  Boilerplate
# ------------------------------------------------------------------------------
LANGSEL=""
MODE=""
DRY_RUN=0
ASSUME_YES=0
DEEP=0
ONLY=""
KEEP=""
NO_COLOR=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_B=$'\033[1m'; C_R=$'\033[31m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_D=$'\033[2m'; C_0=$'\033[0m'
else
  C_B=""; C_R=""; C_G=""; C_Y=""; C_D=""; C_0=""
fi

die() { printf '%s%s%s\n' "$C_R" "$*" "$C_0" >&2; exit 1; }

# the real (non-root) user and their home, even under sudo
REAL_USER="${SUDO_USER:-$(id -un)}"
REAL_HOME="$(dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
[ -n "$REAL_HOME" ] || REAL_HOME="$HOME"
REAL_UID="$(id -u "$REAL_USER" 2>/dev/null || id -u)"

# ------------------------------------------------------------------------------
#  i18n  (ko / en)
# ------------------------------------------------------------------------------
pick_lang() {
  if [ -n "$LANGSEL" ]; then return; fi
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    ko*) LANGSEL=ko ;;
    *)   LANGSEL=en ;;
  esac
}

t() {  # t KEY [args...]
  local k="$1"; shift
  local s=""
  if [ "$LANGSEL" = ko ]; then
    case "$k" in
      title)        s="구라제거기 for Mac v%s" ;;
      scanning)     s="설치된 보안 프로그램을 찾는 중..." ;;
      none)         s="설치된 보안 프로그램이 없습니다. 깨끗합니다." ;;
      found_n)      s="%s개 발견:" ;;
      found_item)   s="  [%s] %s  (%s)" ;;
      item_path)    s="      파일   %s" ;;
      item_plist)   s="      launchd %s" ;;
      item_proc)    s="      실행중  %s" ;;
      next_remove)  s="삭제하려면:  sudo %s remove" ;;
      need_root)    s="삭제하려면 관리자 권한이 필요합니다. 'sudo' 를 붙여서 다시 실행하세요." ;;
      dry)          s="[시뮬레이션] 실제로 삭제하지 않습니다." ;;
      confirm)      s="위 %s개 프로그램을 삭제할까요? (은행/관공서 사이트 이용 시 재설치를 요구할 수 있습니다) [y/N] " ;;
      aborted)      s="취소했습니다." ;;
      removing)     s="삭제 중: %s" ;;
      stop_job)     s="    launchd 중지  %s" ;;
      kill_proc)    s="    프로세스 종료 %s" ;;
      rm_path)      s="    삭제          %s" ;;
      forget_pkg)   s="    패키지 영수증 %s" ;;
      done_ok)      s="완료. %s개 프로그램을 삭제했습니다." ;;
      done_left)    s="완료했지만 남은 항목이 있습니다 (위 STILL PRESENT 참고)." ;;
      still)        s="    남아있음      %s" ;;
      log_at)       s="로그: %s" ;;
      deep_title)   s="[deep] 카탈로그에 없는 의심 항목 (삭제하지 않음, 보고만 합니다):" ;;
      deep_none)    s="[deep] 추가 의심 항목 없음." ;;
      list_hdr)     s="카탈로그 (%s개):" ;;
      unknown_id)   s="알 수 없는 id: %s  ('list' 로 확인)" ;;
      reinstall)    s="참고: 다음에 은행 사이트에 접속하면 다시 설치하라고 합니다. 필요한 날에만 설치하세요." ;;
      *) s="$k" ;;
    esac
  else
    case "$k" in
      title)        s="Hoax Eliminator for Mac v%s" ;;
      scanning)     s="Looking for installed Korean security agents..." ;;
      none)         s="Nothing found. This Mac is clean." ;;
      found_n)      s="Found %s:" ;;
      found_item)   s="  [%s] %s  (%s)" ;;
      item_path)    s="      file    %s" ;;
      item_plist)   s="      launchd %s" ;;
      item_proc)    s="      running %s" ;;
      next_remove)  s="To remove:  sudo %s remove" ;;
      need_root)    s="Removal needs admin rights. Re-run with 'sudo'." ;;
      dry)          s="[dry run] Nothing will actually be deleted." ;;
      confirm)      s="Remove the %s program(s) above? (Bank/government sites may ask you to reinstall) [y/N] " ;;
      aborted)      s="Aborted." ;;
      removing)     s="Removing: %s" ;;
      stop_job)     s="    stop launchd  %s" ;;
      kill_proc)    s="    kill process  %s" ;;
      rm_path)      s="    delete        %s" ;;
      forget_pkg)   s="    forget pkg    %s" ;;
      done_ok)      s="Done. Removed %s program(s)." ;;
      done_left)    s="Done, but some items remain (see STILL PRESENT above)." ;;
      still)        s="    STILL PRESENT %s" ;;
      log_at)       s="Log: %s" ;;
      deep_title)   s="[deep] Suspects not in the catalog (report only, nothing deleted):" ;;
      deep_none)    s="[deep] No extra suspects." ;;
      list_hdr)     s="Catalog (%s entries):" ;;
      unknown_id)   s="Unknown id: %s  (see 'list')" ;;
      reinstall)    s="Note: the next bank site you visit will ask to reinstall these. Install only on the day you need them." ;;
      *) s="$k" ;;
    esac
  fi
  # shellcheck disable=SC2059
  printf "$s\n" "$@"
}

# ------------------------------------------------------------------------------
#  Helpers
# ------------------------------------------------------------------------------
exists() { [ -e "$1" ] || [ -L "$1" ]; }   # dangling symlinks count too

expand_paths() { _expand_paths "$@" | awk '!seen[$0]++'; }
_expand_paths() {  # "a;b;~/c*"  -> one existing path per line
  local spec="$1" item
  local oldifs="$IFS"
  IFS=';'
  for item in $spec; do
    IFS="$oldifs"
    [ -z "$item" ] && continue
    case "$item" in "~"*) item="$REAL_HOME${item#\~}" ;; esac
    case "$item" in
      *[\*\?\[]*)
        local f
        IFS=$'\n'
        # shellcheck disable=SC2086
        for f in $item; do exists "$f" && printf '%s\n' "$f"; done
        IFS="$oldifs"
        ;;
      *) exists "$item" && printf '%s\n' "$item" ;;
    esac
    IFS=';'
  done
  IFS="$oldifs"
}

expand_plists() { _expand_plists "$@" | awk '!seen[$0]++'; }
_expand_plists() {  # "a.plist;com.x.*.plist" -> existing plist paths
  local spec="$1" item dir f
  local oldifs="$IFS"
  IFS=';'
  for item in $spec; do
    IFS="$oldifs"
    [ -z "$item" ] && continue
    for dir in /Library/LaunchDaemons /Library/LaunchAgents "$REAL_HOME/Library/LaunchAgents"; do
      IFS=$'\n'
      # shellcheck disable=SC2086
      for f in $dir/$item; do exists "$f" && printf '%s\n' "$f"; done
      IFS="$oldifs"
    done
    IFS=';'
  done
  IFS="$oldifs"
}

running_procs() {  # running_procs REGEX -> "pid command" lines
  [ -z "$1" ] && return
  ps -axo pid=,comm= | grep -iE "$1" | grep -viE "hoax-eliminator|grep" || true
}

plist_label() {
  local l=""
  [ -r "$1" ] && l="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$1" 2>/dev/null)"
  case "$l" in ""|*"Doesn't Exist"*) l="$(basename "$1" .plist)" ;; esac
  printf '%s' "$l"
}

field() {  # field N "record"
  printf '%s' "$2" | cut -d'|' -f"$1"
}

each_record() {  # prints catalog records (non-empty lines)
  printf '%s\n' "$CATALOG" | sed '/^[[:space:]]*$/d'
}

selected() {  # selected ID -> 0 if this id should be processed
  local id="$1"
  if [ -n "$ONLY" ]; then
    case ",$ONLY," in *",$id,"*) ;; *) return 1 ;; esac
  fi
  if [ -n "$KEEP" ]; then
    case ",$KEEP," in *",$id,"*) return 1 ;; esac
  fi
  return 0
}

validate_ids() {
  local list="$1" id ok
  local oldifs="$IFS"; IFS=','
  for id in $list; do
    ok=0
    while IFS= read -r rec; do [ "$(field 1 "$rec")" = "$id" ] && ok=1; done <<EOF
$(each_record)
EOF
    [ $ok -eq 1 ] || { IFS="$oldifs"; die "$(t unknown_id "$id")"; }
  done
  IFS="$oldifs"
}

# ------------------------------------------------------------------------------
#  scan
# ------------------------------------------------------------------------------
FOUND_IDS=""
FOUND_COUNT=0

do_scan() {
  printf '%s%s%s\n' "$C_B" "$(t title "$VERSION")" "$C_0"
  t scanning
  echo
  local rec id name vendor paths plists procs
  local hits p
  FOUND_IDS=""; FOUND_COUNT=0
  local out=""
  while IFS= read -r rec; do
    id="$(field 1 "$rec")"; name="$(field 2 "$rec")"; vendor="$(field 3 "$rec")"
    paths="$(field 4 "$rec")"; plists="$(field 5 "$rec")"; procs="$(field 6 "$rec")"
    selected "$id" || continue
    hits="$(expand_paths "$paths"; expand_plists "$plists")"
    local running; running="$(running_procs "$procs")"
    if [ -n "$hits" ] || [ -n "$running" ]; then
      FOUND_COUNT=$((FOUND_COUNT+1)); FOUND_IDS="$FOUND_IDS,$id"
      out="$out$(printf '%s%s%s\n' "$C_Y" "$(t found_item "$id" "$name" "$vendor")" "$C_0")"$'\n'
      while IFS= read -r p; do
        [ -z "$p" ] && continue
        case "$p" in
          */Launch*/*.plist) out="$out$(t item_plist "$p")"$'\n' ;;
          *)                 out="$out$(t item_path "$p")"$'\n' ;;
        esac
      done <<EOF
$hits
EOF
      while IFS= read -r p; do
        [ -z "$p" ] && continue
        out="$out$(t item_proc "$p")"$'\n'
      done <<EOF
$running
EOF
    fi
  done <<EOF
$(each_record)
EOF
  if [ $FOUND_COUNT -eq 0 ]; then
    printf '%s%s%s\n' "$C_G" "$(t none)" "$C_0"
  else
    t found_n "$FOUND_COUNT"
    printf '%s' "$out"
  fi
  [ $DEEP -eq 1 ] && do_deep
  return 0
}

do_deep() {
  echo
  local dir f hits=""
  for dir in /Library/LaunchDaemons /Library/LaunchAgents "$REAL_HOME/Library/LaunchAgents" /Applications "/Library/Application Support" "/Library/Internet Plug-Ins" /Library/PrivilegedHelperTools; do
    [ -d "$dir" ] || continue
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      # skip anything the catalog already covers
      local known=0 rec
      while IFS= read -r rec; do
        # known if the catalog covers this path, or something inside it
        if { expand_paths "$(field 4 "$rec")"; expand_plists "$(field 5 "$rec")"; } | grep -qE "^$(printf '%s' "$f" | sed 's/[][\\.*^$]/\\&/g')(/|$)"; then known=1; break; fi
      done <<EOF
$(each_record)
EOF
      [ $known -eq 0 ] && hits="$hits$f"$'\n'
    done <<EOF
$(ls -1d "$dir"/* 2>/dev/null | grep -iE "$DEEP_KEYWORDS")
EOF
  done
  local known_procs; known_procs="$(each_record | cut -d'|' -f6 | sed '/^$/d' | paste -sd'|' -)"
  local procs; procs="$(ps -axo pid=,comm= | grep -iE "$DEEP_KEYWORDS" | grep -viE "hoax-eliminator|grep" | grep -viE "${known_procs:-__none__}" || true)"
  if [ -z "$hits" ] && [ -z "$procs" ]; then t deep_none; return; fi
  printf '%s%s%s\n' "$C_B" "$(t deep_title)" "$C_0"
  printf '%s' "$hits" | sed 's/^/      /'
  [ -n "$procs" ] && printf '%s\n' "$procs" | sed 's/^/      running /'
}

# ------------------------------------------------------------------------------
#  remove
# ------------------------------------------------------------------------------
LOG=""
log() { [ -n "$LOG" ] && printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; return 0; }

run() {  # run <cmd...>  (honours --dry-run)
  log "$*"
  [ $DRY_RUN -eq 1 ] && return 0
  "$@"
}

stop_job() {  # stop_job /path/to.plist
  local plist="$1" label
  label="$(plist_label "$plist")"
  t stop_job "$label"
  case "$plist" in
    /Library/LaunchDaemons/*) run launchctl bootout "system/$label" >/dev/null 2>&1 || true ;;
    *)                        run launchctl bootout "gui/$REAL_UID/$label" >/dev/null 2>&1 || true ;;
  esac
}

do_remove() {
  if [ "$(id -u)" -ne 0 ] && [ $DRY_RUN -eq 0 ]; then
    die "$(t need_root)"
  fi
  do_scan
  [ $FOUND_COUNT -eq 0 ] && return 0
  echo
  [ $DRY_RUN -eq 1 ] && printf '%s%s%s\n' "$C_Y" "$(t dry)" "$C_0"
  if [ $ASSUME_YES -eq 0 ] && [ $DRY_RUN -eq 0 ]; then
    printf '%s' "$(t confirm "$FOUND_COUNT")"
    local ans=""
    if [ -r /dev/tty ]; then read -r ans </dev/tty; else read -r ans; fi
    case "$ans" in y|Y|yes|YES) ;; *) t aborted; exit 1 ;; esac
  fi
  LOG="/tmp/hoax-eliminator-$(date +%Y%m%d-%H%M%S).log"
  [ $DRY_RUN -eq 1 ] && LOG=""
  echo
  local rec id name paths plists procs p removed=0 left=0
  while IFS= read -r rec; do
    id="$(field 1 "$rec")"
    case ",$FOUND_IDS," in *",$id,"*) ;; *) continue ;; esac
    name="$(field 2 "$rec")"; paths="$(field 4 "$rec")"; plists="$(field 5 "$rec")"; procs="$(field 6 "$rec")"
    printf '%s%s%s\n' "$C_B" "$(t removing "$name")" "$C_0"
    # 1. launchd jobs
    while IFS= read -r p; do [ -n "$p" ] && stop_job "$p"; done <<EOF
$(expand_plists "$plists")
EOF
    # 2. processes
    if [ -n "$procs" ] && [ -n "$(running_procs "$procs")" ]; then
      t kill_proc "$procs"
      run pkill -f -i "$procs" 2>/dev/null || true
      sleep 1
      run pkill -9 -f -i "$procs" 2>/dev/null || true
    fi
    # 3. files (plists first, then paths)
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      t rm_path "$p"
      run rm -rf "$p"
    done <<EOF
$(expand_plists "$plists"; expand_paths "$paths")
EOF
    # 4. receipts
    local pkg
    for pkg in $(pkgutil --pkgs 2>/dev/null | grep -iE "$(printf '%s' "$id|$procs" | tr '|' '\n' | sed '/^$/d' | paste -sd'|' -)" 2>/dev/null); do
      t forget_pkg "$pkg"; run pkgutil --forget "$pkg" >/dev/null 2>&1 || true
    done
    # 5. verify
    local leftovers; leftovers="$(expand_plists "$plists"; expand_paths "$paths")"
    if [ $DRY_RUN -eq 0 ] && [ -n "$leftovers" ]; then
      left=$((left+1))
      printf '%s' "$leftovers" | while IFS= read -r p; do [ -n "$p" ] && printf '%s%s%s\n' "$C_R" "$(t still "$p")" "$C_0"; done
    else
      removed=$((removed+1))
    fi
  done <<EOF
$(each_record)
EOF
  # tidy empty parent dirs we may have emptied
  [ $DRY_RUN -eq 0 ] && rmdir "/Library/Application Support/iniLINE" "/Library/Application Support/wizvera" 2>/dev/null
  echo
  if [ $left -eq 0 ]; then printf '%s%s%s\n' "$C_G" "$(t done_ok "$removed")" "$C_0"; else printf '%s%s%s\n' "$C_Y" "$(t done_left)" "$C_0"; fi
  [ -n "$LOG" ] && t log_at "$LOG"
  t reinstall
}

# ------------------------------------------------------------------------------
#  list
# ------------------------------------------------------------------------------
do_list() {
  local n; n="$(each_record | wc -l | tr -d ' ')"
  t list_hdr "$n"
  each_record | while IFS= read -r rec; do
    printf '  %-12s %s  %s(%s)%s\n' "$(field 1 "$rec")" "$(field 2 "$rec")" "$C_D" "$(field 3 "$rec")" "$C_0"
  done
}

usage() {
  sed -n '2,20p' "$0" 2>/dev/null | sed 's/^# \{0,2\}//' || true
}

# ------------------------------------------------------------------------------
#  main
# ------------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    scan|remove|list) MODE="$1" ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --deep) DEEP=1 ;;
    --only) shift; ONLY="${1:-}" ;;
    --only=*) ONLY="${1#--only=}" ;;
    --keep) shift; KEEP="${1:-}" ;;
    --keep=*) KEEP="${1#--keep=}" ;;
    --lang) shift; LANGSEL="${1:-}" ;;
    --lang=*) LANGSEL="${1#--lang=}" ;;
    --ko) LANGSEL=ko ;;
    --en) LANGSEL=en ;;
    --version|-V) echo "$VERSION"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; die "unknown option: $1" ;;
  esac
  shift
done
[ "$(uname -s)" = Darwin ] || die "macOS only."
pick_lang
[ -n "$ONLY" ] && validate_ids "$ONLY"
[ -n "$KEEP" ] && validate_ids "$KEEP"
case "${MODE:-scan}" in
  scan)   do_scan; [ $FOUND_COUNT -gt 0 ] && { echo; t next_remove "$(basename "$0")"; }; exit 0 ;;
  remove) do_remove ;;
  list)   do_list ;;
esac
