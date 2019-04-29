#!/usr/bin/env bash
#Script für eine Automatische Erstellung eines WLAN (SSID) auf dem Ruckus Produkten.
#
#by Gregor holzfeind <gholzfeind@heiniger-ag.ch>
#Version: 1.3
#Datum: 19.09.2017

# History
# Version		Datum			Änderungen
# 1.0			19.09.2017		Basis-Script
# 1.1			19.09.2017		Einführung des Random-Passwort
# 1.2			19.09.2017		QR-Generator hinzugefügt
# 1.3			19.09.2017		Systemcheck hinzugefügt


#Variablen
    IPaddress="172.16.10.220" #IP-Adresse des vSZ
    Username="terosami" #User
    Password="" #Passwort des Benutzer
    domain="Heiniger" #Domain setzen
    Zone="Heininger Koeniz"  #Zone definieren
    ssid="Test_gg" #SSID
    vlan="1" ;#VLAN der SSID
    description="Scriptbasiert" #Beschreibung der SSID
    enc_algorithm="aes" #Algoritmus der Veschlüsselung, mögliche Werte: aes, auto, tkip
    enc_method="wpa2" #Methode der Verschlüsselung, mögliche Werte: mixed, none, wep128, wep64, wpa, wpa2
    auth_method="open" #Methode der Authentifizierung, mögliche Werte: "8021X, mac, open
    len_pw="10" #Passwortlänge
	ssid_pw="" #Passwort, nur benutzen wenn die Funktion "func_pass" auskommentieren ist!


#Funktionen

#Systemüberprüfung
func_sys_check() {
	check_expect=$(which expect)
	check_spawn=$(which spawn)
	check_qrencode=$(which qrencode)
	if [ "$check_expect" == "/usr/bin/expect" ]
	then
		exp_test="1"
	else
		exp_test="0"
	fi
	if [ "$check_spawn" == "/usr/bin/spawn" ]
	then
		spawn_test="1"
	else
		spawn_test="0"
	fi
		if [ "$check_qrencode" == "/usr/bin/qrencode" ]
	then
		qr_test="1"
	else
		qr_test="0"
	fi
	if [ "$exp_test" == "1" ] && [ "$spawn_test" == "1" ] && [ "$qr_test" == "1" ]
	then
		echo "Prüfung erfolgreich" > l
	else
		if [ "$exp_test" == "0" ]
		then
			test_exp="- expect\n"
		else
			test_exp=""
		fi
		if [ "$spawn_test" == "0" ]
		then
			test_spawn="- spawn\n"
		else
			test_spawn=""
		fi
		if [ "$qr_test" == "0" ]
		then
			test_qr="- qrencode\n"
		else
			test_qr=""
		fi
		echo -e "Es fehlen folgend(e) Programm(e):\n$test_exp$test_spawn$test_qr\nBitte installieren Sie die Programme!"
fi
}
#Passwortgenerator
func_pass() {
	ssid_pw=$(cat /dev/urandom|tr -dc "a-zA-Z0-9_\?" | fold -w$len_pw | head -n $RANDOM | tail -n 1)
}
#QR-Code
func_qr() {
	qrencode -o qr.svg -t SVG "WIFI:S:$ssid;T:WPA2;P:$ssid_pw;;"
}
# Passwort, nicht ändern
func_password_wifi_sz() {
    expect <<DONE
    spawn ssh $Username@$IPaddress ;#SSH-Login
    expect "*assword: "
    send "$Password\r" ;#senden des Passwort
    expect "*>"    
    send "en\r" ;#Wechsel in den enable-Modus
    expect "*assword: "
    send "$Password\r" ;#senden des Passwort
    expect "#"
    send "con \r" ;#Wechseln ind den Konfigurationsmodus
    expect "*(config)#"
    send "domain $domain\r" ; #Wechsel in die Domain
    expect "*(config-domain)#"
    send "zone $Zone\r" ; # Wechsel in die Zone
    expect "*(config-domain-zone)#"
    send "wlan $ssid\r" ;#Wechsel zur erstellenden SSID
    expect "*(config-domain-zone)#"
    send "ssid $ssid\r" ;#Erstellen der SSID
    expect "*(config-domain-zone-wlan)#"
    send "name $ssid\r" ;#Name der SSID erstellen
    expect "*(config-domain-zone-wlan)#"
    send "vlan-id $vlan\r" ;#Access-VLAN festlegen
    expect "*(config-domain-zone-wlan)#"
    send "auth-method $auth_method\r" ;#Sende der Authentifizierung-Methode
    expect "*(config-domain-zone-wlan)#"        
    send "enc-algorithm $enc_algorithm\r" ;#Senden des Verschlüsselungsalgoritmus
    expect "*(config-wlan)#"
    send "enc-method $enc_method\r" ;#Senden der Verschlüsselungsmethode
    expect "*(config-domain-zone-wlan)#"
    send "enc-passphrase $ssid_pw\r" ;# Passwort der SSID
    expect "*(config-domain-zone-wlan)#"     
    send "description $description\r" ;#Beschreibung der SSID
    expect "*(config-domain-zone-wlan)#"     
    send "end\r" ;#Verlassen des Konfigurationsmmodus mit Speicher der Einstellungen
    expect "Do *"     
    send "yes\r" ;#Bestätung dass die Einstellungen geschrieben werden dürfen
    expect "#"
    send "exit\r" ;#Verlassen des enable-Modus
    expect ">"
    send "exit\r" ;#SSH-Verbindung verlassen
    expect eof
DONE
}

#Programm
if [ $# -eq 0 ];
then
    echo "Es wurden keine Option angegeben. 
Für mehr Informationen ruckus-ssid -h oder ruckus-ssid --help"
    exit 0
else
TEMP=`getopt -o i::u:: --long ip::,user:: -n 'test.sh' -- "$@"`
eval set -- "$TEMP"
while true ; do
	echo "$1"
    case "$1" in
        -i|--ip)
			sleep 5
            case "$2" in
                "") ARG_A='some default value' ; shift 2 ;;
                *) ARG_A=$2 ; shift 2 ;;
            esac ;;
        -u|--user)
            case "$2" in
                "") ARG_B='some default value' ; shift 2 ;;
                *) ARG_B=$2 ; shift 2 ;;
            esac ;;
        *) 
				echo "Es wurden keine Optionen angeben" >&2
				exit 1
				;;
    esac
done
fi
echo "ARG_A = $ARG_A"
echo "ARG_B = $ARG_B"
#	while getopt -l "ip:" opt; do
#		case $opt in
#			i|ip)
#				echo "--ip was triggered, Parameter: $OPTARG" >&2
#				;;
#			u)
#				echo "--user was triggered, Parameter: $OPTARG" >&2
#				;;
#			\?)
#				echo "Unbekannte Option, sieh -h oder --help" >&2
#				exit 1
#				;;
#			:)
#				echo "Die Option -$OPTARG benötigt noch weiter Anweisungen." >&2
#				exit 1
#				;;
#			*) 
#				echo "Es wurden keine Optionen angeben" >&2
#				exit 1
#				;;
#		esac
#	done
#fi

#func_sys_check
#func_pass #Falls kein Zufallspasswort gewüncht ist, einfach diese Funktionen auskommentieren! und das Passwort in den Variablen definieren.
#func_password_wifi
#func_qr
