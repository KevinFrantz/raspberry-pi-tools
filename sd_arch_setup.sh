#!/bin/bash
echo "Setupscript fuer Raspberry Pi SD's"
echo "Dieses Script  muss aus dem Ordner aufgerufen werden, in welchem ArchLinuxARM-rpi-2-latest.tar.gz liegt"
echo
echo "@author KevinFrantz"
echo "@since 2017-03-12"
echo
if [ `id -u` != 0 ];then
    echo "Das Script muss als Root aufgerufen werden!"
    exit 1
fi
echo "Liste der aktuell gemounteten Geraete:"
echo
ls -lasi /dev/ | grep -E "sd|mm"
echo "(Die Liste zeigt nur Geraete an welche auf den Filter passen)"
echo
while [ \! -b "$ofi" ]
	do
		echo "Bitte waehlen Sie die korrekte SD-Karte aus:"
		echo "/dev/:"
		read device
		ofi="/dev/$device"
done
#Pruefen ob der Pfad existiert hinzufuegen
while [ "$workingpath" == "" ]
	do
		echo "Bitte waehlen Sie den Arbeitspfad zu $(pwd) aus:"
		read workingpath
		if [ "${workingpath:0:1}" != "/" ]
			then
				workingpath=$(pwd)"/"$workingpath
		fi
		if [ -d "$workingpath" ]
			then
				i=$((${#workingpath}-1)) #Letzte Zeichenstelle ermitteln
				if [ "${workingpath:$i:1}" != "/" ]
					then
						workingpath=$workingpath"/"
				fi
			else
				echo "Der ausgewaehlte Arbeitspfad existiert nicht."
				workingpath=""
		fi

done
echo "Bitte geben Sie ein, für welchen Raspberry das Image aufgespielt werden soll:"
read version
if [ "$version" == "" ]
  then
    version="3"
fi
echo "Image für RaspberryPi $version wird verwendet..."
imagename="ArchLinuxARM-rpi-$version-latest.tar.gz"
downloadurl="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-$version-latest.tar.gz"
while [ "$imagepath" == "" ]
	do
		echo "Setzen Sie den Imagenamen(Standart:$workingpath$imagename)"
		read image
		if [ "$image" == "" ]
			then
				imagepath=$workingpath$imagename
			else
				imagepath=$workingpath$image
		fi
		if [ \! -f "$imagepath" ]
			then
				echo "Das ausgewaehlte Image existiert nicht!"
				#Image ggf. downloaden
				if [ \! -f "$imagepath" ]
					then
						echo "Image wird gedownloadet..."
						wget $downloadurl
				fi
		fi

done

#Nutzer definieren
echo "Geben Sie den Nutzer an, von welchem der SSH-Key kopiert werden soll:"
read user;

echo "Die Arbeitsvariablen werden gesetzt..."
bootpath=$workingpath"boot"
rootpath=$workingpath"root"

ssh_key_source="/home/$user/.ssh/id_rsa.pub"
ssh_key_target="$rootpath/home/alarm/.ssh/authorized_keys"

if [ "${ofi:5:1}" != "s" ]
	then
		partion="p"
	else
		partion=""
fi
ofiboot=$ofi$partion"1"
ofiroot=$ofi$partion"2"
echo "Arbeitsverzeichnis: $workingpath"
echo "Rootpath: $rootpath"
echo "Bootpath: $bootpath"
echo "Imagepath: $imagepath"
echo "SD-Karte: $ofi"
echo "SD-Karte-Partition 1(boot): $ofiboot"
echo "SD-Karte-Partition 2(root): $ofiroot"
echo "SSH-Source-Path: $ssh_key_source"
echo "SSH-Target-Path: $ssh_key_target"
echo "Bestaetigen Sie mit der Enter-Taste. Zum Abbruch Ctrl + Alt + C druecken"
read bestaetigung
echo "fdisk wird ausgefuehrt..."
(	echo "o"	#Type o. This will clear out any partitions on the drive.
	echo "p"	#Type p to list partitions. There should be no partitions left
	echo "n"	#Type n,
	echo "p"	#then p for primary,
	echo "1"	#1 for the first partition on the drive,
	echo ""		#press ENTER to accept the default first sector,
	echo "+100M"	#then type +100M for the last sector.
	echo "t"	#Type t,
	echo "c"	#then c to set the first partition to type W95 FAT32 (LBA).
	echo "n"	#Type n,
	echo "p"	#then p for primary,
	echo "2"	#2 for the second partition on the drive,
	echo ""		#and then press ENTER twice to accept the default first and last sector.
	echo ""
	echo "w"	#Write the partition table and exit by typing w.
)| fdisk $ofi

#Bootpartion formatieren und mounten
echo "Generiere und mounte boot-Partition..."
mkfs.vfat $ofiboot
mkdir $bootpath
mount $ofiboot $bootpath

#Rootpartition formatieren und mounten
echo "Generiere und mounte root-Partition..."
mkfs.ext4 $ofiroot
mkdir $rootpath
mount $ofiroot $rootpath

echo "Die Root-Dateien werden auf die SD-Karte aufgespielt..."
bsdtar -xpf $imagepath -C $rootpath
sync

echo "Die Boot-Dateien werden auf die SD-Karte aufgespielt..."
mv -v $rootpath"/boot/"* $bootpath

if [ "$user" != "" ] && [ -f "$ssh_key_source" ]
	then
		echo "Der SSH-Key wird auf den Raspberry kopiert..."
		mkdir -v "$rootpath/home/alarm/.ssh"
		cat "$ssh_key_source" > "$ssh_key_target"
		chown -R 1000 "$rootpath/home/alarm/.ssh"
		chmod -R 400 "$rootpath/home/alarm/.ssh"
fi

echo "Script rauemt das Verzeichnis auf..."
umount $rootpath $bootpath
rm -r $rootpath
rm -r $bootpath
