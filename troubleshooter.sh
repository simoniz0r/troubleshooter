#!/usr/bin/env bash
# Name: troubleshooter
# Author: simonizor
# License: MIT
# Description: Collects useful information from the host system (hardware, logs, etc) for troubleshooting issues

# use /dev/tcp to make tcp connection
req.bash() {
    exec 9<> /dev/tcp/"$1"/"$2"
    cat - >& 9
    cat <& 9
}

# check if TLOG_OUT_DIR variable exists for setting log output directory
if [[ ! -z "$TLOG_OUT_DIR" ]]; then
    # create directory if does not exist
    mkdir -p "$TLOG_OUT_DIR"
else
    TLOG_OUT_DIR="$HOME/.cache"
fi
# set date for log file
LOG_DATE="$(date +%s)"
# get hardware info using inxi
# check if inxi is installed
if type inxi > /dev/null 2>&1; then
    echo -e "##### Hardware Information:\n" > "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting hardware info with inxi ('inxi -Fx')..."
    inxi -Fx | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
# if not try to find lshw
elif type lshw > /dev/null 2>&1 || [[ -f "/usr/sbin/lshw" ]]; then
    echo -e "##### Distribution Information:\n" > "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting distribution information ('cat /etc/os-release')..."
    cat /etc/os-release >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting kernel information ('uname -a')..."
    echo -e "\nKernel: $(uname -a)\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting hardware info with lshw which requires root permissions ('lshw')..."
    echo -e "##### Hardware Information:\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    sudo lshw >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
else
    echo -e "##### Distribution Information:\n" > "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting distribution information ('cat /etc/os-release')..."
    cat /etc/os-release >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting kernel information ('uname -a')..."
    echo -e "\nKernel: $(uname -a)\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo -e "##### Hardware Information:\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting available information from '/proc' ('procinfo -a')..."
    echo -e "\n###\n### 'procinfo -a':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    procinfo -a >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting CPU information ('lscpu')..."
    echo -e "\n###\n### 'lscpu':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    lscpu >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting drive information ('lsblk')..."
    echo -e "\n###\n### 'lsblk':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    lsblk >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting PCI information which requires root permissions ('sudo lspci -v')..."
    echo -e "\n###\n### 'sudo lspci -v':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    sudo lspci -v >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo "Getting USB information ('lsusb; lsusb -t')..."
    echo -e "\n###\n### 'lsusb; lsusb -t':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    echo -e "$(lsusb)\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    lsusb -t >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
fi
echo -e "\n##### System Logs:\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
# get system logs using either journalctl for systemd or rc.log and /var/log/syslog for others
if type journalctl &>/dev/null; then
    echo "Getting system logs from journalctl which requires root permissions ('sudo journalctl -xb -p 3')..."
    echo -e "\n###\n### 'sudo journalctl -xb -p 3':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    # journalctl -xb -p 3
    sudo journalctl -xb -p 3 >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log 2>&1
elif [[ -f "/var/log/rc.log" ]]; then 
    echo "Getting system logs from /var/log/rc.log"
    echo -e "\n###\n### 'cat /var/log/rc.log':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    cat /var/log/rc.log >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    if [[ -f "/var/log/syslog" ]]; then 
        echo "Getting system logs from /var/log/syslog which requires root permissions"
        echo -e "\n###\n### 'sudo cat /var/log/syslog':\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
        sudo cat /var/log/syslog >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
    fi
fi
echo "Getting dmesg log ('dmesg --level=err,warn,crit')..."
echo -e "\n###\n### 'dmesg --level=err,warn,crit':\n###\n"  >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
# dmesg --level=err,warn,crit
dmesg --level=err,warn,crit >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log 2>&1
echo "Getting Xorg log from '~/.local/share/xorg/Xorg.0.log' or '/var/log/Xorg.0.log' ..."
echo -e "\n###\n### Xorg log:\n###\n" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
# try to find Xorg log
if [[ -f "$HOME/.local/share/xorg/Xorg.0.log" ]]; then
    cat ~/.local/share/xorg/Xorg.0.log >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
elif [[ -f "/var/log/Xorg.0.log" ]]; then
    cat /var/log/Xorg.0.log >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
else
    echo "No Xorg log found!"
    echo "No Xorg log found!" >> "$TLOG_OUT_DIR"/troubleshooter."$LOG_DATE".log
fi
# try to upload log to termbin
TERMBIN_LINK="$(cat "$TLOG_OUT_DIR"/troubleshooter.$LOG_DATE.log | req.bash termbin.com 9999 | tr -d '\0')"
if [[ "$TERMBIN_LINK" =~ "https://termbin.com/" ]]; then
    echo "$(tput setaf 2)Link to contents of troubleshooter.$LOG_DATE.log : $TERMBIN_LINK$(tput sgr0)"
    # copy link to clipboard if xclip is installed
    if type xclip > /dev/null 2>&1; then
        echo "$(tput setaf 2)Link copied to clipboard$(tput sgr0)"
        echo -n "$TERMBIN_LINK" | xclip -i -selection clipboard
    fi
    rm -f "$TLOG_OUT_DIR"/troubleshooter.$LOG_DATE.log
else
    echo "$(tput setaf 1)Failed to upload 'troubleshooter.$LOG_DATE.log' to termbin.com.$(tput sgr0)"
    echo "Copy saved in '"$TLOG_OUT_DIR"/troubleshooter.$LOG_DATE.log'"
fi
