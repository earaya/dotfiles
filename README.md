# Dotfiles

Declarative macOS setup for Homebrew packages, Zsh, Starship, Ghostty, Rectangle, and Visual Studio Code.

## Apply the setup

Preview every change first:

```sh
./bootstrap.sh --dry-run
```

Then apply it:

```sh
./bootstrap.sh
```

The bootstrap script installs packages from `Brewfile`, creates symlinks from
`home/` into `$HOME`, and applies the scripts under `macos/`. Existing files are
moved to `~/.dotfiles-backup/<timestamp>/` before a link is created.

Use `--skip-brew` or `--skip-macos` to omit either system-level step.

On a new machine, bootstrap reports any missing GitHub SSH keys. Create them
interactively after applying the tracked SSH configuration:

```sh
./setup-ssh.sh
```

The SSH setup script creates only missing keys, requires passphrases, stores
them in the macOS Keychain, and prints the public values to add to GitHub.
Existing keys are never replaced. Preview its actions with
`./setup-ssh.sh --dry-run`.

## Source of truth

Tracked configuration files are symlinked into place, so edits from either path
stay synchronized immediately:

- `home/.zshrc` maps to `~/.zshrc`
- `home/.zprofile` maps to `~/.zprofile`
- `home/.config/starship.toml` maps to `~/.config/starship.toml`
- `home/.config/ghostty/config.ghostty` maps to `~/.config/ghostty/config.ghostty`
- `home/.ssh/config` maps to `~/.ssh/config`

Homebrew and macOS preferences cannot be symlinked. Their tracked declarations
are the source of truth and must be changed before or alongside the live state.

## Maintenance workflow

### Add or remove a Homebrew tool

Edit the manifest and reconcile the machine:

```sh
brew bundle add <formula> --file ./Brewfile
brew bundle add <app> --cask --file ./Brewfile
brew bundle remove <name> --file ./Brewfile
brew bundle install --file ./Brewfile
brew bundle check --file ./Brewfile
```

`brew bundle install` installs missing entries but does not remove undeclared
software. Review before using `brew bundle cleanup --file ./Brewfile`, because it
uninstalls packages not present in the manifest.

### Change a tracked configuration

Edit the live path or its matching path under `home/`. They are the same file
after bootstrap. Reload the application when needed; for example, open a new Zsh
session or reload Ghostty with `Command-Shift-,`.

To adopt another text configuration, place it under `home/` using its path
relative to `$HOME`, then rerun `./bootstrap.sh`. Example:

```text
home/.gitconfig -> ~/.gitconfig
```

### Change a macOS or application preference

Update the appropriate idempotent script under `macos/`, run that script, and
verify the application behavior. Keep only deliberate settings; do not commit a
complete preferences plist containing generated state.

### Default editor

Visual Studio Code is installed from `Brewfile`. Use its `code` command to
open files or directories from the terminal without changing macOS file
associations:

```sh
code ~/.zshrc
code .
```

The shell also exports `EDITOR='code --wait'` and `VISUAL` for terminal
programs that invoke an editor and need to wait until editing is complete.

### GitHub SSH identities

Private keys are unique to each machine and are not tracked. The SSH setup
script creates these paths expected by `home/.ssh/config`:

```text
~/.ssh/id_ed25519_github       personal account (earaya)
~/.ssh/id_ed25519_github_domo  Domo EMU account (esteban-araya_domo)
```

Enterprise SSH is the default for normal `github.com` remotes. Personal
repositories use the `github-personal` alias:

```text
git@github.com:OWNER/REPOSITORY.git
git@github-personal:earaya/REPOSITORY.git
```

After adding the printed public keys to their accounts, verify both identities:

```sh
ssh -T git@github.com
ssh -T git@github-personal
```

GitHub prints a successful-authentication message and exits with status 1
because it does not provide shell access.

### Machine-specific or secret settings

Put private Zsh settings in `~/.zshrc.local`. The tracked `.zshrc` loads it when
present, and `*.local` is ignored. Never store API keys, private SSH keys,
1Password data, history, caches, or generated application state here.
