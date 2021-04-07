# DebUp
A simple Command line to manage and upload deb packages to Cydia Repo (Github Cydia Repo).
This command line allow you to upload deb packages to cydia repo with a single click,
it can be usefull for developers who dealing with upload/reupload packages alot,
also it has feature to modifying control file of deb packages before uploading,
such Author, Depends, Version etc.


All you have to do is just put your ready-to-upload deb packages in a directory
and copy the directory path then run this command along with your github cydia repo
and directory path of your deb packages.

E.G
`debup` https://github.com/username/repo /var/mobile/deb

then let it finish.

# Usage


usage : `debup` [github repo url] [deb directory path] [opt]

without opt will upload all deb files.


opt.

-mod  : modifying deb file info before uploading.

-f    : add files to github repo. (files directory path)

-v    : verbose mode.


<use this opt without directory path>

-c    : delete large file from github history (cache).

-r    : delete deb packages from cydia repo.


When using -c try not to delete your existing files."
