#!/bin/bash
function check_installed {
  local package
  local to_install=()
  list=""
  list2=""
  while IFS= read -r package; do
    [ -z "${package}" ] && continue

    STR="${package}"
    SUB='*'

    case $STR in
      *"$SUB"*)
        list2="${list2} \"${STR}\""
        ;;
      *)
        list="${list} \"${STR}\""
        ;;
    esac

    if !(dpkg -s "${package}" >/dev/null 2>&1); then
      if !(nala show "${package}" 2>&1 | grep -q "Error: "); then
        list="${list} \"${package}\""
      fi
    fi
  done < "${1}"

  c="sudo nala install ${list} -y"
  c2="sudo apt install ${list2} -y"
  echo $c
  echo $c2
}

package=("kcalc" "kate" "kmix" "knotes" "\"kde-config-cron*\"" "krename" "kamoso" "kolourpaint" "kid3" "kcolorchooser"
  "kcharselect" "kdenetwork-filesharing" "kfind" "kget" "kinfocenter" "\"kio*\"" "\"kio*\"" "kio-admin" "kleopatra"
  "krdc" "kaccounts-providers" "kio-gdrive" "kbackup" "plasma-nm" "plasma-pa" "\"plasma-widget*\"" "\"plasma-widget*\""
  "plasma-widgets-addons" "ffmpegthumbs" "ark" "okular" "ksystemlog" "kde-config-cron" "kdeplasma-addons" "\"kdeplasma-addon*\"")

package_2=(
"kcalc"
"kate"
"kmix"
"knotes"
"\"kde-config-cron*\""
"krename"
"kamoso"
"kolourpaint"
"kid3"
"kcolorchooser"
"kcharselect"
"kdenetwork-filesharing"
"kfind"
"kget"
"kinfocenter"
"\"kio*\""
"\"kio*\""
"kio-admin"
"kleopatra"
"krdc"
"kaccounts-providers"
"kio-gdrive"
"kbackup"
"plasma-nm"
"plasma-pa"
"\"plasma-widget*\""
"\"plasma-widget*\""
"plasma-widgets-addons"
"ffmpegthumbs"
"ark"
"okular"
"ksystemlog"
"kde-config-cron"
"kdeplasma-addons"
"\"kdeplasma-addon*\""
)


check_installed "${package}"
