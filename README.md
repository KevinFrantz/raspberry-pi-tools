# Raspberry Pi sdc tools
This repository contains some shell scripts to install Arch Linux for the Raspberry Pi on a SD-Card and to backup a SD-Card.
## Todo

- Implement ssh configuration
- Implement wifi automation

## Setup
### SD-Card
#### Guided
To install a Linux distribution manually on a SD card type in:

```bash
  bash ./sd_setup.sh
```
#### Piped
To pase the configuration to the program use this syntax:
```bash
(
  echo "$USER"              # | The username
  echo "mmcblk1"            # | The device
  echo "3"                  # | The raspberry pi number
  echo "arch"           # | The operation system
  echo "n"                  # | Force image download
  echo "n"                  # | Transfer image
  #echo "n"                 # ├── Overwrite device before copying
  echo "test12345"          # | The user password
  echo "test12345"          # | The root password
  echo "example-host"       # | The hostname
  echo "y"                  # | Setup Wifi on target system
)| sudo bash ./sd_setup.sh
```

### System
#### Arch
```bash
  pacman-key --init
  pacman-key --populate archlinuxarm
  install -m640 /etc/netctl/examples/wireless-wpa domo-de-kosmopolitoj-wpa
  nano domo-de-kosmopolitoj-wpa
  netctl start domo-de-kosmopolitoj-wpa
  netctl enable domo-de-kosmopolitoj-wpa
```
#### Ubuntu\\Debian
```bash
  sudo apt update
  sudo apt upgrade
```
## Backup
To backup a SD card type in:

```bash
  bash ./sd_backup.sh
```

## License

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
