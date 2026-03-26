#!/bin/bash

DOMAIN="aseconecta.com.ar"
DNS_SERVER="8.8.8.8"

echo "[+] Descubriendo subdominios desde crt.sh..."
curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" \
  | jq -r '.[].name_value' \
  | tr '\n' '\n' \
  | sed 's/\*\.//g' \
  | sort -u > subdominios.txt

echo "[+] Analizando certificados..."
while IFS= read -r host; do
  [[ -z "$host" ]] && continue

  IP=$(dig @"$DNS_SERVER" "$host" +short | head -n1)

  if [[ -z "$IP" ]]; then
    echo "[!] $host -> no resuelve"
    continue
  fi

  CERT_INFO=$(echo | openssl s_client -connect "$IP:443" -servername "$host" 2>/dev/null \
    | openssl x509 -noout -subject -issuer -enddate 2>/dev/null)

  if [[ -n "$CERT_INFO" ]]; then
    echo "[$host][$IP]"
    echo "$CERT_INFO"
    echo "----------------------------------"
  else
    echo "[!] $host -> sin SSL o fallo"
  fi
done < subdominios.txt