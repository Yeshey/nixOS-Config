alias neofetch="hyfetch";
alias re-kde="nix-shell -p killall --command \"kquitapp5 plasmashell || killall plasmashell ; kstart5 plasmashell\""; # Restart gui in KDE
alias mount="mount|column -t";                      # Pretty mount
alias temperature="watch \"nix-shell -p lm_sensors --command sensors | grep temp1 | awk '{print $2}' | sed 's/+//'\"";
alias ping="ping -c 5";                             # Control output of ping
alias grep="grep --color=auto";
alias egrep="egrep --color=auto";
alias fgrep="fgrep --color=auto";
alias diff="colordiff";
alias dir="dir --color=auto";
alias vdir="vdir --color=auto";
alias myip="  
    echo \"Your external IP address is:\"
    curl -w '\n' https://ipinfo.io/ip
";
space() {
    watch "df -h . && df ."
}
gacp() {
    local commitMsg="$1"
    
    # Check if both arguments are provided, if not, exit with an error message
    if [ -z "$commitMsg" ]; then
        echo "Please set a commit message. Example gacp 'my message'"
        return 1
    fi

    git add .
    git commit -m "$1"
    git push
}
alias cp="cp -i"; # Confirm before overwriting something
alias rvt="nix-shell -p ffmpeg --command \"bash <(curl -s https://raw.githubusercontent.com/Yeshey/RecursiveVideoTranscoder/main/RecursiveVideoTranscoder.sh)\"";
# alias win10-vm="sh <(curl -s https://raw.githubusercontent.com/Yeshey/nixos-nvidia-vgpu_nixOS/master/run-vm.sh)";
