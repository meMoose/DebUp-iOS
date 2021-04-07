#!/bin/bash

if [[ -z ${@:1} ]]; then
echo "------------------------------------------------------------"
echo "“Upload & Manage packages to cydia repo (github cydia repo only)”

usage : debup [github repo url] [deb directory path] [opt]

without opt will upload all deb files.

opt.
-mod  : modifying deb file info before uploading.
-f    : add files to github repo. (files directory path)
-v    : verbose mode.

<use this opt without directory path>
-c    : delete large file from github history (cache).
-r    : delete deb packages from cydia repo.

When using -c try not to delete your existing files."
echo "------------------------------------------------------------"
exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
exit 2
elif [[ $(echo "$1" | grep -oE '[^.]+$') == git ]]; then
echo "Invalid, please check your repo url.
(Input url without '.git')"
exit 3
elif [[ ! $1 =~ .*github.com.* ]]; then
echo "Invalid, please check your repo url.
(e.g 'https://github.com/../..')"
exit 4
elif [[ $# -eq 1 ]]; then
echo "Please input deb or files directory path"
exit 5
elif [ $2 != -r ] && [ $2 != -c ] && [[ $3 != -f || $3 == -z ]] && [ `ls -1 $2/*.deb 2>/dev/null | wc -l ` -eq 0 ]; then
echo "Deb or files not found, please check your directory path or rename your directory"
exit 6
fi

NAME=$( echo $1 | cut -d "/" -f5 )
REPO=/var/mobile/Debrep/$NAME

#Delete github history process
if [ $2 == -c ]; then
	git clone $1 $REPO
	cd $REPO

#get size before caching
   du -sh .git | grep -o '^\S*' | tr -d '\n' > /var/tmp/size.txt && echo -n ' ===> ' >> /var/tmp/size.txt

#get list of history and deleting
	IFS=','
	options=($(git rev-list --objects --all \
	| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
	| awk '/^blob/ {print substr($0,6)}' \
	| sort --numeric-sort --key=2 \
	| cut --complement --characters=13-40 \
	| numfmt --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest | sed -e 's/^\w*\ *//' | tr '\n' ',' | sed 's/.$//'))
	PS3="Please select history to delete: "
		select opt in "${options[@]}" "BATCH DELETE" "QUIT" ;
			do
			if (( REPLY == 1 + ${#options[@]} )) ; then
				while [[ $sel == '' ]]; do
					read -p "select number by spaces: " sel;done
						selected=$((git rev-list --objects --all \
| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
| awk '/^blob/ {print substr($0,6)}' \
| sort --numeric-sort --key=2 \
| cut --complement --characters=13-40 \
| numfmt --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest | awk 'NF>1{print $NF}') | sed -n "$( echo "$sel" | sed 's/[0-9]\+/&p;/g')" | tr '\n' ' ')
						while true; do
							read -p "This will delete other history with same name, Do you want to continue?[y/n]? " yn
							case $yn in
								[Yy]* ) git filter-branch --force --index-filter "git rm --cached -r --ignore-unmatch "$selected"" --prune-empty --tag-name-filter cat -- --all
								break;;
								[Nn]* ) rm -r /var/mobile/Debrep
									rm /var/tmp/size.txt
									exit 0
								break;;
								* ) echo "Please type y/n";;
							esac
						done
			elif (( REPLY == 2 + ${#options[@]} )) ; then
				rm -r /var/mobile/Debrep
				rm /var/tmp/size.txt
				exit 0
			elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
				set=$(echo "$opt" | cut -d' ' -f2-)
				while true; do

#prevent to delete existing files
					read -p "This will delete other history with same name, Do you want to continue?[y/n]? " yn
						case $yn in
						[Yy]* ) git filter-branch --force --index-filter "git rm --cached -r --ignore-unmatch "$set"" --prune-empty --tag-name-filter cat -- --all
						break;;
						[Nn]* ) rm -r /var/mobile/Debrep
							rm /var/tmp/size.txt
							exit 0
						break;;
						* ) echo "Please type y/n";;
						esac
				done
			else
				echo "Invalid, try again"
				exit 4
			fi
		break;
		done

#update and push after deleting history
echo "Updating Repo..."
git filter-branch -f > /dev/null 2>&1
git update-ref -d refs/original/refs/heads/master
git reflog expire --expire=now --all
git gc --prune=now
git push --all --force

#show size after deleting all history
cd ..
size=$(cat /var/tmp/size.txt && du -sh --time $REPO/.git | grep -o '^\S*')
echo "Done!
Compressed from "$size""

#deleting leftover
	if [ -d "$REPO" ]; then
		rm -r $REPO
		cd ..
		rm -d Debrep
	else
		rm -r /var/mobile/Debrep
      rm /var/tmp/size.txt
		exit 0
	fi
rm /var/tmp/size.txt
exit 0
fi
#done

#Add files to github process
if [[ $3 == -f ]]; then
	path=$2/*
	STRING=" "
	for file in $path; do
		if  [[ $file == *"$STRING"* ]]; then
			echo "Invalid, File names contains spaces."
			exit 89
		fi
	done
	git clone $1 $REPO
	cd $REPO

#listing files and select files
	option=($(ls $2))
	PS3="Please Select Your File: "
	select opts in "${option[@]}" "ADD ALL FILES" "QUIT";
	do 

#select all files
		if (( REPLY == 1 + ${#option[@]} )) ; then

#listing and select folder
			options=($(find -type d | sed 's/^.\{2\}//'))
			PS3="Please select folder: "
			select opt in "${options[@]}" "$REPO" "QUIT";
			do
#all files into main github folder and upload
       if (( REPLY == 1 + ${#options[@]} )) ; then
       	cp '$opts' $REPO
       	while [[ "$cm" == '' ]]; do
       		git add --all;
       		read -p "Input Commit Messages: " cm;done
       	git commit -m "$cm" > /dev/null 2>&1;
       	git push origin master
       	echo "Done!"
rm -r /var/mobile/Debrep > /dev/null 2>&1;
       	exit 0

#exit process
     	elif (( REPLY == 2 + ${#options[@]} )) ; then
     		rm -r /var/mobile/Debrep > /dev/null 2>&1;
     		exit 0

#all files into folder then upload
     	elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
     		cp $2/* $REPO/"$opt"
     		while [[ "$cm" == '' ]]; do
     			git add --all;
     			read -p "Input Commit Messages: " cm;done
     		git commit -m "$cm" > /dev/null 2>&1;
     		git push origin master
     		echo "Done!"
rm -r /var/mobile/Debrep > /dev/null 2>&1;
     		exit 0
     	else

#exit process
     		echo "Invalid"
     		rm -r /var/mobile/Debrep > /dev/null 2>&1;
     		exit 7
      fi
     break 2;
     done

#exit process
    elif (( REPLY == 2 + ${#option[@]} )) ; then
    	rm -r /var/mobile/Debrep > /dev/null 2>&1;
    	exit 0

#select one file into main github folder and upload
    elif (( REPLY > 0 && REPLY <= ${#option[@]} )) ; then
    	options=($(find -type d | sed 's/^.\{2\}//'))
    	PS3="Please select folder: "
    	select opt in "${options[@]}" "$REPO" "QUIT";
    	do
    		if (( REPLY == 1 + ${#options[@]} )) ; then
    			cp $2/$opts $REPO
    			while [[ "$cm" == '' ]]; do
    				git add --all;
    				read -p "Input Commit Messages: " cm;done
    			git commit -m "$cm" > /dev/null 2>&1;
    			git push origin master
    			echo "Done!"
rm -r /var/mobile/Debrep > /dev/null 2>&1;
    			exit 0

#exit process
    		elif (( REPLY == 2 + ${#options[@]} )) ; then
    			rm -r /var/mobile/Debrep > /dev/null 2>&1;
    			exit 0

#one file into folder then upload
    		elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
    			cp $2/$opts $REPO/"$opt"
    			while [[ "$cm" == '' ]]; do
    				git add --all;
    				read -p "Input Commit Messages: " cm;done
    				git commit -m "$cm" > /dev/null 2>&1;
    				git push origin master
    				echo "Done!"
rm -r /var/mobile/Debrep > /dev/null 2>&1;
    				exit 0
				else

#exit process
					echo "Invalid"
					rm -r /var/mobile/Debrep > /dev/null 2>&1;
					exit 8
				fi
			break 2;
			done
		else
			echo "Invalid"
			rm -r /var/mobile/Debrep > /dev/null 2>&1;
			exit 9
		fi
	break 2;
	done
fi

#remove deb packages from cydia
if [[ $2 == -r ]]; then
git clone $1 $REPO
cd $REPO/debs

#listing and select deb files
DIR="/var/mobile/Deleted Deb Files"
  					options=($(find $REPO -name "*.deb" | xargs -n 1 basename))
	PS3="Please select package to delete: "
select opt in "${options[@]}" "BATCH REMOVE" "QUIT" ;
	do

#Batch remove
		if (( REPLY == 1 + ${#options[@]} )) ; then
while [[ $sel == '' ]]; do
read -p "Choose number with spaces: " sel;done

#listing selected deb files and delete
selected=$((find $REPO -name "*.deb" | xargs -n 1 basename) | sed -n "$( echo "$sel" | sed 's/[0-9]\+/&p;/g')")
if [ -d "$DIR" ]; then
mv $selected "$DIR" > /dev/null 2>&1;
else
mkdir "$DIR"
mv $selected "$DIR" > /dev/null 2>&1;
fi

#prevent error
if [[ ! ${?} -eq 0 ]]; then
echo Wrong type try again
rm -r /var/mobile/Debrep > /dev/null 2>&1;
exit 5
fi
break;

#exit process
elif (( REPLY == 2 + ${#options[@]} )) ; then
rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 6

#remove one file
		elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
if [ -d "$DIR" ]; then
mv "$opt" "$DIR" > /dev/null 2>&1;
else
mkdir "$DIR"
mv "$opt" "$DIR" > /dev/null 2>&1
fi
break;
fi
done

#making hash for packages and upload
cd ..
dpkg-scanpackages -m .| bzip2 > Packages.bz2;
dpkg-scanpackages -m .| gzip -c > Packages.gz;
git add --all
git commit -m init
git push origin master
echo Done!
rm -r /var/mobile/Debrep > /dev/null 2>&1;
exit 0
fi

#check if repo folder exist if not exist then clone repo
if [[ $# -lt 3 ]]; then
	rm -r $REPO > /dev/null 2>&1;
	echo "Cloning into '$NAME'"
	git clone $1 $REPO > /dev/null 2>&1 && cd $REPO;
	cp $2/*.deb $REPO/debs;

elif [[ $# -lt 5 ]]; then
	rm -r $REPO > /dev/null 2>&1;
while true; do
	if [[ ( $3 == -v || $4 == -v ) ]]; then 
		git clone $1 $REPO && cd $REPO;
	else
	echo "Cloning into '$NAME'"
		git clone $1 $REPO > /dev/null 2>&1 && cd $REPO;
	fi
	if [[ ! ${?} -eq 0 ]]; then
	exit 3
	fi

#modifying info deb packages
	if [[ ( $3 == -mod || $4 == -mod ) ]]; then
	export DEBUP=/var/tmp/DebUp;
	rm -r $DEBUP > /dev/null 2>&1;
	mkdir $DEBUP;

#listing and select deb packages
	cp $2/*.deb $DEBUP;
	while true; do
	options=($(find $DEBUP -name "*.deb" | xargs -n 1 basename))
	prompt="Please select deb file to modify: "
	PS3="$prompt"
	select opt in "${options[@]}" "Quit" ;
	do 

#exit process
		if (( REPLY == 1 + ${#options[@]} )) ; then
		rm -r /var/mobile/Debrep;
		rm -r $DEBUP;
		exit 6
		
#export and editing info
		elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
		deb=$( echo "$opt" | sed 's/\.[^.]*$//' )
		dpkg-deb -R $DEBUP/$opt $DEBUP/$deb;

#choose section to edit
			while true; do
			read -p "Please Choose Field: 
 A : Author
 D : Depends
 M : Maintainer
 N : Name
 P : Package Name
 V : Version
" mod
				case $mod in

#editing Author section
				[Aa]* ) while [[ $a == '' ]]; do
					read -p "Enter desired Author: " a;
					dpkg-deb -f $DEBUP/$opt | sed "s|Author.*|Author: $a|" > $DEBUP/$deb/DEBIAN/control;
					dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
					echo "Done!"

#ask if done, if not then back to choose section
					while true; do
					read -p "Do you want to continue editing?[y/n]? " yn
						case $yn in
						[Yy]* ) a="";
						break 2;;

#done editing and show result
						[Nn]* ) echo "Your changed has been saved and ready to upload";
						echo "-----------------------------------------------"
						dpkg -I $DEBUP/$deb.deb;
						echo "-----------------------------------------------"
						break 3;;

#loop for wrong typing
						* ) echo "Please type y/n";;
						esac
					done
					done
				;;

#editing Depends section
				[Dd]* ) while [[ $d == '' ]]; do
				read -p "Enter desired Dependencies: " d;
				dpkg-deb -f $DEBUP/$opt | sed "s|Depends.*|Depends: $d|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"

#ask if done, if not then back to choose section
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) d="";
					break 2;;

#done editing and show result
					[Nn]* ) echo "Your changed has been saved and ready to upload";
					echo "-----------------------------------------------"
					dpkg -I $DEBUP/$deb.deb;
					echo "-----------------------------------------------"
					break 3;;

#loop for wrong typing
					* ) echo "Please type y/n";;
					esac
				done
				done
				;;

#editing Maintainer section
				[Mm]* ) while [[ $m == '' ]]; do
				read -p "Enter desired Maintainer: " m;
				dpkg-deb -f $DEBUP/$opt | sed "s|Maintainer.*|Maintainer: $m|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"

#ask if done, if not then back to choose section
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) m="";
					break 2;;

#done editing and show result
					[Nn]* ) echo "Your changed has been saved and ready to upload";
					echo "-----------------------------------------------"
					dpkg -I $DEBUP/$deb.deb;
					echo "-----------------------------------------------"
					break 3;;

#loop for wrong typing
					* ) echo "Please type y/n";;
					esac
				done
				done
				;;

#editing Name section
				[Nn]* ) while [[ $nm == '' ]]; do
				read -p "Enter desired Name: " nm;
				dpkg-deb -f $DEBUP/$opt | sed "s|Name.*|Name: $nm|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"
				while true; do

#ask if done, if not then back to choose section
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) nm="";
					break 2;;

#done editing and show result
					[Nn]* ) echo "Your changed has been saved and ready to upload";
					echo "-----------------------------------------------"
					dpkg -I $DEBUP/$deb.deb;
					echo "-----------------------------------------------"
					break 3;;
					* ) echo "Please type y/n";;
					esac
				done
				done
				;;

#editing Packages Name section
				[Pp]* ) while [[ $pn == '' ]]; do
				read -p "Enter desired Package Name: " pn;
				dpkg-deb -f $DEBUP/$opt | sed "s|Package.*|Package: $pn|" > $DEBUP/$deb/DEBIAN/control;

#rename files and rewriting
				mv $DEBUP/$deb $DEBUP/$pn;
				dpkg-deb -b $DEBUP/$pn > /dev/null 2>&1;
				rm $DEBUP/$deb.deb;
				echo "Done!"
#ask if done, if not then back to choose section
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) rm -r $DEBUP/$pn > /dev/null 2>&1 pn="";
					break 3;;

#done editing and show result
					[Nn]* ) echo "Your changed has been saved and ready to upload";
					echo "-----------------------------------------------"
					dpkg -I $DEBUP/$pn.deb;
					echo "-----------------------------------------------"
					rm -r $DEBUP/$pn > /dev/null 2>&1
					break 3;;
					* ) echo "Please type y/n";;
					esac
				done
				done
				;;

#editing Version section
				[Vv]* ) while [[ $v == '' ]]; do
				read -p "Enter desired Version: " v;
				dpkg-deb -f $DEBUP/$opt | sed "s|Version.*|Version: $v|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"

#ask if done, if not then back to choose section
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) v="";
					break 2;;

#done editing and show result
					[Nn]* ) echo "Your changed has been saved and ready to upload";
					echo "-----------------------------------------------"
					dpkg -I $DEBUP/$deb.deb;
					echo "-----------------------------------------------"
					break 3;;
					* ) echo "Please type y/n";;
					esac
				done
				done
			esac
		done
		break;
    else

#loop for wrong typing section
        echo "Invalid option. Try another one."
    fi
	done
#done editing and ask if want to edit another files or upload
	rm -r $DEBUP/$deb > /dev/null 2>&1
	PS3="Please Select Options: "
	select opt in "Modify another package" "Save & Upload all package"; do
		case $opt in
		"Modify another package") a='';
		d='';
		m='';
		nm='';
		pn='';
		v='';
		break;;
		"Save & Upload all package")
		break 2;;
		*) echo "Invalid Options";
		esac
	done
	done
	fi
	break;
done
fi

#editinf info file silent mode
if [[ $# -lt 4 ]] && [[ $3 == -mod ]]; then
	echo "Saving..."
	cp -r $DEBUP/. $REPO/debs;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && bzip2 $DEBUP/Packages;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && gzip $DEBUP/Packages;
	rm $2/*.deb;
	cp $DEBUP/* $2;
	echo "Creating Hash..."
	cd $REPO;
	rm Packages > /dev/null 2>&1;
	rm Packages.bz2 > /dev/null 2>&1;
	rm Packages.gz > /dev/null 2>&1;
	dpkg-scanpackages -m ./debs | bzip2 > Packages.bz2;
	dpkg-scanpackages -m ./debs | gzip -c > Packages.gz;
	echo "Done!"
	while true; do
		echo "-----------------------------------------------"
		ls $DEBUP/*.deb | xargs -n 1 basename;
		echo "-----------------------------------------------"
		read -p "Do you wish to upload?[Y/N]" up;
		case $up in
		[Yy]* ) rm -r $DEBUP;
		break;;
		[Nn]* ) rm -r /var/mobile/Debrep;
		rm -r $DEBUP;
		exit 0
		break;;
		esac
	done
	
	while [[ "$cm" == '' ]]; do
	git add --all;
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email:" ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name:" un;done
			git config --global user.name "$un"
			cm='';
		fi

#uploading process silent mode
	while true; do
	git push origin master > /dev/null 2>&1;
	if [[ ! ${?} -eq 0 ]]; then
		echo "bruhh.. you're typo"
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 45
	else
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		echo "Uploading..."
		break 2;
	fi
	break;
	done
rm -r /var/mobile/Debrep > /dev/null 2>&1;
apt-get update > /dev/null 2>&1;

#uploading process
elif [[ $# -gt 3 ]] && [[ ( $3 == -mod || $4 == -mod ) ]]; then

#Saving edited files and creating hash for packages
	echo "Saving..."
	cp -r $DEBUP/. $REPO/debs;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && bzip2 $DEBUP/Packages;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && gzip $DEBUP/Packages;
	rm $2/*.deb;
	cp $DEBUP/* $2;
	echo "Creating Hash..."
	cd $REPO;
	rm Packages > /dev/null 2>&1;
	rm Packages.bz2 > /dev/null 2>&1;
	rm Packages.gz > /dev/null 2>&1;
	dpkg-scanpackages -m ./debs | bzip2 > Packages.bz2;
	dpkg-scanpackages -m ./debs | gzip -c > Packages.gz;
	echo "Done!"

#show final result
	while true; do
		echo "-----------------------------------------------"
		ls $DEBUP/*.deb | xargs -n 1 basename;
		echo "-----------------------------------------------"

#ask if want to continue if not then cancel all process and delete
		read -p "Do you wish to upload?[Y/N]" up;
		case $up in
		[Yy]* ) rm -r $DEBUP;
		break;;
		[Nn]* ) rm -r /var/mobile/Debrep;
		rm -r $DEBUP;
		exit 0
		break;;
		esac
	done

#uploading
	echo "Uploading..."
	while [[ "$cm" == '' ]]; do
	git add --all;
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm"

#if first time login to github through terminal then setting for terminal login.
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email:" ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name:" un;done
			git config --global user.name "$un"
			cm='';
		fi

#push all files
	while true; do
	git push origin master > /dev/null 2>&1;

#prevent error by typing wrong password. exit, then cancel all process and delete all.
	if [[ ! ${?} -eq 0 ]]; then
		echo "bruhh.. you're typo"
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 45
	else

#uploading
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		echo "Uploading..."
		break 2;
	fi
	break;
	done
apt-get update;

#uploading process verbose mode
elif [[ ( $3 == -v || $4 == -v ) ]]; then
	cp $2/*.deb $REPO/debs > /dev/null 2>&1;
	echo "Creating Hash..."
	cd $REPO;
	rm Packages > /dev/null 2>&1;
	rm Packages.bz2 > /dev/null 2>&1;
	rm Packages.gz > /dev/null 2>&1;
	dpkg-scanpackages -m ./debs | bzip2 > Packages.bz2;
	dpkg-scanpackages -m ./debs | gzip -c > Packages.gz;
	echo "Done!"
	while true; do
	echo "-----------------------------------------------"
	ls $2/*.deb | xargs -n 1 basename;
	echo "-----------------------------------------------"
	read -p "Do you wish to upload?[Y/N]" up;
	case $up in
		[Yy]* )
		break;;
		[Nn]* ) rm -r /var/mobile/Debrep;
		exit 0
		break;;
	esac
	done

echo "Uploading..."
	while [[ "$cm" == '' ]]; do
	git add --all;
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm"
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email:" ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name:" un;done
			git config --global user.name "$un"
			cm='';
		fi
	while true; do
	git push origin master > /dev/null 2>&1;
	if [[ ! ${?} -eq 0 ]]; then
		echo "bruhh.. you're typo"
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 45
	else
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		echo "Uploading..."
		break 2;
	fi
	break;
	done
apt-get update;

else
	echo "Creating Hash..."
	cd $REPO;
	rm Packages > /dev/null 2>&1;
	rm Packages.bz2 > /dev/null 2>&1;
	rm Packages.gz > /dev/null 2>&1;
	dpkg-scanpackages -m ./debs | bzip2 > Packages.bz2;
	dpkg-scanpackages -m ./debs| gzip -c > Packages.gz;
	echo "Done!"
	while true; do
	echo "-----------------------------------------------"
	ls $2/*.deb | xargs -n 1 basename;
	echo "-----------------------------------------------"
	read -p "Do you wish to upload?[Y/N]" up;
		case $up in
		[Yy]* )
		break;;
		[Nn]* ) rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 0
		break;;
       * ) Please type y/n;;
		esac
	done
	
	while [[ "$cm" == '' ]]; do
	git add --all;
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email:" ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name:" un;done
			git config --global user.name "$un"
			cm='';
		fi
	while true; do
	git push origin master > /dev/null 2>&1;
	if [[ ! ${?} -eq 0 ]]; then
		echo "bruhh.. you're typo"
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		exit 45
	else
		rm -r /var/mobile/Debrep > /dev/null 2>&1;
		echo "Uploading..."
		break 2;
	fi
	break;
	done
apt-get update > /dev/null 2>&1;
fi

echo "Done!, Check Your Cydia Repo"
exit 0
