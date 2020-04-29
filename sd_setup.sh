#!/bin/bash
# shellcheck disable=SC2010  # ls  | grep allowed

echo "Setupscript for Raspberry Pi SD's"
echo
echo "@author Kevin Veen-Birkenbach [kevin@veen.world]"
echo "@since 2017-03-12"
echo

echo "Starting setup..."

echo "Define working folder..."
working_folder="/tmp/raspberry-pi-tools-$(date +%s)/";


echo "Create temporary working folder in $working_folder";
mkdir -v "$working_folder"

echo "Checking if root..."
if [ "$(id -u)" != "0" ];then
    echo "This script must be executed as root!" && exit 1
fi

echo "Configure user..."
echo "Please type in a valid username from which the SSH-Key should be copied:"
read -r origin_username;
getent passwd "$origin_username" > /dev/null 2 || (echo "User $origin_username doesn't exist. Abord program." && exit 1);
origin_user_home="/home/$origin_username/";

echo "Image routine starts..."
image_folder="$origin_user_home""Images/";
echo "The images will be stored in \"$image_folder\"."
if [ ! -d "$image_folder" ]; then
  echo "Folder \"$image_folder\" doesn't exist. It will be created now."
  mkdir -v "$image_folder"
fi

echo "Select sd-card..."
echo "List of actual mounted devices:"
ls -lasi /dev/ | grep -E "sd|mm"
echo
while [ ! -b "$sd_card_path" ]
	do
		echo "Please type in the name of the correct sd-card."
		echo "/dev/:"
		read -r device
		sd_card_path="/dev/$device"
done

echo "Select which Raspberry Pi version should be used"
read -r version

echo "Select which operation system should be used..."
echo
echo "1) arch"
echo "2) moode"
echo "3) retropie"
echo
echo "Please type in the os:"
read -r os


os_does_not_support_raspberry_version_error () {
  echo "$1 for Raspberry Pi Version $2 is not supported!" && exit 1;
}

case "$os" in
  "arch")
    base_download_url="http://os.archlinuxarm.org/os/";
    case "$version" in
      "1")
        imagename="ArchLinuxARM-rpi-latest.tar.gz"
        ;;
      "2" | "3")
        imagename="ArchLinuxARM-rpi-2-latest.tar.gz"
        ;;
      "4")
        imagename="ArchLinuxARM-rpi-4-latest.tar.gz"
        ;;
      *)
        os_does_not_support_raspberry_version_error "$os" "$version"
        ;;
    esac
    ;;
  "moode")
    image_checksum="185cbc9a4994534bb7a4bc2744c78197"
    base_download_url="https://github.com/moode-player/moode/releases/download/r651prod/"
    imagename="moode-r651-iso.zip";
    ;;
  "retropie")
    base_download_url="https://github.com/RetroPie/RetroPie-Setup/releases/download/4.6/";
    case "$version" in
      "1")
        image_checksum="98b4205ad0248d378c6776e20c54e487"
        imagename="retropie-buster-4.6-rpi1_zero.img.gz"
        ;;

      "2" | "3")
        image_checksum="2e082ef5fc2d7cf7d910494cf0f7185b"
        imagename="retropie-buster-4.6-rpi2_rpi3.img.gz"
        ;;

      "4")
        image_checksum="9154d998cba5219ddf23de46d8845f6c"
        imagename="retropie-buster-4.6-rpi4.img.gz"
        ;;
      *)
        os_does_not_support_raspberry_version_error "$os" "$version"
        ;;
    esac
    ;;
  *)
    echo "The operation system \"$os\" is not supported yet!" && exit 1;
  ;;
esac

echo "Download os-image..."
download_url="$base_download_url$imagename"
image_path="$image_folder$imagename"

if [ ! -f "$image_path" ]
	then
		echo "The selected image \"$imagename\" doesn't exist under local path \"$image_path\"."
		if [ ! -f "$image_path" ]
			then
				echo "Image \"$imagename\" gets downloaded from \"$download_url\"..."
				wget "$download_url" -P "$image_folder" || (echo "Download failed. Program aborted." && exit 1)
		fi
fi

