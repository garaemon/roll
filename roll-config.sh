#!/bin/sh

COMMANDS="bootstrap clean-fasl check genrc install_sbcl install_clbuild help"
VERBOSE=false
# constants
SBCL_URL=:pserver:anonymous@sbcl.cvs.sourceforge.net:/cvsroot/sbcl
ROLL_PACKAGES="chimi nurarihyon nurikabe komainu yasha tengu clyax"
usage() {
echo "usage: roll-config.sh COMMAND PARAMS

currently supported commands:

  roll-config.sh bootstrap [-v]
  roll-config.sh uninstall [-v]
  roll-config.sh clean-fasl [-v]
  roll-config.sh check [-v]
  roll-config.sh genrc [-v] SHELL PREFIX_PATH
  roll-config.sh install_sbcl [-v] PREFIX_PATH
  roll-config.sh install_clbuild [-v] PREFIX_PATH
  roll-config.sh help
  
  Options:
    -v: exec commands in verbose mode.
"
};

check_sbcl() {
    which sbcl
}

check_acl() {
    which alisp
}

check_clbuild() {
    which clbuild
}

check_env() {
    if [ "${ROLL_ROOT}" != "" ] ; then
	echo OK
    else
	echo NG
    fi
}

debug_echo() {
    if [ "$VERBOSE" = "true" ] ; then
	echo "[DEBUG] " $@
    fi
}

roll_genrc() {
    TARGET_SHELL=$1
    PREFIX_PATH=$2
    debug_echo "target shell -> $TARGET_SHELL"
    debug_echo "prefix path -> $PREFIX_PATH"
    case $TARGET_SHELL in
	bash ) roll_genrc_bash;;
	csh  ) roll_genrc_csh;;
	zsh  ) roll_genrc_zsh;;
    esac
}

roll_genrc_bash() {
roll_genrc_zsh
}

roll_genrc_csh() {
cat <<EOF
setenv ROLL_ROOT $PREFIX_PATH
setenv ROLL_LISP
setenv ROLL_GITHUB_COMMITTER
EOF
}

roll_genrc_zsh() {
cat <<EOF
export ROLL_ROOT=$PREFIX_PATH
export ROLL_LISP=
export ROLL_GITHUB_COMMITTER=
EOF
}

roll_check() {
if [ `check_sbcl` -o `check_acl` -o "$ROLL_LISP" != "" ] ; then
    echo Lisp OK
else
    echo Lisp NG
    return 1
fi

if [ `check_clbuild` ] ; then
    echo clbuild OK
else
    echo clbuild NG
    return 2
fi

if [ "`check_env`" = "OK" ] ; then
    echo environmental variable OK
else
    echo environmental variable NG
    return 3
fi

return 0
}

roll_uninstall() {
    CLBUILD_PATH=`which clbuild`
    CLBUILD_DIR=`dirname $CLBUILD_PATH`
    debug_echo remove clbuild sources...
    for i in $ROLL_PACKAGES
    do
	clbuild uninstall $i
    done

    debug_echo remove symlink to ROLL_ROOT
    cd $ROLL_ROOT
    for i in $ROLL_PACKAGES
    do
	rm -f $i
    done
}

roll_clbuild_setup() {
    # setup dependencies
    if [ "`grep -c \"ROLL CONFIG\" $CLBUILD_DIR/dependencies`" = "0" ] ; then
	echo now setting dependencies of clbuild
	echo "# ROLL CONFIG" >> $CLBUILD_DIR/dependencies
	cat ./dependencies >> $CLBUILD_DIR/dependencies
    fi
    # setup my-projects
    touch $CLBUILD_DIR/my-projects
    if [ "`grep -c \"ROLL CONFIG\" $CLBUILD_DIR/my-projects`" = "0" ] ; then
	echo now setting my-projects of clbuild
	echo "# ROLL CONFIG" >> $CLBUILD_DIR/my-projects
	if [ "$ROLL_GITHUB_COMMITTER" = "yes" ] ; then
	    cat ./my-projects-committer >> $CLBUILD_DIR/my-projects
	else
	    cat ./my-projects >> $CLBUILD_DIR/my-projects
	fi
    fi
}

roll_clbuild_install() {
    clbuild install chimi nurarihyon nurikabe komainu yasha tengu clyax
}

roll_symlink_setup() {
    cd $ROLL_ROOT
    for i in $ROLL_PACKAGES
    do
	ln -sf CLBUILD_DIR/source/$i .
    done
}

roll_bootstrap() {
    CLBUILD_PATH=`which clbuild`
    CLBUILD_DIR=`dirname $CLBUILD_PATH`
    debug_echo CLBUILD_DIR is $CLBUILD_DIR
    roll_clbuild_setup
    roll_clbuild_install
    roll_symlink_setup
    return 0
}

roll_clean_fasl() {
    CLBUILD_PATH=`which clbuild`
    CLBUILD_DIR=`dirname $CLBUILD_PATH`
    cd $CLBUILD_DIR/source
    for i in $ROLL_PACKAGES
    do
	find -L $i -name "*fasl" -print -exec rm -f {} \;
    done
}

roll_install_clbuild() {
    TARGET_PATH=$1
    TMP=`pwd`
    cd $TARGET_PATH
    if [ ! -e clbuild ] ; then
	debug_echo "now installing clbuild"
	darcs get http://common-lisp.net/project/clbuild/clbuild
    fi
    cd $TMP
}

roll_install_sbcl() {
    CURRENT_SBCL=`which sbcl`
    if [ "$CURRENT_SBCL" = "" ] ; then
	echo "you need to install sbcl binary first..."
	return 1
    fi
    CURRENT_SBCL_DIR=`dirname $CURRENT_SBCL`
    TARGET_PATH=$1
    TMP=`pwd`
    cd $TARGET_PATH
    if [ ! -e sbcl ] ; then
	debug_echo "checking out sbcl..."
	cvs -d $SBCL_URL co sbcl
	cd sbcl
    else
	debug_echo "updating sbcl..."
	cd sbcl;
	cvs up
    fi
    cat > customize-target-features.lisp <<EOF
(lambda (features)
      (flet ((enable (x)
               (pushnew x features))
             (disable (x)
               (setf features (remove x features))))
        ;; Threading support, available only on x86/x86-64 Linux, x86 Solaris
        ;; and x86 Mac OS X (experimental).
        (enable :sb-thread)))
EOF
    cat > sbclcompr <<EOF
SBCL_HOME=`dirname $CURRENT_SBCL_DIR`/lib/sbcl $CURRENT_SBCL \$*
EOF
   chmod +x sbclcompr
   debug_echo "now cleaning sbcl..."
   sh clean.sh
   debug_echo "now compiling sbcl..."
   sh make.sh "./sbclcompr"
   debug_echo "now installing sbcl..."
   sudo sh install.sh
}

# main
# $0 = roll-config.sh
# $1 = commands
ROLL_COMMAND=$1
if [ "$ROLL_COMMAND" = "help" ] ; then
    usage
    exit 0
fi
shift 1				# dispose command

# parse options
while getopts v OPT
do
    case $OPT in
	"v" ) VERBOSE=true;;
    esac
done

shift `expr $OPTIND - 1`

for i in $COMMANDS
do
    if [ "$i" = "$ROLL_COMMAND" ] ; then
	roll_$i $@
	exit $?
    fi
done

# error trap
usage
exit 1

