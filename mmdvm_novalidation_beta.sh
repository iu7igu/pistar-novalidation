#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "Questo script deve essere eseguito come root ( sudo ./mmdvm_novalidation.sh )" 1>&2
   exit 1
fi

echo "
**********************************************************************************
*****IU7IGU-CISARLecce & DIGILAND GROUP MMDVM-NOValidation Script for PI-STAR*****
**********************************************************************************

**********************************************************************************
******************************TOOLz for PI-STAR MENU'*****************************
**********************************************************************************
"

display=false
permanent=false

pistar-reset(){
	systemctl stop pistar-watchdog.timer
	systemctl stop pistar-watchdog
	systemctl stop mmdvmhost.timer
	systemctl stop mmdvmhost
	echo "Processi di PI-STAR fermati"
	echo "Ripristino il pistar-update"
	rm /usr/local/sbin/pistar-update
	cd /usr/local/sbin/
	wget https://raw.githubusercontent.com/AndyTaylorTweet/Pi-Star_Binaries_sbin/master/pistar-update -O pistar-update > /dev/null 2>&1
	chmod +x /usr/local/sbin/pistar-update
	echo "Ora puoi aggiornare il sistema"
	systemctl start pistar-watchdog.timer
	systemctl start pistar-watchdog 
	systemctl start mmdvmhost.timer
	systemctl start mmdvmhost
	echo "Processi di PI-STAR riavviati"
	

mmdvm_novalidation(){
	systemctl stop pistar-watchdog.timer
	systemctl stop pistar-watchdog
	systemctl stop mmdvmhost.timer
	systemctl stop mmdvmhost
	echo "Processi di PI-STAR fermati"
	echo "Scarico i file necessari --->"
	echo "Download MMDVMHost"
	git clone https://github.com/g4klx/MMDVMHost.git > /dev/null 2>&1
	if [ -f DStarControl.cpp]; then
		rm DStarControl.cpp
	fi
	if $permanent; then
		echo "Download Pistar-update modificato"
		if [ -f pistar-update-mod* ]; then
			rm pistar-update-mod*
		fi
		if [[ $2 == "hd" && -n "$2" ]]; then
			wget http://iu7igummdvm.duckdns.org/mmdvm/pistar-update-mod-hd -O pistar-update-mod-hd > /dev/null 2>&1
			rm /usr/local/sbin/pistar-update
			mv pistar-update-mod-hd /usr/local/sbin/pistar-update
			chmod +x /usr/local/sbin/pistar-update
		else
			wget http://iu7igummdvm.duckdns.org/mmdvm/pistar-update-mod -O pistar-update-mod > /dev/null 2>&1
			rm /usr/local/sbin/pistar-update
			mv pistar-update-mod /usr/local/sbin/pistar-update
			chmod +x /usr/local/sbin/pistar-update
		fi
	fi
	echo "Download DStarControl.cpp per il NOValidation"
	wget http://iu7igummdvm.duckdns.org/mmdvm/DStarControl.cpp -O DStarControl.cpp > /dev/null 2>&1
	if [ -f ok.rules ]; then
		rm ok.rules
	fi
	echo "Download file rules per abilitare le porte USB/AMA/ACM"
	wget http://iu7igummdvm.duckdns.org/mmdvm/ok.rules -O ok.rules > /dev/null 2>&1
	mv DStarControl.cpp MMDVMHost/DStarControl.cpp
	
	cd MMDVMHost
	
	if $display; then
		echo "Compilo MMDVMHost con supporto per HD44780"
		echo
		make clean > /dev/null 2>&1
		make -f Makefile.Pi.HD44780
	else
		echo "Compilo MMDVMHost"
		echo
		make clean > /dev/null 2>&1
		make -f Makefile.Pi.OLED
	fi

	echo "Sostituzione MMDVMHost e rules con backup"
	cd /usr/local/bin/
	echo "Muovo MMDVMHost"
	if [ -f MMDVMHost ]; then
		cp MMDVMHost MMDVMHost.bak
		cd /home/pi-star/MMDVMHost
		mv MMDVMHost /usr/local/bin/
	else
		cd /home/pi-star/MMDVMHost
		mv MMDVMHost /usr/local/bin/
	fi
	cd /etc/udev/rules.d/
	echo "Muovo il file Rules"
	if [ -f 99-com.rules ]; then
		cp 99-com.rules 99-com.rules.bak
		rm 99-com.rules
		cd /home/pi-star/
		mv ok.rules /etc/udev/rules.d/99-com.rules
	else
		cd /home/pi-star/
		mv ok.rules /etc/udev/rules.d/99-com.rules
	fi
	echo "Installazione completata, rimuovo i file scaricati"
	rm -r /home/pi-star/MMDVMHost
	systemctl start pistar-watchdog.timer
	systemctl start pistar-watchdog 
	systemctl start mmdvmhost.timer
	systemctl start mmdvmhost
	echo "Processi di PI-STAR riavviati"
}
	
if [[ $1 == "up" && -n "$1" ]]; then
	if [[ $2 == "hd" && -n "$2" ]]; then
		display=true
		fi
	permanent=true
	mmdvm_novalidation
else
	PS3="Scegli tra le varie opzioni: "
options=("Installa MMDVM-NOValidation" "Installa MMDVM-NOValidation con supporto per HD44780" "Installa MMDVM-NOValidation in modo permanente" "Installa MMDVM-NOValidation con supporto per HD44780 in modo permanente" "Ripristina Pistar-Update" "Cambia server DMRIds.dat (Anti-GDPR)" "Riavvia" "!!Esci!!")
select opt in "${options[@]}"
do
    case $opt in
        "Installa MMDVM-NOValidation")
			echo "Installo MMDVM-NOValidation";
			display=false
			mmdvm_novalidation
			break
            ;;
        "Installa MMDVM-NOValidation con supporto per HD44780")
            echo "Installo MMDVM-NOValidation con supporto per HD44780"
			display=true
			mmdvm_novalidation
			break
            ;;
		"Ripristina Pistar-Update")
            echo "Resetto il Pistar-Update"
			pistar-reset
			break
            ;;
		"Installa MMDVM-NOValidation in modo permanente")
            echo "Installo MMDVM-NOValidation in modo permanente"
			display=false
			permanent=true
			mmdvm_novalidation
			break
            ;;
		"Installa MMDVM-NOValidation con supporto per HD44780 in modo permanente")
            echo "Installo MMDVM-NOValidation con supporto per HD44780"
			display=true
			permanent=true
			mmdvm_novalidation
			break
            ;;
        "Cambia server DMRIds.dat (Anti-GDPR)")
			echo "Sostituisco il file HostFilesUpdate.sh"
            wget http://iu7igummdvm.duckdns.org/mmdvm/HostFilesUpdate.sh > /dev/null
			mv HostFilesUpdate.sh /usr/local/sbin/HostFilesUpdate.sh
			cd /usr/local/sbin/
			chmod +x HostFilesUpdate.sh
			echo "Aggiorno il file DMRIds.dat dal server americano"
			./HostFilesUpdate.sh
			echo
			echo "I NOMINATIVI SARANNO VISUALIZZATI AL RIAVVIO DEL SISTEMA"
			echo
			break
            ;;
		"Riavvia")
			read -p "Ho finito di installare tutto, posso riavviare ora? Y/N" -n 1 -r
			if [[ $REPLY =~ ^[Yy]$ ]];then
				/sbin/reboot
			fi
			break
			;;
        "!!Esci!!")
            break
            ;;
        *) echo "Scelta non valida";;
    esac
done
fi


