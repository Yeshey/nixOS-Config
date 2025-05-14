# clean https://nixos.wiki/wiki/Cleaning_the_nix_store
# also need to run as nix-collect-garbage -d non root: https://github.com/NixOS/nix/issues/8508
# alias clean="echo \"This will clean all generations, and optimise the store\" ; sudo sh -c 'nix-collect-garbage -d ; nix-store --optimise ; nix-store --gc ; echo \"Displaying stray roots:\" ; nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/current-system|/run/booted-system|/proc|{memory|{censored)\" ; flatpak uninstall --unused -y' ; nix-collect-garbage -d ; echo \"You should do a nixos-rebuild boot and a reboot to clean the boot generations now.\"";

# cleangit() {
#     find . -type d \( -name '.stversions' -prune \) -o \( -name '.git' -type d -execdir sh -c 'echo "Cleaning repository in $(pwd)"; git clean -fdx' \; \)
# }

# cleansyncthing(){
#     echo "Deleting sync conflict files in: $(pwd)"
#     find . -mount -mindepth 1 -type f \
#         -not \( -path "*/.Trash-1000/*" -or -path "*.local/share/Trash/*" \) \
#         -name "*.sync-conflict-*" -ls -delete
# }

alias df="df -h";                                   # Human-readable sizes
alias free="free -m";                               # Show sizes in MB
alias zshreload="clear && zsh";
alias zshconfig="nano ~/.zshrc";

#re-kde() { 
#    nix-shell -p killall --command "kquitapp5 plasmashell || killall plasmashell ; kstart5 plasmashell"
#};
alias re-kde="nix-shell -p killall --command \"kquitapp5 plasmashell || killall plasmashell ; kstart5 plasmashell\""; # Restart gui in KDE
alias mount="mount|column -t";                      # Pretty mount
alias temperature="watch \"nix-shell -p lm_sensors --command sensors | grep temp1 | awk '{print $2}' | sed 's/+//'\"";
# alias ping="ping -c 5";                             # Control output of ping
# alias fastping="ping -c 100 -s 1";
# alias ports="netstat -tulanp";                      # Show Open ports
alias grep="grep --color=auto";
# alias egrep="egrep --color=auto";
# alias fgrep="fgrep --color=auto";
# alias diff="colordiff";
# alias dir="dir --color=auto";
# alias vdir="vdir --color=auto";
# alias week="
#     now=$(date '+%V %B %Y');
#     echo \"Week Date:\" $now
# ";
alias myip="  
    echo \"Your external IP address is:\"
    curl -w '\n' https://ipinfo.io/ip
";
# alias chtp=" curl cht.sh/python/\"$1\" ";           # alias to use cht.sh for python help # TODO remove these
# alias chtc=" curl cht.sh/c/\"$1\" ";                # alias to use cht.sh for c help
# alias chtsharp=" curl cht.sh/csharp/\"$1\" ";           # alias to use cht.sh for c# help
# alias cht=" curl cht.sh/\"$1\" ";                   # alias to use cht.sh in general

space() {
    local target_dir=${1:-.}
    watch "df -h $target_dir && df $target_dir"
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
alias gl='git pull'
alias ga='git add'
alias gp='git push'
alias cp="cp -i";                                   # Confirm before overwriting something
alias rvt="nix-shell -p ffmpeg --command \"bash <(curl -s https://raw.githubusercontent.com/Yeshey/RecursiveVideoTranscoder/main/RecursiveVideoTranscoder.sh)\"";
alias win10-vm="sh <(curl -s https://raw.githubusercontent.com/Yeshey/nixos-nvidia-vgpu/535.129/guides/run-vm.sh)";
