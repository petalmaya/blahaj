# Wires up the Homebrew CLI tools from the Brewfile (installed by
# blahaj-brew-bundle.service on first boot) into interactive bash.
# Fedora's default bash sources /etc/skel/.bashrc.d/*.sh|*.bashrc
# automatically, so this lands for every new user without touching
# their actual .bashrc.

if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v fzf      >/dev/null 2>&1 && eval "$(fzf --bash)"

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first'
    alias la='eza -la --group-directories-first'
    alias tree='eza --tree'
fi

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v fd  >/dev/null 2>&1 && alias find='fd'
