# Forticlient Terminal VPN (ftermvpn)

Forticlient Terminal VPN (ftermvpn) is a tool that allows you to manage your VPN connections with Forticlient VPN in a faster, more practical and stable way through a terminal. Through a terminal-based menu, you can easily start your VPN connections and manage them without disconnections.

I was encouraged to develop this tool because the user interface of Forticlient on macOS was inadequate and people around me who used Forticlient VPN often experienced disconnection problems. After realizing that VPN connections through the terminal largely eliminated such problems, I aimed to provide a simple and effective solution that even users with limited system knowledge could easily use.

## Dependencies

### For MacOS

You need to have brew installed on your system. If you dont have brew, you can check this official website for brew installation : [Brew Official Website](https://brew.sh/)

After you installed brew, you need to install `dialog` for UI stylish menu, `jq` for JSON processes and `wget` for download the necessary files.

> :bulb:  You don't have to install wget, you can manually copy the file contents from the repo, but if you're lazy I suggest you do.

```bash
brew install openfortivpn
brew install dialog
brew install jq
brew install wget
```

### For Linux

**Linux support will added soon.**

At the moment I haven't adapted it for linux systems yet. I will share it as soon as I can. If you don't want to wait, you can use it on linux by using **`whiptail`** instead of **`dialog`** and making the relevant changes.

## Setup instructions

### 1. Create the .ftermvpn directory

Create a hidden directory in your home directory and set standard permissions with following code : 

```bash
mkdir -m 755 ~/.ftermvpn
```
### 2. Download the necessary files


```bash
wget -O ~/.ftermvpn/ftermvpn.sh https://raw.githubusercontent.com/bugra-gokcek/Forticlient-Terminal-VPN/refs/heads/main/ftermvpn_for_mac.sh

wget -O ~/.ftermvpn/vpn_config.json https://raw.githubusercontent.com/bugra-gokcek/Forticlient-Terminal-VPN/refs/heads/main/vpn_config.json
```

### 3. Set execute permissions for the script

Make the `ftermvpn.sh` script executable :

```bash
chmod +x ~/.ftermvpn/ftermvpn.sh
```


### 4. Set read-write permissions for the config file

Ensure that the `vpn_config.json` file has appropriate read-write permissions : 

```bash
chmod 664 ~/.ftermvpn/vpn_config.json
```

### 5. Create a symbolic link for easier access

Create a symbolic link in `/usr/local/bin` to run the script using the `ftermvpn` command :

```bash
sudo ln -s ~/.ftermvpn/ftermvpn.sh /usr/local/bin/ftermvpn
```

After completing these steps, you can run the `ftermvpn` by simply typing ftermvpn in the terminal.

### 5.1 Alternative way : Alias

If you dont want to create link or you have some issues with links, you can create an alias for easier access. 

#### Mac

```bash
echo "alias ftermvpn='bash ~/.ftermvpn/ftermvpn.sh'" >> ~/.zshrc
```

#### Linux

```bash
echo "alias ftermvpn='bash ~/.ftermvpn/ftermvpn.sh'" >> ~/.bashrc
```

---
## Issues and Help

If you need help or encounter an issue, feel free to open an issue. I’ll assist as quickly as possible.
