{ ... }:
{
  home.sessionPath = [ "$HOME/scripts" ];
  home.sessionVariables.EDITOR = "vim";

  programs.bash = {
    enable = true;
    historySize = 10000;
    historyFileSize = 100000;
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];
    initExtra = ''
      if [[ -r "$HOME/.env" ]]; then
        source "$HOME/.env"
      fi

      if [[ "$TERM" != "dumb" || -n "$INSIDE_EMACS" ]]; then
        PROMPT_COLOR="1;31m"
        ((UID)) && PROMPT_COLOR="1;32m"
        if [[ -n "$INSIDE_EMACS" || "$TERM" == "eterm" || "$TERM" == "eterm-color" ]]; then
          PS1="\[\033[$PROMPT_COLOR\]\u@\h:\w>\[\033[0m\] "
        else
          PS1="\[\033[$PROMPT_COLOR\]\[\e]0;\u@\h>\w\a\]\u@\h:\w>\[\033[0m\] "
        fi
        if [[ "$TERM" == "xterm" ]]; then
          PS1="\[\033]2;\h:\u:\w\007> "
        fi
      fi
    '';
  };
}
