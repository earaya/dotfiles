#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--dry-run] [--skip-brew] [--skip-macos]

Installs Homebrew packages, links files under home/ into $HOME, and applies
tracked macOS preferences. Existing non-symlink files are preserved with a
timestamped backup before linking.
EOF
}

dry_run=false
skip_brew=false
skip_macos=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    --skip-brew) skip_brew=true ;;
    --skip-macos) skip_macos=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  printf '%s\n' "This setup currently supports macOS only." >&2
  exit 1
fi

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
home_dir="$repo_dir/home"
backup_root="$HOME/.dotfiles-backup"
backup_stamp=$(date '+%Y%m%d%H%M%S')

run() {
  if [ "$dry_run" = true ]; then
    printf 'Would run:'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if [ "$skip_brew" = false ]; then
  if ! command -v brew >/dev/null 2>&1; then
    if [ "$dry_run" = true ]; then
      printf '%s\n' "Would install Homebrew from https://brew.sh"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
  fi

  if command -v brew >/dev/null 2>&1; then
    run brew bundle install --file "$repo_dir/Brewfile"
  elif [ "$dry_run" = false ]; then
    printf '%s\n' "Homebrew installation did not provide a usable brew command." >&2
    exit 1
  fi
fi

if command -v brew >/dev/null 2>&1; then
  for java_version in 21 25; do
    java_home="$(brew --prefix "openjdk@$java_version")/libexec/openjdk.jdk/Contents/Home"
    if [ "$dry_run" = true ]; then
      printf 'Would add JDK to jEnv: %s\n' "$java_home"
    elif command -v jenv >/dev/null 2>&1; then
      JENV_SKIP=true jenv add "$java_home" >/dev/null
    fi
  done

  if [ "$dry_run" = true ]; then
    printf '%s\n' "Would set jEnv global Java version to 21"
  elif command -v jenv >/dev/null 2>&1; then
    jenv global 21
    jenv enable-plugin export >/dev/null 2>&1 || true
  fi
fi

find "$home_dir" -type f ! -name '.DS_Store' ! -name '.zcompdump*' ! -name 'id_*' | while IFS= read -r source; do
  relative=${source#"$home_dir"/}
  target="$HOME/$relative"
  target_dir=$(dirname -- "$target")

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'Already linked: %s\n' "$target"
    continue
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$backup_root/$backup_stamp/$relative"
    if [ "$dry_run" = true ]; then
      printf 'Would back up: %s -> %s\n' "$target" "$backup"
    else
      mkdir -p -- "$(dirname -- "$backup")"
      mv -- "$target" "$backup"
    fi
  fi

  if [ "$dry_run" = true ]; then
    printf 'Would link: %s -> %s\n' "$target" "$source"
  else
    mkdir -p -- "$target_dir"
    ln -s -- "$source" "$target"
    printf 'Linked: %s -> %s\n' "$target" "$source"
  fi
done

# Ghostty reads its macOS-specific config after the XDG config. Preserve and
# remove legacy files so they cannot silently override the tracked XDG file.
for legacy_name in config.ghostty config; do
  legacy="$HOME/Library/Application Support/com.mitchellh.ghostty/$legacy_name"
  if [ -e "$legacy" ] || [ -L "$legacy" ]; then
    backup="$backup_root/$backup_stamp/Library/Application Support/com.mitchellh.ghostty/$legacy_name"
    if [ "$dry_run" = true ]; then
      printf 'Would back up legacy Ghostty config: %s -> %s\n' "$legacy" "$backup"
    else
      mkdir -p -- "$(dirname -- "$backup")"
      mv -- "$legacy" "$backup"
    fi
  fi
done

if [ "$skip_macos" = false ]; then
  if [ "$dry_run" = true ]; then
    printf 'Would run: %s\n' "$repo_dir/macos/rectangle.sh"
  else
    "$repo_dir/macos/rectangle.sh"
  fi
fi

missing_ssh_keys=false
for key_name in id_ed25519_github id_ed25519_github_domo; do
  if [ ! -f "$HOME/.ssh/$key_name" ]; then
    printf 'Missing SSH key: %s\n' "$HOME/.ssh/$key_name"
    missing_ssh_keys=true
  fi
done

if [ "$missing_ssh_keys" = true ]; then
  printf 'Run %s/setup-ssh.sh to create the missing per-machine GitHub keys.\n' "$repo_dir"
fi
printf '%s\n' "Setup complete. Open a new shell to load the linked configuration."
