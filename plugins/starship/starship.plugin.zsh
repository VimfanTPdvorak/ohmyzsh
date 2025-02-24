if (( $+commands[starship] )); then
  # ignore oh-my-zsh theme
  unset ZSH_THEME

  # If starship.toml not presented yet, then useng the starship preset
  # gruvbox-rainbow.
  if [ ! -f ~/.config/starship.toml ];then
      mkdir -p ~/.config
      cp $ZSH/templates/starship.default.toml ~/.config/starship.toml
  fi

  eval "$(starship init zsh)"
else
  echo '[oh-my-zsh] starship not found, please install it from https://starship.rs'
fi
