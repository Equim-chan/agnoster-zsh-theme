# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
  PRIMARY_FG=233
fi

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
LIGHTNING="\u26a1"
GEAR="\uf423"

# Command stat
setopt PROMPT_SUBST
[[ $cmdcount -ge 1 ]] || cmdcount=1
preexec() { ((cmdcount++)) }

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: no more user@hostname, instead, platform info and cpu metrics
prompt_context() {
  # /proc/loadavg 似乎不能直接访问(结果不会刷新)，要通过 uptime(1) 才行，很诡异
  # 另外，CPU 查询的速度确实较慢，这里提供了一个查询内存的 alternative
  # 如果还想要更快的速度，可以设置 $FAST
  # $FAST 为 1 时为快速模式，关闭 Metrics 信息查询。
  # $FAST 为 2 时为暴走模式，关闭 Metrics 和 git 信息查询。
  if [ ! "$FAST" ]; then
    if [[ "$METRICS" == "MEM" ]]; then
      local val=$(free | grep Mem | awk '{printf("%.2f%%%%", $3/$2 * 100.0)}')
    elif [[ "$METRICS" == "CPU_AS_ONE_CORE" ]]; then
      local val=$(loadavg_as_one_core)
    else
      local val=$(loadavg)
    fi
    prompt_segment 169 black " \ue70f $cmdcount \ue0b1 $val "
  else
    prompt_segment 169 black " \ue70f $cmdcount "
    if [[ "$FAST" == "1" ]]; then
      prompt_segment red black " \uf490 " # fire
    else
      prompt_segment red black " \uf0e7 " # lightening
    fi
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -n " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black " %$(( $COLUMNS - 45 ))<...<%~%<< "
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{169}%}$GEAR"

  if [[ -n "$symbols" ]]; then
    print -n "%{%F{$PRIMARY_FG}%}\ue0b2%{%f%}"
    prompt_segment $PRIMARY_FG default " $symbols "
  else
    print -n "%{%F{169}%}\ue0b2%{%f%}"
  fi
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    color=cyan
    prompt_segment $color $PRIMARY_FG
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

# Work with prompt_newline
prompt_begin() {
  if [ $RETVAL -eq 0 ]; then
    print -n "%{%F{169}%}╭%{%f%}"
  else
    print -n "%{%F{red}%}╭%{%f%}"
  fi
}

# Newline
prompt_newline() {
  if [ $RETVAL -eq 0 ]; then
    print -n "%{%F{169}%}\n╰\uf101%{%f%}" # 
  else
    print -n "%{%F{red}%}\n╰\ue009%{%f%}" # 
  fi
}

# Status on the right
prompt_right() {
  RETVAL=$?

  # Time
  local hour=$(date +"%H")
  # [6, 18) is day
  if [ $hour -ge 6 -a $hour -lt 18 ]; then
    local time_sym="\uf185"
    local time_color_bg="017" # dark blue
  else
    local time_sym="\uf186"
    local time_color_bg="088" # dark red
  fi

  if [ $RETVAL -ne 0 ]; then
    print -n "%{%F{$PRIMARY_FG}%}\ue0b2"
    print -n "%{%F{red}%K{$PRIMARY_FG}%} \uf00d $RETVAL %{%f%k%}" # 
    print -n "%{%F{$PRIMARY_FG}%K{$time_color_bg}%}\ue0b0"
  else
    print -n "%{%F{$time_color_bg}%}\ue0b2"
  fi

  print -n "%{%F{white}%K{$time_color_bg}%B%} $time_sym $(date +"%H:%M") %{%b%f%k%}"
  print -n "%{%F{$time_color_bg}%}\ue0b0"
}

## Main prompt
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'

  prompt_begin
  prompt_status
  prompt_context
  prompt_virtualenv
  prompt_dir
  if [[ "$FAST" != "2" ]]; then
    prompt_git
  fi
  prompt_end
  prompt_newline
}

prompt_agnoster_precmd() {
  if [[ "$FAST" != "2" ]]; then
    vcs_info
  fi
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main) '
  RPROMPT='$(prompt_right)'
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"

# 快速模式切换
f() {
  if [ ! "$FAST" ]; then
    export FAST=1
  elif [[ "$FAST" == "1" ]]; then
    unset FAST
  else
    git config --global --remove-section oh-my-zsh
    export FAST=1
  fi
}

# 暴走模式切换
fff() {
  if [[ ! "$FAST" || "$FAST" == "1" ]]; then
    git config --global oh-my-zsh.hide-status 1
    git config --global oh-my-zsh.hide-dirty 1
    export FAST=2
  else
    git config --global --remove-section oh-my-zsh
    unset FAST
  fi
}
