{
  config,
  lib,
  pkgs,
  settings,
  ...
}:
{
  home.username = settings.username;
  home.homeDirectory = "/home/${settings.username}";
  home.stateVersion = settings.homeStateVersion;
  home.sessionVariables.EDITOR = "vim";
  home.packages = [ pkgs.peco ];
  programs.git = {
    enable = true;
    settings.user =
      lib.optionalAttrs (settings.gitName != "") { name = settings.gitName; }
      // lib.optionalAttrs (settings.gitEmail != "") { email = settings.gitEmail; };
  };
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    defaultKeymap = "emacs";
    history = {
      size = 150000;
      save = 150000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      share = true;
    };
    initContent = ''
      [[ -t 0 ]] && stty -ixon

      function peco-history-selection() {
        local selected
        # fc -r gives reverse chronological order, rather than sorting commands alphabetically.
        selected=$(fc -rl 1 | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*[0-9]*[[:space:]]*//' |
          ${pkgs.gawk}/bin/awk '!seen[$0]++' | ${pkgs.peco}/bin/peco) || return 0
        if [[ -n "$selected" ]]; then
          BUFFER=$selected
          CURSOR=$#BUFFER
        fi
        zle reset-prompt
      }
      zle -N peco-history-selection
      bindkey '^R' peco-history-selection

      # Native Zsh Git completion and vcs_info; no downloads from Git's master branch.
      autoload -Uz vcs_info add-zsh-hook
      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:git:*' check-for-changes true
      zstyle ':vcs_info:git:*' stagedstr '+'
      zstyle ':vcs_info:git:*' unstagedstr '*'
      zstyle ':vcs_info:git:*' formats '--%b%c%u'
      zstyle ':vcs_info:git:*' actionformats '--%b|%a%c%u'
      add-zsh-hook precmd vcs_info
      setopt PROMPT_SUBST
      PROMPT='%F{cyan}%~%f %F{red}''${vcs_info_msg_0_}%f %F{blue}%D{%Y-%m-%d %H:%M:%S}%f
       $ '
    '';
  };
}
