#!/bin/sh

## Version 0.1.1
##
## Usage
##      -v      Show version
##      -h      Show help
##      -vvv    Verbose
##
## The script install_dependencies.sh allows you to install or update Popcorn Time depencencies.
##

VERBOSE=
PACKAGE_MANAGER=

help () {
    head $0 -n10 | tail -n9 | sed s/\#\#[\ \n]*//g
}

message() {
    echo "\n$*"
}

is_installed() {
    [ -z "$(whereis $1 | awk '{print($2);}')" ] && \
        return 1 || \
        return 0
}

QUESTION() {
    tries=0

    while [ $tries -lt 3 ]
    do
        read -p "$* (yes/no) [yes] " yn
        yn=$(echo $yn | sed 's/./\L&/g') # convert to lowercase (;

        # standart response
        [ -z "$yn" ] && yn=yes

        tries=$((tries + 1))

        [ "$yn" = "yes" ] && return 0 || \
        [ "$yn" = "no"  ] && return 1

        message "Not a valid answer, please try again"
        sleep 1
    done

    message "No valid input, exiting"
    return 1
}

DEBUG() {
    [ "$VERBOSE" = "yes" ] && echo -n "$*"
}

set_package_manager() {
    check_package_managers pacman apt yum dnf brew ports emerge pkgin pkg pkg_add
    DEBUG "Using '$PACKAGE_MANAGER' as package manager."
}

check_package_managers() {
    for mgmt in $*
    do
        if is_installed $mgmt; then
            PACKAGE_MANAGER=$mgmt
            return
        fi
    done
    if   [ -d /usr/ports/www/node     ]; then PACKAGE_MANAGER=FreeBSD
    elif [ -d /usr/ports/lang/node    ]; then PACKAGE_MANAGER=OpenBSD
    elif [ -d /usr/pkgsrc/lang/nodejs ]; then PACKAGE_MANAGER=NetBSD
    fi

    if [ -z "$PACKAGE_MANAGER" ]; then
        message "I couldn't determine your package manager." \
                "Please continue manually."
        exit 5
    fi
}

install_node() {
    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -S nodejs npm
            ;;
        apt)
            curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
            apt-get install -y build-essential nodejs
            ;;
        yum)
            curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
            yum -y install gcc-c++ make nodejs npm
            ;;
        dnf)
            dnf install nodejs
            ;;
        emerge)
            emerge nodejs
            ;;
        pkg)
            pkg install node
            ;;
        pkg_add)
            pkg_add node
            ;;
        FreeBSD)
            cd /usr/ports/www/node && make install clean
            ;;
        OpenBSD)
            cd /usr/ports/lang/node && make install clean
            ;;
        NetBSD)
            cd /usr/pkgsrc/lang/nodejs && make install
            ;;
    esac
}

check_dependencies() {
    for dep in $*
    do
        DEBUG "Verifying: $dep"
        if is_installed $dep
        then
            DEBUG "$dep is installed."
            continue
        fi

        case "$dep" in
            npm)
                if QUESTION \
                    "I require NPM/NodeJS" \
                    "https://nodejs.org/en/download/" \
                    "Do you wish I try to install it for you?"
                then
                    DEBUG "Preparing to install NodeJS"
                    install_node
                    check_dependencies npm
                    continue
                fi

                message "Ensure the existance of NPM/NodeJS in your" \
                        "machine following the official documentation" \
                        "https://nodejs.org/en/download/package-manager/"
                exit 4
                ;;
        esac

        message "I'm afraid I cannot continue without '$dep' installed."
        exit 4
    done
}

for param in $*
do
    case "$param" in -vvv)
            VERBOSE="yes"
            ;;
        -h)
            message "Usage: ./$0 [-v|-vvv|-h]\n" \
                    "or   sh $0"
            help
            exit 0
            ;;
        -v)
            help | grep Version
            exit 0
            ;;
    esac
done

set_package_manager
check_dependencies npm