echo "Verifying image..."
if [[ -v image_checksum ]]
  then
    echo "$image_checksum $image_path"| md5sum -c -|| (echo "Verification failed. Program aborted." && exit 1)
  else
    echo "WARNING: Verification is not possible. No checksum is define."
fi
exit
echo "Preparing mount paths..."
boot_mount_path="$working_folder""boot"
root_mount_path="$working_folder""root"
mkdir -v "$boot_mount_path"
mkdir -v "$root_mount_path"

echo "Defining partition paths..."
if [ "${sd_card_path:5:1}" != "s" ]
  then
    partion="p"
  else
    partion=""
fi
boot_partition_path=$sd_card_path$partion"1"
root_partition_path=$sd_card_path$partion"2"

mount_partitions(){
  echo "Mount boot and root partition..."
  mount "$boot_partition_path" "$boot_mount_path" || (echo "Mount from $boot_partition_path to $boot_mount_path failed..." && exit 1)
  mount "$root_partition_path" "$root_mount_path" || (echo "Mount from $root_partition_path to $root_mount_path failed..." && exit 1)
  echo "The following mounts refering this setup exist:" && mount | grep "$working_folder"
}

echo "Copy data to sd-card..."
case "$os" in
  "arch")
    echo "fdisk is executedman fd"
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
    )| fdisk "$sd_card_path"

    echo "Format boot partition..."
    mkfs.vfat "$boot_partition_path"

    echo "Format root partition..."
    mkfs.ext4 "$root_partition_path"

    mount_partitions;

    echo "Root files will be transfered to sd-card..."
    bsdtar -xpf "$image_path" -C "$root_mount_path"
    sync

    echo "Boot files will be transfered to sd-card..."
    mv -v "$root_mount_path/boot/"* "$boot_mount_path"

    ;;
  "moode")
    unzip -p "$image_path" | sudo dd of="$sd_card_path" bs=4M conv=fsync || (echo "Copy failed. Aborted." && exit 1)
    sync

    mount_partitions;
    ;;
  "retropie")
    gunzip -c "$image_path" | sudo dd of="$sd_card_path" bs=4M conv=fsync
    sync

    mount_partitions;
    ;;
  *)
    echo "The operation system \"$os\" is not supported yet!" && exit 1;
    ;;
esac

echo "Define target paths..."
target_home_path="$root_mount_path/home/";
target_username=$(ls "$target_home_path");
target_user_home_folder_path="$target_home_path$target_username/";

echo "Copy ssh key to target..."
target_user_ssh_folder_path="$target_user_home_folder_path"".ssh/"
target_authorized_keys="$target_user_ssh_folder_path/authorized_keys"
origin_user_rsa_pub="$origin_user_home/.ssh/id_rsa.pub";
if [ -f "$origin_user_rsa_pub" ]
  then
    mkdir -v "$target_user_ssh_folder_path"
    cat "$origin_user_rsa_pub" > "$target_authorized_keys"
    target_authorized_keys_content=$(cat "$target_authorized_keys")
    echo "$target_authorized_keys contains the following: $target_authorized_keys_content"
    chown -vR 1000 "$target_user_ssh_folder_path"
    chmod -vR 400 "$target_user_ssh_folder_path"
  else
    echo "The ssh key \"$origin_user_rsa_pub\" can't be copied to \"$target_authorized_keys\" because it doesn't exist."
fi

echo "Change password of user \"$target_username\"..."
chroot "$root_mount_path" /bin/passwd "$target_username"

echo "Change password of root user..."
chroot "$root_mount_path" /bin/passwd root

echo "Do you want to copy all Wifi passwords to the sd-card?(y/n)"
read -r copy_wifi
if [ "$copy_wifi" = "y" ]
  then
    origin_wifi_config_path="/etc/NetworkManager/system-connections/"
    target_wifi_config_path="$root_mount_path$origin_wifi_config_path"
    rsync -av "$origin_wifi_config_path" "$target_wifi_config_path"
fi
echo "The first level folder structure on $root_mount_path is now:" && tree -laL 1 "$root_mount_path"
echo "The first level folder structure on $boot_mount_path is now:" && tree -laL 1 "$boot_mount_path"
echo "Cleaning up..."
umount -v "$root_mount_path" "$boot_mount_path"
rm -vr "$working_folder"
echo "Setup successfull :)" && exit 0
