#!/bin/bash

if [[ -z ${@:1} ]]; then
echo "------------------------------------------------------------"
echo "“Upload deb packages to cydia repo (github cydia repo only)”"

echo "usage : debup [github repo url] [deb directory path] [opt]"

echo "opt."
echo "-mod  : modifying deb file info before uploading"
echo "-v    : verboose mode"
echo "------------------------------------------------------------"
exit 1
fi

if [[ $(echo "$1" | grep -oE '[^.]+$') == git ]]; then
echo "Invalid, please check your repo url.
(Input url without '.git')"
exit 2
elif [[ $# -eq 1 ]]; then
echo "Please input deb directory path"
exit 3
else
   if [[ $1 =~ .*github.com.* ]]; then
     :
   else
     echo "Invalid, please check your repo url.
(e.g 'https://github.com/../..')"
   exit 4
   fi
fi



NAME=$( echo $1 | cut -d "/" -f5 )
REPO=/var/mobile/Debrep/$NAME

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
	
	if [[ ( $3 == -mod || $4 == -mod ) ]]; then
	export DEBUP=/var/tmp/DebUp;
	rm -r $DEBUP > /dev/null 2>&1;
	mkdir $DEBUP;
	cp $2/*.deb $DEBUP;
	while true; do
	options=($(find $DEBUP -name "*.deb" | xargs -n 1 basename))
	prompt="Please select deb file to modify: "
	PS3="$prompt"
	select opt in "${options[@]}" "Quit" ;
	do 
		if (( REPLY == 1 + ${#options[@]} )) ; then
		rm -r /var/mobile/Debrep;
		rm -r $DEBUP;
		exit 6
		
		elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
		deb=$( echo "$opt" | sed 's/\.[^.]*$//' )
		dpkg-deb -R $DEBUP/$opt $DEBUP/$deb;
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
				[Aa]* ) while [[ $a == '' ]]; do
					read -p "Enter desired Author: " a;
					dpkg-deb -f $DEBUP/$opt | sed "s|Author.*|Author: $a|" > $DEBUP/$deb/DEBIAN/control;
					dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
					echo "Done!"
					while true; do
					read -p "Do you want to continue editing?[y/n]? " yn
						case $yn in
						[Yy]* ) a="";
						break 2;;
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
				[Dd]* ) while [[ $d == '' ]]; do
				read -p "Enter desired Dependencies: " d;
				dpkg-deb -f $DEBUP/$opt | sed "s|Depends.*|Depends: $d|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) d="";
					break 2;;
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
				[Mm]* ) while [[ $m == '' ]]; do
				read -p "Enter desired Maintainer: " m;
				dpkg-deb -f $DEBUP/$opt | sed "s|Maintainer.*|Maintainer: $m|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) m="";
					break 2;;
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
				[Nn]* ) while [[ $nm == '' ]]; do
				read -p "Enter desired Name: " nm;
				dpkg-deb -f $DEBUP/$opt | sed "s|Name.*|Name: $nm|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) nm="";
					break 2;;
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
				[Pp]* ) while [[ $pn == '' ]]; do
				read -p "Enter desired Package Name: " pn;
				dpkg-deb -f $DEBUP/$opt | sed "s|Package.*|Package: $pn|" > $DEBUP/$deb/DEBIAN/control;
				mv $DEBUP/$deb $DEBUP/$pn;
				dpkg-deb -b $DEBUP/$pn > /dev/null 2>&1;
				rm $DEBUP/$deb.deb;
				echo "Done!"
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) rm -r $DEBUP/$pn > /dev/null 2>&1 pn="";
					break 3;;
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
				[Vv]* ) while [[ $v == '' ]]; do
				read -p "Enter desired Version: " v;
				dpkg-deb -f $DEBUP/$opt | sed "s|Version.*|Version: $v|" > $DEBUP/$deb/DEBIAN/control;
				dpkg-deb -b $DEBUP/$deb > /dev/null 2>&1;
				echo "Done!"
				while true; do
				read -p "Do you want to continue editing?[y/n] " yn
					case $yn in
					[Yy]* ) v="";
					break 2;;
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
        echo "Invalid option. Try another one."
    fi
	done
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

if [[ $# -lt 4 ]] && [[ $3 == -mod ]]; then
	echo "Saving..."
	cp -r $DEBUP/. $REPO/debs;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && bzip2 $DEBUP/Packages;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && gzip $DEBUP/Packages;
	rm $2/*.deb;
	cp $DEBUP/* $2;
	echo "Creating Hash..."
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
	
	git add --all;
	
	while [[ "$cm" == '' ]]; do
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email": ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name": un;done
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
rm -r /var/mobile/Debrep > /dev/null 2>&1;
apt-get update > /dev/null 2>&1;

elif [[ $# -gt 3 ]] && [[ ( $3 == -mod || $4 == -mod ) ]]; then
	echo "Saving..."
	cp -r $DEBUP/. $REPO/debs;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && bzip2 $DEBUP/Packages;
	dpkg-scanpackages -m $DEBUP > /dev/null 2>&1 > $DEBUP/Packages && gzip $DEBUP/Packages;
	rm $2/*.deb;
	cp $DEBUP/* $2;
	echo "Creating Hash..."
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
		break;
	done
	echo "Uploading..."
	
	git add --all;
	
	while [[ "$cm" == '' ]]; do
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email": ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name": un;done
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

elif [[ ( $3 == -v || $4 == -v ) ]]; then
	cp $2/*.deb $REPO/debs > /dev/null 2>&1;
	echo "Creating Hash..."
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
	break;
	done

echo "Uploading..."
git add --all;
	while [[ "$cm" == '' ]]; do
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email": ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name": un;done
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
	
	git add --all;
	while [[ "$cm" == '' ]]; do
	read -p "Input Commit Messages: " cm;done
		git commit -m "$cm" > /dev/null 2>&1;
		if [[ ! ${?} -eq 0 ]]; then
			while [[ "$ue" == '' ]]; do
			read -p "Input user.email": ue;done
			git config --global user.email "$ue"
			while [[ "$un" == '' ]]; do
			read -p "Input user.name": un;done
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
