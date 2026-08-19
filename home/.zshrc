# ---- Completion -------------------------------------------------------------

autoload -Uz compinit
zmodload -i zsh/complist
compinit

# Tab completion: case-insensitive matching and a navigable selection menu.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}no matches found%f'

# ---- History ----------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Share history across open Ghostty tabs/windows and write it incrementally.
setopt append_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_find_no_dups

# ---- Fish-like history search ------------------------------------------------

source "$(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

# Type any fragment, then use Up/Down to find matching history entries.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# ---- Inline suggestions ------------------------------------------------------

source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Muted Solarized-style suggestion color. Press Right Arrow or End to accept.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ---- Aliases ----------------------------------------------------------------

[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

# Use VS Code for commands that respect standard editor environment variables.
if command -v code >/dev/null 2>&1; then
  export EDITOR='code --wait'
  export VISUAL="$EDITOR"
fi

# Keep machine- or work-specific settings out of Git.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ---- Prompt -----------------------------------------------------------------
if [[ "$TERM" != dumb ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ---- Syntax highlighting (must be last) -------------------------------------

syntax_highlighting="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [[ -r "$syntax_highlighting" ]]; then
  source "$syntax_highlighting"
  # Bright, bold colors remain visible against Ghostty's dark background.
  ZSH_HIGHLIGHT_STYLES[arg0]='fg=10,bold'
  ZSH_HIGHLIGHT_STYLES[command]='fg=10,bold'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=10,bold,underline'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9,bold'
fi
unset syntax_highlighting
