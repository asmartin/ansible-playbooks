#!/bin/bash
#######################################################
## Author:	Andrew Martin <amartin@avidandrew.com> 
## Date:	1/10/16
## Descr:	import or export GPG keys
#######################################################
function usage() {
	echo "Export Usage: $0 export public|private keyid output.filename"
	echo "Import Usage: $0 import public|private input.filename"
	echo ""
	echo "Example exporting public key: $0 export public D86E2403 amartin.pub"
        echo "Example importing public key: $0 import public amartin.pub"
	exit 1
}

function exportPublic() {
	echo "exporting public key to $filename"
	gpg --armor --output $filename --export $keyid
}

function exportPrivate() {
	echo "WARNING: this exported private key file ($filename) is unencrypted - protect it!"
	gpg --export-secret-keys --armor $keyid > $filename
}

function importPublic() {
	echo "importing $filename"
	gpg --import $filename
}

function importPrivate() {
	echo "WARNING: be sure to use 'shred -u' on any unencrypted copies of $filename after successful import"
	gpg --allow-secret-key-import --import $filename
}

if [ $# -lt 3 ]; then
	usage
fi

type=$1
keytype=$2
keyid=""
filename=""

if [ "$type" == "import" ]; then
	filename=$3

	case $keytype in
	    public)
			importPublic
			;;
	    private)
			importPrivate
			;;
	    *)
			echo: "error: second argument must be either 'public' or 'private'"
			usage
			;;
	esac
elif [ "$type" == "export" ]; then
	keyid=$3
	filename=$4

	case $keytype in
	    public)
			exportPublic
			;;
	    private)
			exportPrivate
			;;
	    *)
			echo "error: second argument must be either 'public' or 'private'"
			usage
			;;
	esac
else
	echo "error: first argument must be either 'import' or 'export'"
	usage
fi	
