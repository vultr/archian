#!/bin/bash

function getValue {
    KEY=$1
    FILE=$2
    if [ -z "$FILE" ]; then
        FILE="/root/archian/archian.json"
    fi
    VAL=$(jq ".${KEY}" ${FILE} | sed 's/"//g')
    if [ "$?" != "0" ]; then
      echo -n ""
    fi
    echo -n "${VAL}"
}

function installScripted {
  NAME=$1
  FILE="/root/archian/packages/${NAME}.txt"

  IFSB=$IFS
  IFS=$' '
  EXCLUDE=($(jq -r ".packages.exclude | @sh" /root/archian/archian.json | sed "s/'//g"))
  PACKAGES=($(cat ${FILE}))
  IFS=$IFSB

  PACKAGES=($(comm -3 <(printf "%s\n" "${PACKAGES[@]}" | sort) <(printf "%s\n" "${EXCLUDE[@]}" | sort) | sort -n))
  PACKAGES="${PACKAGES[@]}"

  runuser -l installer -c "trizen -Sy --noconfirm ${PACKAGES}"
}

function installScriptedOptional {
  NAME=$1
  FILE="/root/archian/packages/${NAME}.txt"

  WANTED=$(getValue "packages.${NAME}")
  if [ "$WANTED" != "true" ]; then
    return
  fi

  IFSB=$IFS
  IFS=$' '
  EXCLUDE=($(jq -r ".packages.exclude | @sh" /root/archian/archian.json | sed "s/'//g"))
  PACKAGES=($(cat ${FILE}))
  IFS=$IFSB

  PACKAGES=($(comm -3 <(printf "%s\n" "${PACKAGES[@]}" | sort) <(printf "%s\n" "${EXCLUDE[@]}" | sort) | sort -n))
  PACKAGES="${PACKAGES[@]}"

  runuser -l installer -c "trizen -Sy --noconfirm ${PACKAGES}"
}