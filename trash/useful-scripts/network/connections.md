# Setting up wifi during installation:
https://wiki.archlinux.org/title/Iwd

# Wifi
Do not use Network Manager and IWD together.

## NetworkManager
More feature-rich than IWD.
`nmtui` is a terminal gui for network manager.
`nmcli` is a cmd tool.

```bash
sudo systemctl start NetworkManager
nmtui
nmtui connect
```
### 802-1x and WPA & WPA2 Enterprise
Need to add a new connection first using `nmcli` and add credentials.
Then, after that you are able to use `nmtui`.

```bash
nmcli connection add type wifi ifname wlan0 con-name CONNECTION_NAME ssid SSID
nmcli connection edit CONNECTION_NAME
> set 802-1x.eap peap
> set 802-1x.phase2-auth mschapv2
> set wifi-sec.key-mgmt wpa-eap
> set 802-1x.identity USERNAME 
> set 802-1x.password PASSWORD
> save
> activate
```


## IWD
This is not necessary.
But it might be useful during installation.
Basic network configurator.

```bash
# sudo systemctl start NetworkManager
# nmcli --ask device wifi connect <ssid>
sudo systemctl start iwd
iwctl
> device list
> station <device_name> scan
> station <device_name> get-networks
> station <device_name> connect <SSID>
```

If you want to connect to a 8021x security network do the next 3 steps.

Add ssid setting in /var/lib/iwd/<ssid.security>. Example File:
```bash
[Security]
EAP-Method=PEAP
EAP-Identity=anonymous@realm.edu
EAP-PEAP-CACert=/path/to/root.crt
EAP-PEAP-ServerDomainMask=radius.realm.edu
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=johndoe@realm.edu
EAP-PEAP-Phase2-Password=hunter2

[Settings]
AutoConnect=true
```

MAYBE change `/etc/iwd/main.conf`
MAYBE `iconv -t utf16le | openssl md4 -provider legacy # hash your password`

```bash
touch /var/lib/iwd/<ssid>.<security>
iwctl
> device list
> station <station_name> scan
> station <station_name> get-networks
> station <station_name> connect <ssid>
> exit
```


