#!/bin/bash

VPN_JSON_FILE="~/.ftermvpn/vpn_config.json"

show_menu() {
    dialog --clear --backtitle "FORTICLIENT TERMINAL VPN" \
    --title "FORTICLIENT TERMINAL VPN" \
    --menu "Please choose an option:" 15 50 5 \
    1 "Connect to VPN" \
    2 "Add VPN connection" \
    3 "Edit VPN connections" \
    4 "Delete VPN connection" \
    5 "Show VPN connections" 2>menu_choice

    menuitem=$(<menu_choice)

    case $menuitem in
        1) connect_vpn ;;
        2) add_vpn ;;
        3) edit_vpn ;;
        4) delete_vpn ;;
        5) list_vpn ;;
    esac
}

add_vpn() {
    VpnName=$(dialog --inputbox "VPN name:" 8 40 3>&1 1>&2 2>&3 3>&-)
    VpnIP=$(dialog --inputbox "VPN IP:" 8 40 3>&1 1>&2 2>&3 3>&-)
    VpnPort=$(dialog --inputbox "VPN Port:" 8 40 3>&1 1>&2 2>&3 3>&-)
    VpnUser=$(dialog --inputbox "VPN Username:" 8 40 3>&1 1>&2 2>&3 3>&-)
    VpnPass=$(dialog --passwordbox "VPN Password:" 8 40 3>&1 1>&2 2>&3 3>&-)

    clear

    original_name="$VpnName"
    suffix=1
    while jq -e ".[] | select(.name == \"$VpnName\")" "$VPN_JSON_FILE" > /dev/null 2>&1; do
        suffix=$((suffix + 1))
        VpnName="${original_name}_${suffix}"
    done

    echo "Connecting to VPN..."
    vpn_output=$(sudo openfortivpn $VpnIP:$VpnPort --username="$VpnUser" --password="$VpnPass" 2>&1)

    trusted_cert=$(echo "$vpn_output" | sed -n 's/.*--trusted-cert \([a-fA-F0-9]\{64\}\).*/\1/p')

    if [ -n "$trusted_cert" ]; then
        echo "Certificate found : $trusted_cert"

        vpn_entry=$(jq -n --arg name "$VpnName" --arg ip "$VpnIP" --arg port "$VpnPort" --arg user "$VpnUser" --arg pass "$VpnPass" --arg cert "$trusted_cert" \
        '{name: $name, ip: $ip, port: $port, user: $user, pass: $pass, cert: $cert}')
        
        if [ ! -f "$VPN_JSON_FILE" ]; then
            echo "[]" > "$VPN_JSON_FILE"
        fi
        jq ". += [$vpn_entry]" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"

        dialog --msgbox "VPN added successfully. New name : $VpnName" 6 40
    else
        dialog --msgbox "Certificate not found, process failed." 6 40
    fi
    show_menu
}

delete_vpn() {
    vpn_names=$(jq -r '.[] | .name' "$VPN_JSON_FILE")
    if [ -z "$vpn_names" ]; then
        dialog --msgbox "There are no VPN for delete" 6 40
        show_menu
        return
    fi

    selected_vpn=$(dialog --menu "Select the VPN that you want to delete : " 15 50 8 $(echo "$vpn_names" | nl -w2 -s' ') 3>&1 1>&2 2>&3 3>&-)

    if [ -n "$selected_vpn" ]; then
        vpn_to_delete=$(echo "$vpn_names" | sed -n "${selected_vpn}p")
        jq "del(.[] | select(.name == \"$vpn_to_delete\"))" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"
        dialog --msgbox "VPN deleted successfully : $vpn_to_delete" 6 40
    else
        dialog --msgbox "Process canceled." 6 40
    fi
    show_menu
}

