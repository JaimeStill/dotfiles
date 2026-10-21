# PATH for every kind of session on DGX OS: sourced from ~/.profile (GNOME session, so desktop
# shortcuts and git's credential helper find mise tools) and from the top of ~/.bashrc, ahead of
# Ubuntu's interactive-only guard (so `ssh host cmd` and `herdr --remote` find them too).
case ":$PATH:" in
  *":$HOME/.local/share/mise/shims:"*) ;;
  *) export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH" ;;
esac
