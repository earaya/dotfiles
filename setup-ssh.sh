#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: ./setup-ssh.sh [--dry-run]

Creates missing, passphrase-protected Ed25519 keys for the personal and Domo
GitHub accounts, stores their passphrases in the macOS Keychain, and prints the
public keys to add to GitHub. Existing keys are never overwritten.
EOF
}

dry_run=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  printf '%s\n' "This setup currently supports macOS only." >&2
  exit 1
fi

umask 077
ssh_dir="$HOME/.ssh"
machine_name=$(hostname -s 2>/dev/null || hostname)

if [ "$dry_run" = false ]; then
  mkdir -p -- "$ssh_dir"
  chmod 700 -- "$ssh_dir"
fi

setup_key() {
  label=$1
  private_key=$2
  comment=$3
  account_note=$4
  public_key="$private_key.pub"

  if [ -e "$private_key" ] || [ -L "$private_key" ]; then
    if [ ! -f "$private_key" ]; then
      printf 'Refusing non-regular private key path: %s\n' "$private_key" >&2
      exit 1
    fi
    if [ ! -f "$public_key" ]; then
      printf 'Private key exists but public key is missing: %s\n' "$public_key" >&2
      exit 1
    fi
    printf 'Existing %s key: %s\n' "$label" "$private_key"
  else
    if [ -e "$public_key" ] || [ -L "$public_key" ]; then
      printf 'Public key exists without its private key: %s\n' "$public_key" >&2
      exit 1
    fi

    if [ "$dry_run" = true ]; then
      printf 'Would create passphrase-protected %s key: %s\n' "$label" "$private_key"
      printf 'Would add %s to the macOS Keychain and SSH agent.\n' "$private_key"
      return
    fi

    printf 'Creating %s key. Enter a non-empty passphrase when prompted.\n' "$label"
    ssh-keygen -t ed25519 -a 100 -C "$comment" -f "$private_key"

    # Empty passphrases are not accepted for generated keys.
    if ssh-keygen -y -P '' -f "$private_key" >/dev/null 2>&1; then
      rm -f -- "$private_key" "$public_key"
      printf '%s\n' "A passphrase is required; the unprotected key was removed." >&2
      exit 1
    fi

    chmod 600 -- "$private_key"
    chmod 644 -- "$public_key"
  fi

  if [ "$dry_run" = true ]; then
    printf 'Would add %s to the macOS Keychain and SSH agent.\n' "$private_key"
    return
  fi

  ssh-add --apple-use-keychain "$private_key"

  printf '\n%s GitHub account: %s\n' "$label" "$account_note"
  printf 'Key title: %s - %s\n' "$label" "$machine_name"
  printf 'Key value:\n'
  cat -- "$public_key"
  printf '\nAdd it at: https://github.com/settings/ssh/new\n\n'
}

setup_key \
  "Personal" \
  "$ssh_dir/id_ed25519_github" \
  "github:personal:$machine_name" \
  "earaya"

setup_key \
  "Domo EMU" \
  "$ssh_dir/id_ed25519_github_domo" \
  "github:domo-emu:$machine_name" \
  "esteban-araya_domo"

printf '%s\n' "Private keys remain local under $ssh_dir and are never stored in this repository."
