# ln -sfn silently drops the symlink *inside* an existing real (non-symlink)
# directory instead of replacing it, so directory targets need the real
# directory removed first.
link_dir() {
  if [[ -d $2 && ! -L $2 ]]; then
    rm -rf "$2"
  fi
  ln -sfn "$1" "$2"
}
