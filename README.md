# dotfiles

Personal configs managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Config Location | Description |
|---------|----------------|-------------|
| `nvim` | `~/.config/nvim/` | LazyVim + Kanagawa Dragon |
| `tmux` | `~/.config/tmux/` | Ctrl+Space prefix, resurrect, fzf |
| `zsh` | `~/.zshrc`, `~/.p10k.zsh` | Oh My Zsh + Powerlevel10k |
| `git` | `~/.gitconfig` | Delta diffs, histogram, aliases |
| `ghostty` | `~/.config/ghostty/` | Kanagawa Dragon terminal |
| `zed` | `~/.config/zed/` | Vim mode, Kanagawa Dragon |
| `fastfetch` | `~/.config/fastfetch/` | System info display |
| `btop` | `~/.config/btop/` | System monitor |

## Usage

```bash
# Clone
git clone git@github.com:Quitetall/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install all packages
stow nvim tmux zsh git ghostty zed fastfetch btop

# Install one package
stow nvim

# Uninstall one package
stow -D nvim

# Add a new package
mkdir -p newpkg/.config/newpkg
cp ~/.config/newpkg/config newpkg/.config/newpkg/
stow newpkg
```

## Theme

Kanagawa Dragon everywhere. Key colors:
- Background: `#0d0c0c`
- Foreground: `#c5c9c5`
- Accent: `#7fb4ca` (crystalBlue)
- Red: `#c4746e` (samuraiRed)
- Green: `#8a9a7b` (springGreen)
- Violet: `#a292a3` (oniViolet)
- Yellow: `#c4b28a` (carpYellow)
