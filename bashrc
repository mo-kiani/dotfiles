# The stuff that came by default was moved to .bashrc_default to reduce clutter
if [ -f ~/.bashrc_default ]; then
  source ~/.bashrc_default
fi

# Set vi mode
## Also, this is needed for the TAB key binding in ~/.inputrc to work for some weird reason if you set vi mode there
set -o vi

# This is simply needed to make GPG work properly
if command -v tty &> /dev/null; then
  export GPG_TTY=$(tty)
else
  echo "command 'tty' is unavailable and so \$GPG_TTY could not be set properly to ensure that GPG functions properly"
fi

# Run ssh-agent
if command -v ssh-agent &> /dev/null; then
  eval `ssh-agent` > /dev/null 2>&1
else
  echo "command 'ssh-agent' is unavailable, could not start ssh-agent"
fi

# When in an interactive SSH non-tmux terminal
if [[ $- =~ i ]] && [[ -n "$SSH_TTY" ]] && [[ -z "$TMUX" ]]; then
  # attempt to use a tmux session named after the user
  if ! command -v tmux &> /dev/null; then
    echo "Attempted to automatically open a tmux session for this interactive SSH terminal as $USER but tmux is not available on this host."
  else
    tmux attach-session -t $USER || tmux new-session -s $USER
    # and exit the SSH session/shell if the tmux session was exited (not detached)
    # This gives the user the option to detach for debugging issues outside of tmux over
    # SSH or adding more tmux sessions, etc., but still benefit from the convenience of
    # closing the SSH connection automatically when the user is done.
    if ! tmux has-session -t $USER &> /dev/null; then
      exit
    fi
  fi
fi

# Set vim as default editor
export VISUAL=vim
export EDITOR=vim

# Function for setting the console title
settitle () {
  export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  echo -ne '\033]0;'"$1"'\a'
  export CONSOLE_TITLE="$1"
}

# Convenient way to print out glyphs from UTF codepoint number(s)
# particularly useful for configuring oh-my-posh
codepoints_to_glyphs () {
  for codepoint in "$@"; do
    printf "$(printf '\\U%08x' 0x$codepoint)"
  done
  printf "\n"
}

# Add general purpose folder to PATH
if [ -d ~/.path ]; then
  export PATH=$PATH:~/.path
fi

# Activate oh-my-posh with default theme
if command -v oh-my-posh &> /dev/null; then
  if [ -f ~/.oh-my-posh/themes/default.omp.json ]; then
    eval "$(oh-my-posh init bash --config ~/.oh-my-posh/themes/default.omp.json)"
  else
    eval "$(oh-my-posh init bash)"
  fi
else
  echo "oh-my-posh is not installed. Use the following command to install it if you wish: curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.oh-my-posh"
fi

# Add timestamps to history
export HISTTIMEFORMAT="  %Y/%m/%d %H:%M:%S    "

# Handy Aliases
alias django="python manage.py"  # Run Django management commands easily

# Activate features that require a nerd-font by creating a file at ~/.nerdfont_on.
# The environment variable that is set can be checked by configurations of other
# software such as vim and tmux to make appropriate use of nerd-fonts when available.
# This code only runs when outside of an ssh session because during an ssh connection
# whether a nerd-font is available is up to the client-side rather than the server-side.
# It's a good idea to use SendEnv in the ssh config of your clients and AcceptEnv in the
# ssh config of your servers to make this automatically work in ssh connections.
if [[ -z "$SSH_TTY" ]] && [ -f ~/.nerdfont_on ]; then
  export NERD_FONT=on
fi

# Set variable indicating whether bash is running in WSL
if grep -qi -- '-WSL' /proc/sys/kernel/osrelease || test -f /proc/sys/fs/binfmt_misc/WSLInterop; then
  export IM_IN_WSL=true
fi

# Set variable indicating what terminal bash is running in
export MY_TERM="unknown"
if [[ -n "$WT_SESSION" ]]; then
  export MY_TERM="wt"
elif [ $TERM_PROGRAM = 'vscode' ]; then
  export MY_TERM="vscode"
fi

# Provide a hook to add more bashrc configurations on a per-system basis while
# still allowing this bashrc to be used on all systems
if [ -f ~/.bashrc_extras ]; then
  source ~/.bashrc_extras
fi
