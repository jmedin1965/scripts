# scripts - a collection of scripts for /usr/local/scripts

$GitAuthorInfo$
$GitAuthorDate$
$GitAuthorName$
$GitAuthorEmail$
$GitTagsLong$
$GitTagsShort$


Just a collection of scripts I keep re-cerating or copying arround on my ubuntu linux machines.
This is my first attempt at managing this via a github repository.

## How to connect

If you have existing files in /user/local, then be very careful as you may loose these. Either way, don't download the repo directly into /usr/local. cd to a directory that does not have a sub-folder called local and do the following

cd /usr/local
git clone https://jmedin1965@github.com/jmedin1965/scripts

Please check out the WIKI for information: https://github.com/jmedin1965/local/wiki

## The file list

bin/compare-packages-on-other-machine.sh
bin/compiz-detect-window-properties.sh
bin/convert-to-3gp.sh
bin/convert-to-avi.sh
bin/copy-to-aragorn
bin/copy-to-nagios
bin/git-flow	- official git flow functions
bin/git-ident	- a git program to handle git identification variables in text files using filters and gitattributes
bin/git-prompt.sh
bin/gitflow	- official git flow functions
bin/kernel-clean-old
bin/letsencrypt-auto
bin/letsencrypt-update-gitlab.sh
bin/letsencrypt-update-ipfire.sh
bin/list-installed-packages.sh
bin/map
bin/meld-for-git
bin/pmail
bin/rcs-to-git.sh.old
bin/scsi-rescan
bin/ssh-greg.sh
bin/ssh-mat.sh
README.md	- This file
sbin/auto-mount.sh
sbin/backup-to-usb.sh
sbin/backup.sh
sbin/enable-apt-cacher.sh
sbin/filesystem-merge-squashfs.sh
sbin/get.cam.sh
sbin/git-check.sh
sbin/git-commit-message-for-apt.sh
sbin/git-pull-local.sh
sbin/letsencrypt-auto-renew
sbin/recycle-shadow-copy.sh
