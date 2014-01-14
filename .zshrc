###############################################################################
# This file is sourced only for interactive shells. It
# should contain commands to set up aliases, functions,
# options, key bindings, etc.
#
# Global Order: zshenv, zprofile, zshrc, zlogin
################################################################################

ZSHDIR=$HOME/.zsh

# source conf files.
for file in $ZSHDIR/rc/base/*; do
    source $file
done
# done

# zmv is a zsh massive renaming tool
# Usage:
#   zmv [OPTIONS] oldpattern newpattern
# where oldpattern contains parenthesis surrounding patterns which will
# be replaced in turn by $1, $2, ... in newpattern.  For example,
#   zmv '(*).lis' '$1.txt'
# renames 'foo.lis' to 'foo.txt', 'my.old.stuff.lis' to 'my.old.stuff.txt',
# and so on.  Something simpler (for basic commands) is the -W option:
#   zmv -W '*.lis' '*.txt'
# This does the same thing as the first command, but with automatic conversion
# of the wildcards into the appropriate syntax.  If you combine this with
# noglob, you don't even need to quote the arguments.  For example,
#   alias mmv='noglob zmv -W'
#   mmv *.c.orig orig/*.c
zrcautoload zmv

# I'm not pretty sure of what it does. :D
zrcautoload history-search-end

#m# k ESC-h Call \kbd{run-help} for the 1st word on the command line
alias run-help >&/dev/null && unalias run-help
for rh in run-help{,-git,-svk,-svn}; do
    zrcautoload $rh
done; unset rh

# loads completion system
if zrcautoload compinit ; then
    compinit || print 'Notice: no compinit available :('
else
    # creates fake functions
    print 'Notice: no compinit available :('
    function zstyle { }
    function compdef { }
fi

# zed - /usr/share/zsh/functions/Misc/zed
#
# No other shell could do this.
# Edit small files with the command line editor.
# Use ^X^W to save, ^C to abort.
# Option -f: edit shell functions.  (Also if called as fned.)
zrcautoload zed

# Loads .so modules in /usr/lib/i386-linux-gnu/zsh/${ZSHVERSION}/zsh/
for mod in complist deltochar mathfunc ; do
    zmodload -i zsh/${mod} 2>/dev/null || print "Notice: no ${mod} available :("
done

# autoload zsh modules when they are referenced
# uses bidimensionnal array to give option to zmodload
tmpargs=(
    a   stat
    a   zpty
    ap  mapfile
)

while (( ${#tmpargs} > 0 )) ; do
    zmodload -${tmpargs[1]} zsh/${tmpargs[2]} ${tmpargs[2]}
    shift 2 tmpargs
done
unset tmpargs

# dirstack handling
# I wasn't able to find a good .zsh/rc/* file for this
DIRSTACKSIZE=${DIRSTACKSIZE:-20}
DIRSTACKFILE=${DIRSTACKFILE:-${HOME}/.zdirs}

if [[ -f ${DIRSTACKFILE} ]] && [[ ${#dirstack[*]} -eq 0 ]] ; then
    dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
    # "cd -" won't work after login by just setting $OLDPWD, so
    [[ -d $dirstack[0] ]] && cd $dirstack[0] && cd $OLDPWD
fi

chpwd() {
    local -ax my_stack
    my_stack=( ${PWD} ${dirstack} )
    builtin print -l ${(u)my_stack} >! ${DIRSTACKFILE}
}

# In order to set prompt, and because we love confort
# These files are not mandatory, but removing them
# would break the PS1 prompt.
for file in $ZSHDIR/rc/extra/*; do
    source $file
done

# {{{ set prompt
if zrcautoload promptinit && promptinit 2>/dev/null ; then
    promptinit # people should be able to use their favourite prompt
else
    print 'Notice: no promptinit available :('
fi

setopt prompt_subst

# make sure to use right prompt only when not running a command
setopt transient_rprompt


function ESC_print () {
    info_print $'\ek' $'\e\\' "$@"
}
function set_title () {
    info_print  $'\e]0;' $'\a' "$@"
}

function info_print () {
    local esc_begin esc_end
    esc_begin="$1"
    esc_end="$2"
    shift 2
    printf '%s' ${esc_begin}
    for item in "$@" ; do
        printf '%s ' "$item"
    done
    printf '%s' "${esc_end}"
}

#+--------------------------------------+
#|            PROMPT                    |
#+--------------------------------------+

# set colors for use in prompts {{{
if zrcautoload colors 2> /dev/null && colors 2>/dev/null ; then
    BLUE="${fg[blue]}"
    RED="${fg_bold[red]}"
    GREEN="${fg[green]}"
    CYAN="${fg[cyan]}"
    MAGENTA="${fg[magenta]}"
    YELLOW="${fg[yellow]}"
    WHITE="${fg[white]}"
    NO_COLOUR="${reset_color}"
else
    BLUE=$'\e[1;34m'
    RED=$'\e[1;31m'
    GREEN=$'\e[1;32m'
    CYAN=$'\e[1;36m'
    WHITE=$'\e[1;37m'
    MAGENTA=$'\e[1;35m'
    YELLOW=$'\e[1;33m'
    NO_COLOUR=$'\e[0m'
fi

# Change vcs_info formats for the grml prompt. The 2nd format sets up
# $vcs_info_msg_1_ to contain "zsh: repo-name" used to set our screen title.
# TODO: The included vcs_info() version still uses $VCS_INFO_message_N_.
#       That needs to be the use of $VCS_INFO_message_N_ needs to be changed
#       to $vcs_info_msg_N_ as soon as we use the included version.
if [[ "$TERM" == dumb ]] ; then
    zstyle ':vcs_info:*' actionformats "(%s)-[%r/%b|%a]" "(%s)-[%r/%b|%a]"
    zstyle ':vcs_info:*' formats       "(%s)-[%r/%b]"    "(%s)-[%r/%b]"
else
    # these are the same, just with a lot of colours:
    zstyle ':vcs_info:*' actionformats "%F{magenta}(%F{no}%s%F{magenta})%F{yellow}-%F{magenta}[%F{green}%r%F{yellow}/%F{green}%b%F{yellow}|%F{red}%a%F{magenta}]%F{no}" \
                                       "(%s)-[%r/%b|%a]" 
    zstyle ':vcs_info:*' formats       "%F{magenta}(%F{no}%s%F{magenta})%F{yellow}-%F{magenta}[%F{green}%r%F{yellow}/%F{green}%b%F{magenta}]%F{no}" \
                                       "(%s)-[%r/%b]"
    zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat "%b{red}:{yellow}%r"
fi

# datecolor() {
#     local H date coul
#     H=$(date +"%H")
#     date=$(date +"%H:%M:%S")
# 
#     if [ $H -gt 8 -a $H -lt 22 ]; then
#         coul=${CYAN}
#     else
#         coul=${BLUE}
#     fi
# 
#     echo "${coul}${date}${DC}"
# }

# Built from /usr/share/zsh/functions/Prompts/prompt_adam2…
EXITCODE="%(?..[%?]%1v)"

# Set of chars used in prompt
prompt_tlc='.'
prompt_mlc='|'
prompt_blc='\`'
prompt_hyphen='-'
prompt_color1='cyan'    # hyphens
prompt_color2='green'   # current directory
prompt_color3='cyan'   # user@host
prompt_color4='red'   # user input
prompt_color5='yellow'

# see man zshmisc for explanation about %B, %F, %b…
prompt_tbox="%B%F{$prompt_color1}${prompt_tlc}%b%F{$prompt_color1}${prompt_hyphen}"
prompt_bbox="%B%F{$prompt_color1}${prompt_blc}${prompt_hyphen}%b%F{$prompt_color1}"

# This is a cute hack.  Well I like it, anyway.
prompt_bbox_to_mbox=$'%{\e[A\r'"%}%B%F{$prompt_color1}${prompt_mlc}%b%F{$prompt_color1}${prompt_hyphen}%{"$'\e[B%}'

# left and right parenthesis
prompt_l_paren="%B%F{black}("
prompt_r_paren="%B%F{black})"

# User : %n, host : %M
prompt_user_host="%b%F{$prompt_color3}%n%B%F{$prompt_color3}@%b%F{$prompt_color3}%M"

# line 1 is pwd, username, host, hour…
prompt_line_1a="$prompt_tbox$prompt_l_paren%B%F{$prompt_color5}%*$prompt_r_paren%b%F{$prompt_color1}$prompt_hyphen$prompt_l_paren%B%F{$prompt_color2}%~$prompt_r_paren%b%F{$prompt_color1}"
prompt_line_1b="$prompt_l_paren$prompt_user_host$prompt_r_paren%b%F{$prompt_color1}${prompt_hyphen}"

# line 2 is prompt
prompt_line_2="$prompt_bbox${prompt_hyphen}%B%F{white}"
prompt_char="%(!.#.>)"
prompt_opts=(cr subst percent)

# This function is called before each prompt regenation
precmd () {
    setopt noxtrace localoptions extendedglob
    local prompt_line_1
    # update VCS information
    vcs_info

    if [[ $TERM == screen* ]] ; then
        if [[ -n ${VCS_INFO_message_1_} ]] ; then
            ESC_print ${VCS_INFO_message_1_}
        else
            ESC_print "zsh"
        fi
    fi

    RPROMPT="%(?..:()"
    
    # Generates battery info
    batcolor
    BATTERY="${BATTCOLOR}${PERCENT} %%"
    RPROMPT="${BATTERY} ${RPROMPT}"
    
    # adjust title of xterm
    # see http://www.faqs.org/docs/Linux-mini/Xterm-Title.html
    [[ ${NOTITLE} -gt 0 ]] && return 0
    case $TERM in
        (xterm*|rxvt*)
            set_title ${(%):-"%n@%m: %~"}
            ;;
    esac

    local prompt_line_1a_width=${#${(S%%)prompt_line_1a//(\%([KF1]|)\{*\}|\%[Bbkf])}}
    local prompt_line_1b_width=${#${(S%%)prompt_line_1b//(\%([KF1]|)\{*\}|\%[Bbkf])}}
    local prompt_vcs_width=${#${(S%%)VCS_INFO_message_0_//(\%([KF1]|)\{*\}|\%[Bbkf])}}
  
    local prompt_padding_size=$(( COLUMNS - prompt_line_1a_width - prompt_line_1b_width - prompt_vcs_width - 2 ))

    # Try to fit in long path and user@host, and vcs_info
    if (( prompt_padding_size > 0 )); then
      local prompt_padding
      eval "prompt_padding=\${(l:${prompt_padding_size}::${prompt_hyphen}:)_empty_zz}"
      prompt_line_1="$prompt_line_1a$prompt_padding$prompt_hyphen$VCS_INFO_message_0_%F{$prompt_color1}$prompt_hyphen$prompt_line_1b"
    else
        prompt_padding_size=$(( COLUMNS - prompt_line_1a_width - prompt_vcs_width - 2 ))
      
        # Didn't fit; try to fit in long path and vcs_info
        if (( prompt_padding_size > 0 )); then
            local prompt_padding
            eval "prompt_padding=\${(l:${prompt_padding_size}::${prompt_hyphen}:)_empty_zz}"
            prompt_line_1="$prompt_line_1a$prompt_padding$prompt_hyphen$VCS_INFO_message_0_%F{$prompt_color1}$prompt_hyphen"
        else
            prompt_padding_size=$(( COLUMNS - prompt_line_1a_width ))

            # Didn't fit; try to fit in just long path
            if (( prompt_padding_size > 0 )); then
                eval "prompt_padding=\${(l:${prompt_padding_size}::${prompt_hyphen}:)_empty_zz}"
                prompt_line_1="$prompt_line_1a$prompt_padding"
            else
                # Still didn't fit; truncate 
                local prompt_pwd_size=$(( COLUMNS - 5 ))
                prompt_line_1="$prompt_tbox$prompt_l_paren%B%F{$prompt_color2}%$prompt_pwd_size<...<%~%<<$prompt_r_paren%b%F{$prompt_color1}$prompt_hyphen"
            fi
        fi
    fi
  
  
    # And, makes it good
    PS1="$prompt_line_1$prompt_newline$prompt_line_2%B%F{red}${EXITCODE}%b%F{$prompt_color1}$prompt_hyphen%B%F{white}$prompt_char %b%f%k"
    PS2="$prompt_line_2$prompt_bbox_to_mbox%B%F{white}%_> %b%f%k"
    PS3="$prompt_line_2$prompt_bbox_to_mbox%B%F{white}?# %b%f%k"

    # Text color and style for prompt
    zle_highlight[(r)default:*]="default:fg=$prompt_color4,bold"
}

# preexec() => a function running before every command
preexec () {
    # set hostname if not running on host with name 'grml'
    if [[ -n "$HOSTNAME" ]] && [[ "$HOSTNAME" != $(hostname) ]] ; then
       NAME="@$HOSTNAME"
    fi
    # get the name of the program currently running and hostname of local machine
    # set screen window title if running in a screen
    if [[ "$TERM" == screen* ]] ; then
        # local CMD=${1[(wr)^(*=*|sudo|ssh|-*)]}       # don't use hostname
        local CMD="${1[(wr)^(*=*|sudo|ssh|-*)]}$NAME" # use hostname
        ESC_print ${CMD}
    fi
    # adjust title of xterm
    [[ ${NOTITLE} -gt 0 ]] && return 0
    case $TERM in
        (xterm*|rxvt*)
            set_title "${(%):-"%n@%m:"}" "$1"
            ;;
    esac
}


# # set variable debian_chroot if running in a chroot with /etc/debian_chroot
# if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]] ; then
#     debian_chroot=$(cat /etc/debian_chroot)
# fi
# 
# # don't use colors on dumb terminals (like emacs):
# if [[ "$TERM" == dumb ]] ; then
#     PROMPT="${debian_chroot:+($debian_chroot)}%n@%m %# "
# else
#     # only if $GRMLPROMPT is set (e.g. via 'GRMLPROMPT=1 zsh') use the extended prompt
#     # set variable identifying the chroot you work in (used in the prompt below)
#     if [[ $GRMLPROMPT -gt 0 ]] ; then
#         PROMPT="${CYAN}[%j running job(s)] ${GREEN}{history#%!} ${RED}%(3L.+.) ${BLUE}%* %D${BLUE}%n${NO_COLOUR}@%m %# "
#     else
#         # This assembles the primary prompt string
#         if (( EUID != 0 )); then
#             PROMPT="%{${WHITE}%}${debian_chroot:+($debian_chroot)}%{${BLUE}%}%n%{${NO_COLOUR}%}@%m %# "
#         else
#             PROMPT="%{${WHITE}%}${debian_chroot:+($debian_chroot)}%{${RED}%}%n%{${NO_COLOUR}%}@%m %# "
#         fi
#     fi
# fi

# if we are inside a grml-chroot set a specific prompt theme
# if [[ -n "$GRML_CHROOT" ]] ; then
#     PROMPT="%{$fg[red]%}(CHROOT) %{$fg_bold[red]%}%n%{$fg_no_bold[white]%}@%m %40<...<%B%~%b%<< %\# "
# fi

# {{{ 'hash' some often used directories
#d# start
hash -d deb=/var/cache/apt/archives
hash -d doc=/usr/share/doc
hash -d linux=/lib/modules/$(command uname -r)/build/
hash -d log=/var/log
hash -d slog=/var/log/syslog
hash -d src=/usr/src
hash -d templ=/usr/share/doc/grml-templates
hash -d tt=/usr/share/doc/texttools-doc
hash -d www=/var/www
#d# end
# }}}

# I like clean prompt, so provide simple way to get that
check_com 0 || alias 0='return 0'

unlimit
limit stack 8192
limit -s

# called later (via grmlcomp)
# note: use 'zstyle' for getting current settings
#         press ^Xh (control-x h) for getting tags in context; ^X? (control-x ?) to run complete_debug with trace output
grmlcomp() {
    # TODO: This could use some additional information

    # allow one error for every three characters typed in approximate completer
    zstyle ':completion:*:approximate:'    max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'

    # don't complete backup files as executables
    zstyle ':completion:*:complete:-command-::commands' ignored-patterns '(aptitude-*|*\~)'

    # start menu completion only if it could find no unambiguous initial string
    zstyle ':completion:*:correct:*'       insert-unambiguous true
    zstyle ':completion:*:corrections'     format $'%{\e[0;31m%}%d (errors: %e)%{\e[0m%}'
    zstyle ':completion:*:correct:*'       original true

    # activate color-completion
    zstyle ':completion:*:default'         list-colors ${(s.:.)LS_COLORS}

    # format on completion
    zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'

    # complete 'cd -<tab>' with menu
    zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

    # insert all expansions for expand completer
    zstyle ':completion:*:expand:*'        tag-order all-expansions
    zstyle ':completion:*:history-words'   list false

    # activate menu
    zstyle ':completion:*:history-words'   menu yes

    # ignore duplicate entries
    zstyle ':completion:*:history-words'   remove-all-dups yes
    zstyle ':completion:*:history-words'   stop yes

    # match uppercase from lowercase
    zstyle ':completion:*'                 matcher-list 'm:{a-z}={A-Z}'

    # separate matches into groups
    zstyle ':completion:*:matches'         group 'yes'
    zstyle ':completion:*'                 group-name ''

    # if there are more than 5 options allow selecting from a menu
    zstyle ':completion:*'               menu select=5

    zstyle ':completion:*:messages'        format '%d'
    zstyle ':completion:*:options'         auto-description '%d'

    # describe options in full
    zstyle ':completion:*:options'         description 'yes'

    # on processes completion complete all user processes
    zstyle ':completion:*:processes'       command 'ps -au$USER'

    # offer indexes before parameters in subscripts
    zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

    # provide verbose completion information
    zstyle ':completion:*'                 verbose true

    # recent (as of Dec 2007) zsh versions are able to provide descriptions
    # for commands (read: 1st word in the line) that it will list for the user
    # to choose from. The following disables that, because it's not exactly fast.
    zstyle ':completion:*:-command-:*:'    verbose false

    # set format for warnings
    zstyle ':completion:*:warnings'        format $'%{\e[0;31m%}No matches for:%{\e[0m%} %d'

    # define files to ignore for zcompile
    zstyle ':completion:*:*:zcompile:*'    ignored-patterns '(*~|*.zwc)'
    zstyle ':completion:correct:'          prompt 'correct to: %e'

    # Ignore completion functions for commands you don't have:
    zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'

    # Provide more processes in completion of programs like killall:
    zstyle ':completion:*:processes-names' command 'ps c -u ${USER} -o command | uniq'

    # complete manual by their section
    zstyle ':completion:*:manuals'    separate-sections true
    zstyle ':completion:*:manuals.*'  insert-sections   true
    zstyle ':completion:*:man:*'      menu yes select

    # provide .. as a completion
    zstyle ':completion:*' special-dirs ..

    # run rehash on completion so new installed program are found automatically:
    _force_rehash() {
        (( CURRENT == 1 )) && rehash
        return 1
    }

    ## correction
    # try to be smart about when to use what completer...
    setopt correct
    zstyle -e ':completion:*' completer '
        if [[ $_last_try != "$HISTNO$BUFFER$CURSOR" ]] ; then
            _last_try="$HISTNO$BUFFER$CURSOR"
            reply=(_complete _match _ignored _prefix _files)
        else
            if [[ $words[1] == (rm|mv) ]] ; then
                reply=(_complete _files)
            else
                reply=(_oldlist _expand _force_rehash _complete _ignored _correct _approximate _files)
            fi
        fi'

    # command for process lists, the local web server details and host completion
    zstyle ':completion:*:urls' local 'www' '/var/www/' 'public_html'

    # caching
    [[ -d $ZSHDIR/cache ]] && zstyle ':completion:*' use-cache yes && \
                            zstyle ':completion::complete:*' cache-path $ZSHDIR/cache/

    # host completion /* add brackets as vim can't parse zsh's complex cmdlines 8-) {{{ */
    [[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
    [[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
    hosts=(
        $(hostname)
        "$_ssh_hosts[@]"
        "$_etc_hosts[@]"
        grml.org
        localhost
    )
    zstyle ':completion:*:hosts' hosts $hosts
    # TODO: so, why is this here?
    #  zstyle '*' hosts $hosts

    # use generic completion system for programs not yet defined; (_gnu_generic works
    # with commands that provide a --help option with "standard" gnu-like output.)
    for compcom in cp deborphan df feh fetchipac head hnb ipacsum mv \
                   pal stow tail uname ; do
        [[ -z ${_comps[$compcom]} ]] && compdef _gnu_generic ${compcom}
    done; unset compcom

    # see upgrade function in this file
    compdef _hosts upgrade
}

grmlstuff() {
# people should use 'grml-x'!
    startx() {
        if [[ -e /etc/X11/xorg.conf ]] ; then
            [[ -x /usr/bin/startx ]] && /usr/bin/startx "$@" || /usr/X11R6/bin/startx "$@"
        else
            echo "Please use the script \"grml-x\" for starting the X Window System
because there does not exist /etc/X11/xorg.conf yet.
If you want to use startx anyway please call \"/usr/bin/startx\"."
            return -1
        fi
    }

    xinit() {
        if [[ -e /etc/X11/xorg.conf ]] ; then
            [[ -x /usr/bin/xinit ]] && /usr/bin/xinit || /usr/X11R6/bin/xinit
        else
            echo "Please use the script \"grml-x\" for starting the X Window System.
because there does not exist /etc/X11/xorg.conf yet.
If you want to use xinit anyway please call \"/usr/bin/xinit\"."
            return -1
        fi
    }

    if check_com -c 915resolution; then
        855resolution() {
            echo "Please use 915resolution as resolution modifying tool for Intel \
graphic chipset."
            return -1
        }
    fi

    #a1# Output version of running grml
    alias grml-version='cat /etc/grml_version'

    if check_com -c rebuildfstab ; then
        #a1# Rebuild /etc/fstab
        alias grml-rebuildfstab='rebuildfstab -v -r -config'
    fi

    if check_com -c grml-debootstrap ; then
        debian2hd() {
            echo "Installing debian to harddisk is possible by using grml-debootstrap."
            return 1
        }
    fi
}

grmlcomp

# {{{ keephack
xsource "/etc/zsh/keephack"
# }}}

#########################################
##      YOUR PERSONNAL STUFF HERE      ##
#########################################

# Loads local zsh fun
for file in $ZSHDIR/rc/local/*; do
    source $file
done
# }}}

# Delete remaining xfunctions (including salias)
xunfunction
