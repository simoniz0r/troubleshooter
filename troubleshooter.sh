#!/usr/bin/env bash
# Name: troubleshooter
# Author: simonizor
# License: MIT
# Description: Collects useful information from the host system (hardware, logs, etc) for troubleshooting issues
# Dependencies: systemd

# set date for log file
LOG_DATE="$(date +%s)"
# get hardware info using inxi
# check if inxi is installed
echo -e "##### Hardware Information:\n" > ~/.cache/troubleshooter."$LOG_DATE".log
if type inxi > /dev/null 2>&1; then
    echo "Getting hardware info with inxi ('inxi -Fx')..."
    inxi -Fx >> ~/.cache/troubleshooter."$LOG_DATE".log
# if not try to find lshw
elif type lshw > /dev/null 2>&1; then
    echo "Getting hardware info with lshw ('lshw')..."
    lshw >> ~/.cache/troubleshooter."$LOG_DATE".log
elif [[ -f "/usr/sbin/lshw" ]]; then
    echo "Getting hardware info with lshw ('/usr/sbin/lshw')..."
    /usr/sbin/lshw >> ~/.cache/troubleshooter."$LOG_DATE".log
else
    echo "Failed to get hardware information!"
    echo "Failed to get hardware information!" >> ~/.cache/troubleshooter."$LOG_DATE".log
fi
echo -e "\n##### System Logs:\n" >> ~/.cache/troubleshooter."$LOG_DATE".log
echo "Getting system logs from journalctl which requires root permissions ('sudo journalctl -xb -p 3')..."
echo -e "\n###\n### 'sudo journalctl -xb -p 3':\n###\n" >> ~/.cache/troubleshooter."$LOG_DATE".log 2>&1
# journalctl -xb -p 3
sudo journalctl -xb -p 3 >> ~/.cache/troubleshooter."$LOG_DATE".log 2>&1
echo "Getting dmesg log ('dmesg --level=err,warn')..."
echo -e "\n###\n### 'dmesg --level=err,warn':\n###\n"  >> ~/.cache/troubleshooter."$LOG_DATE".log
# dmesg --level=err,warn
dmesg --level=err,warn >> ~/.cache/troubleshooter."$LOG_DATE".log 2>&1
echo "Getting Xorg log from '~/.local/share/xorg/Xorg.0.log' or '/var/log/Xorg.0.log' ..."
echo -e "\n###\n### Xorg log:\n###\n" >> ~/.cache/troubleshooter."$LOG_DATE".log
# try to find Xorg log
if [[ -f "$HOME/.local/share/xorg/Xorg.0.log" ]]; then
    cat ~/.local/share/xorg/Xorg.0.log >> ~/.cache/troubleshooter."$LOG_DATE".log
elif [[ -f "/var/log/Xorg.0.log" ]]; then
    cat /var/log/Xorg.0.log >> ~/.cache/troubleshooter."$LOG_DATE".log
else
    echo "No Xorg log found!"
    echo "No Xorg log found!" >> ~/.cache/troubleshooter."$LOG_DATE".log
fi
# try to upload log to termbin
if type nc > /dev/null 2>&1; then
    TERMBIN_LINK="$(cat ~/.cache/troubleshooter.$LOG_DATE.log | nc termbin.com 9999 | tr -d '\0')"
    if [[ "$TERMBIN_LINK" =~ "https://termbin.com/" ]]; then
        echo "$(tput setaf 2)Link to contents of troubleshooter.$LOG_DATE.log : $TERMBIN_LINK$(tput sgr0)"
        # copy link to clipboard if xclip is installed
        if type xclip > /dev/null 2>&1; then
            echo "$(tput setaf 2)Link copied to clipboard$(tput sgr0)"
            echo -n "$TERMBIN_LINK" | xclip -i -selection clipboard
        fi
        rm -f ~/.cache/troubleshooter.$LOG_DATE.log
    else
        echo "$(tput setaf 1)Failed to upload 'troubleshooter.$LOG_DATE.log' to termbin.com.$(tput sgr0)"
        echo "Copy saved in '~/.cache/troubleshooter.$LOG_DATE.log'"
    fi
else
    echo "$(tput setaf 1)Failed to upload 'troubleshooter.$LOG_DATE.log' to termbin.com.$(tput sgr0)"
    echo "Copy saved in '~/.cache/troubleshooter.$LOG_DATE.log'"
fi