edit_vpn() {
    vpn_names=$(jq -r '.[] | .name' "$VPN_JSON_FILE")
    if [ -z "$vpn_names" ]; then
        dialog --msgbox "There are no VPN for edit" 6 40
        show_menu
        return
    fi

    selected_vpn=$(dialog --menu "Select the VPN that you want to edit : " 15 50 8 $(echo "$vpn_names" | nl -w2 -s' ') 3>&1 1>&2 2>&3 3>&-)

    if [ -z "$selected_vpn" ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    vpn_to_edit=$(echo "$vpn_names" | sed -n "${selected_vpn}p")

    vpn_ip=$(jq -r ".[] | select(.name == \"$vpn_to_edit\") | .ip" "$VPN_JSON_FILE")
    vpn_port=$(jq -r ".[] | select(.name == \"$vpn_to_edit\") | .port" "$VPN_JSON_FILE")
    vpn_user=$(jq -r ".[] | select(.name == \"$vpn_to_edit\") | .user" "$VPN_JSON_FILE")
    vpn_pass=$(jq -r ".[] | select(.name == \"$vpn_to_edit\") | .pass" "$VPN_JSON_FILE")

    new_ip=$(dialog --inputbox "VPN IP : ($vpn_ip)" 8 40 "$vpn_ip" 3>&1 1>&2 2>&3 3>&-)
    if [ $? -ne 0 ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    new_port=$(dialog --inputbox "VPN Port : ($vpn_port)" 8 40 "$vpn_port" 3>&1 1>&2 2>&3 3>&-)
    if [ $? -ne 0 ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    new_user=$(dialog --inputbox "VPN Username : ($vpn_user)" 8 40 "$vpn_user" 3>&1 1>&2 2>&3 3>&-)
    if [ $? -ne 0 ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    new_pass=$(dialog --passwordbox "VPN Password : (gizli)" 8 40 "$vpn_pass" 3>&1 1>&2 2>&3 3>&-)
    if [ $? -ne 0 ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    jq "(.[] | select(.name == \"$vpn_to_edit\") | .ip) = \"$new_ip\"" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"
    jq "(.[] | select(.name == \"$vpn_to_edit\") | .port) = \"$new_port\"" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"
    jq "(.[] | select(.name == \"$vpn_to_edit\") | .user) = \"$new_user\"" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"
    jq "(.[] | select(.name == \"$vpn_to_edit\") | .pass) = \"$new_pass\"" "$VPN_JSON_FILE" > tmp.json && mv tmp.json "$VPN_JSON_FILE"

    dialog --msgbox "VPN updated successfully." 6 40
    show_menu
}

list_vpn() {
    vpn_list=$(jq -r '.[] | "\nVPN Name : \(.name)\nIP : \(.ip)\nPort : \(.port)\nUsername : \(.user)\n---------------------------\n"' "$VPN_JSON_FILE")
    if [ -z "$vpn_list" ]; then
        dialog --msgbox "There are no saved VPN." 6 40
    else
        dialog --msgbox "Saved VPN's : \n$vpn_list" 20 50
    fi
    show_menu
}

connect_vpn() {
    vpn_names=$(jq -r '.[] | .name' "$VPN_JSON_FILE")
    if [ -z "$vpn_names" ]; then
        dialog --msgbox "There are no VPN for connect." 6 40
        show_menu
        return
    fi

    selected_vpn=$(dialog --menu "Choose the VPN you want to connect : " 15 50 8 $(echo "$vpn_names" | nl -w2 -s' ') 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$selected_vpn" ]; then
        dialog --msgbox "Process canceled." 6 40
        show_menu
        return
    fi

    vpn_to_connect=$(echo "$vpn_names" | sed -n "${selected_vpn}p")

    vpn_ip=$(jq -r ".[] | select(.name == \"$vpn_to_connect\") | .ip" "$VPN_JSON_FILE")
    vpn_port=$(jq -r ".[] | select(.name == \"$vpn_to_connect\") | .port" "$VPN_JSON_FILE")
    vpn_user=$(jq -r ".[] | select(.name == \"$vpn_to_connect\") | .user" "$VPN_JSON_FILE")
    vpn_pass=$(jq -r ".[] | select(.name == \"$vpn_to_connect\") | .pass" "$VPN_JSON_FILE")
    vpn_cert=$(jq -r ".[] | select(.name == \"$vpn_to_connect\") | .cert" "$VPN_JSON_FILE")

    sudo openfortivpn $vpn_ip:$vpn_port --username="$vpn_user" --password="$vpn_pass" --trusted-cert="$vpn_cert" > /dev/null 2>&1 &
    vpn_pid=$!  

    while true; do
        dialog --title "Connected to $vpn_to_connect VPN" --ok-label "Disconnect" --msgbox "Connected to VPN : $vpn_to_connect" 10 40

        dialog --title "Disconnect" --yesno "Are you sure you want to disconnect?" 7 40
        response=$?

        if [ $response -eq 0 ]; then
            sudo kill $vpn_pid
            dialog --msgbox "Disconnected" 6 40
            break
        fi
    done

    show_menu
}
show_menu
clear