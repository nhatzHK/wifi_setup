#/usr/bin/sh

################################################################################
#===================================LICENSE====================================#
# This is licensed under the WILY license ©somewhere in time                   #
#==============================================================================#

#==============================================================================#
# Establish wireless connection with wpa_supplicant and dhcpd                  #
# -----------------------------------------------------------------------------#
# Some say the wheel shouldn't be reinvented                                   #
# Others claims it should be reinvented to lose some performance               #
# I agree with the later group                                                 #
# If that's not your case, consider visiting this link:                        #
# https://wiki.archlinux.org/index.php/WPA_supplicant                          #
# -----------------------------------------------------------------------------#
# Most of this is copy-pasta from various website that I won't credit here     #
# I'm mostly proud of the parts consisting of the symbols: -, =, #             #
#==============================================================================#

################################################################################

#------------------------------------------------------------------------------#
# Functions declarations                                                       #
#------------------------------------------------------------------------------#

# Connection without encryption
function no_encrypt () {
    # iw dev interface connect "your_essid"
    printf "$PROMPT Connecting to $2 with interface $1\n\n"
    iw dev $1 connect $2
}

# Connection to WEP
# The implementation of this function is left as an exercice for the reader :)
#function wep () {
#}

# Connection to a WPA/WPA2
function wpa_2 () {
    printf "$PROMPT Connecting to $2 with interface $1\n"
    wpa_passphrase $2 $3 >> .temp.wifi_setup
    wpa_supplicant -i $1 -c .temp.wifi_setup -B
    rm .temp.wifi_setup
}

# Set interface up
function set_i_up () {
    ip link set $1 up
}

# Kill all wpa_supplicant and dhcpcd processes
function kill_all {
    printf "$PROMPT Killing all wpa_supplicant and dhcpcd processes\n"
    killall wpa_supplicant`
    killall dhcpcd`
}

################################################################################

#------------------------------------------------------------------------------#
#                                VARIABLES                                     #
#------------------------------------------------------------------------------#
HELP='wifi_setup.help'                           # Help file location
PROMPT='[WIFI_SETUP] : '                                             # Prompt :)
declare interface                                  # Interface to use, i.e wlan0
declare e_ssid                                                    # Network name
declare psswd                                                         # Password

#------------------------------------------------------------------------------#
#                              Argument parsing                                #
#------------------------------------------------------------------------------#
# Use -gt 1 to consume two arguments per pass in the loop (e.g. each           #
# argument has a corresponding value to go with it).                           #
# To you bash illiterate who won't look up what gt is -> greater than          #
# The meaning of -lt is left has an exercise for the reader                    #
# This means you have to associate each flag with a value                      #
# Otherwise you're screwed                                                     #
# -----------------------------------------------------------------------------#
if [[ $# -lt 2 ]]; then
    cat $HELP
    exit 1
fi

# Save arguments in case whoami != root
args=("$@")

while [[ $# -gt 1 ]]
do
    key="$1"

    case $key in
        -i|--interface)
            interface="$2"
            shift                                                # past argument
        ;;
        -e|-s|--essid|--ssid)
            e_ssid="$2"
            shift                                                # past argument
        ;;
        -p|--pswd)
            psswd="$2"
            shift                                                # past argument
        ;;
        -h|--help)                                  # A loser is asking for help 
            printf "$PROMPT Asking for help without shame huh?\n"
            cat $HELP                                                   # Quick
            exit 1                                                  # Let's exit
        ;;
            *)                                                  # unknown option
            printf "$PROMPT Unknown argument $key\n$PROMPT Ignoring\n"
            cat $HELP | head -n 11 | tail -n 4 
            shift               # To shift or not to shift? In the doubt, shift!
        ;;
    esac
    shift                                               # past argument or value
done

################################################################################

#------------------------------------------------------------------------------#
# You shall not run this script if you're not root, move along                 #
# Putting this down there because you don't need root to ask for help          #
# You don't need root to call the script wrongly neither                       #
# -----------------------------------------------------------------------------#
[ "$(whoami)" != "root" ] && exec sudo --  "$0" "${args[@]}"

################################################################################

#------------------------------------------------------------------------------#
# Validity checks and functions calling                                        #
#------------------------------------------------------------------------------#
# If both the interface and the e?ssid are provided
if [[ -n "$interface" ]] && [[ -n "$e_ssid" ]]; then
 
    kill_all
    set_i_up $interface 

    if [[ -n "$psswd" ]]; then
        wpa_2 $interface $e_ssid $psswd
    else
        no_encrypt $interface $e_ssid
    fi
  
    dhcpcd $interface # This 
else
    # Print this to help loosers figure out the usage
    printf "$PROMPT Invalid arguments\n"
    cat $HELP
    exit 3
fi

################################################################################
#                                      THE END                                 #
################################################################################
