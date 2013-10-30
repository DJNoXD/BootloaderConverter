#!/bin/bash

#--------------------------------------------
#New <<-->> Old Bootloader P990 ROM Converter
#Version: 1.0
#Date:Aug 23, 2013
#Author Spyrosk@xda-developers
#--------------------------------------------

Line2newbl () {
	IFS=$lf
	if [[ $line == *mmcblk0p1* ]]; then line=$(echo $line|sed "s/mmcblk0p1/mmcblk0p12/g")
	elif [[ $line == *mmcblk0p9* ]]; then line=$(echo $line|sed "s/mmcblk0p9/mmcblk0p11/g")
	elif [[ $line == *mmcblk0p8* ]]; then line=$(echo $line|sed "s/mmcblk0p8/mmcblk0p9/g")
	elif [[ $line == *mmcblk0p7* ]]; then line=$(echo $line|sed "s/mmcblk0p7/mmcblk0p8/g")
	elif [[ $line == *mmcblk0p6* ]]; then line=$(echo $line|sed "s/mmcblk0p6/mmcblk0p7/g")
	elif [[ $line == *mmcblk0p5* ]]; then line=$(echo $line|sed "s/mmcblk0p5/mmcblk0p6/g")
	elif [[ $line == *mmcblk0p3* ]]; then line=$(echo $line|sed "s/mmcblk0p3/mmcblk0p5/g")
	elif [[ "$line" == *"/devices/platform/sdhci-tegra.3/mmc_host/mmc0"* ]]; then line=$(echo $line|sed "s/9/11/g")
	fi;
	unset IFS
}

Line2oldbl () {
	IFS=$lf
	if [[ $line == *mmcblk0p12* ]]; then line=$(echo $line|sed "s/mmcblk0p12/mmcblk0p1/g")
	elif [[ $line == *mmcblk0p11* ]]; then line=$(echo $line|sed "s/mmcblk0p11/mmcblk0p9/g")
	elif [[ $line == *mmcblk0p9* ]]; then line=$(echo $line|sed "s/mmcblk0p9/mmcblk0p8/g")
	elif [[ $line == *mmcblk0p8* ]]; then line=$(echo $line|sed "s/mmcblk0p8/mmcblk0p7/g")
	elif [[ $line == *mmcblk0p7* ]]; then line=$(echo $line|sed "s/mmcblk0p7/mmcblk0p6/g")
	elif [[ $line == *mmcblk0p6* ]]; then line=$(echo $line|sed "s/mmcblk0p6/mmcblk0p5/g")
	elif [[ $line == *mmcblk0p5* ]]; then line=$(echo $line|sed "s/mmcblk0p5/mmcblk0p3/g")
	elif [[ "$line" == *"/devices/platform/sdhci-tegra.3/mmc_host/mmc0"* ]]; then line=$(echo $line|sed "s/11/9/g")
	fi;
	unset IFS
}

Convert2newbl () {
	filename="${1##*/}"
	let n=0
	let lstart=0
	let occur=0
	found=false
	echo -n "Processing $1 ... "
	lastline=$(tail -n 1 $1)
	eol=$(tail -n 1 $1; echo x); eol="${eol%x}"; eol="${eol#"${eol%?}"}"
	while IFS= read -r line; do
		let n+=1
		if [[ "$line" == *unmount*/system* ]]; then
			let occur+=1
			if [ -e out/ramdisk/init.cm.rc ] && [ $occur == 2 ]; then
				#if rom is cm-based only and before the last unmount /system line add these
				echo 'ui_print("checking and fixing filesystems");'>>$dest/$filename
				echo 'package_extract_file("system/bin/lgdrm.img", "/tmp/lgdrm.img");'>>$dest/$filename
				echo 'package_extract_file("system/bin/check_sdcard.sh", "/tmp/check_sdcard.sh");'>>$dest/$filename
				echo 'set_perm(0, 0, 0755, "/tmp/check_sdcard.sh");'>>$dest/$filename	
				echo 'run_program("/tmp/check_sdcard.sh", "");'>>$dest/$filename	
				echo 'delete("/system/bin/check_sdcard.sh");'>>$dest/$filename	
				echo 'delete("/system/bin/lgdrm.img");'>>$dest/$filename
			fi;
		fi;
		if [[ "$line" == *mkdir*/data/nv* ]]; then let lstart=$n+3; found=true; fi; #found in cm-based roms
		if [[ $found == true ]] && [[ $n -eq $lstart ]]; then
			echo "">>$dest/$filename
			echo "    mkdir /data/ve">>$dest/$filename
			echo "    chown system system /data/ve">>$dest/$filename
			echo "    mount ext3 /dev/block/mmcblk0p10 /data/ve">>$dest/$filename
			echo "    chmod 0711 /data/ve">>$dest/$filename
			let lstart=0
			found=false
		fi;
		WriteLine
	done < <(printf '%s\n' "$(cat $1)");
	#Add at the end of file
	if [[ "$filename" == "init.star.rc" ]]; then
		echo "">>$dest/$filename
		echo "service charger /charger">>$dest/$filename
		echo "    class charger">>$dest/$filename
		echo "    user root">>$dest/$filename
		echo "    group root">>$dest/$filename	
		echo "    oneshot">>$dest/$filename	
	fi;
	echo done.
}

Convert2oldbl () {
	filename="${1##*/}"
	let n=0
	let lstart=0
	let lend=0
	found=false
	echo -n "Processing $1 ... "
	lastline=$(tail -n 1 $1)
	eol=$(tail -n 1 $1; echo x); eol="${eol%x}"; eol="${eol#"${eol%?}"}"
	while IFS= read -r line; do
		let n+=1
		if [[ "$line" == *"checking and fixing filesystems"* ]]; then let lstart=$n; let lend=$n+6; found=true; fi;
		if [[ "$line" == *"mkdir /data/ve"* ]]; then let lstart=$n; let lend=$n+3; found=true; fi;
		if [[ "$line" == *"service charger /charger"* ]]; then let lstart=$n; let lend=$n+5; found=true; fi;
		if [[ $found == true ]]; then
			#if lines to omit found, print only lines before $lstart and after $lend
			if [[ $n -lt $start ]] || [[ $n -gt $lend ]]; then
				WriteLine

			fi;
		else
			WriteLine
		fi;
	done < <(printf '%s\n' "$(cat $1)");
	echo done.
}

WriteLine () {
	if [[ "$line" == "$lastline" ]]; then
		Line2$prefixto
		[ "$eol" == "$lf" ] && echo "$line" >> $dest/$filename || echo  -n "$line" >> $dest/$filename
	else
		Line2$prefixto
		echo "$line" >> $dest/$filename
	fi;
}

ValidateBL () {
	[ -d tmp ] && rm -r tmp
	mkdir tmp
	unzip -q -j -d tmp $1 META-INF/com/google/android/updater-script 2> /dev/null
	[ $action == 1 ] && mp=6 || mp=5
	if [ -e tmp/updater-script ]; then
		str=$(cat tmp/updater-script | grep "/dev/block/mmcblk0p$mp")
		echo $str
	else
		echo "Cannot determine if source rom is a $prefixfrom one."
		read -p "Continue anyway? " answr
		case $answr in
			[Yy]* ) break;;
			* ) exit 9;;
		esac
		str=continue
	fi;
#	rm -r tmp
	if [[ "$str" == "" ]]; then
		return 99
	else
		return 0
	fi;
}

SelectFile () {
	let n=0
	answr=
	echo $2
	for file in $1; do
		if [ ! -d $file ]; then
			let n+=1
			echo "   $n. ${file##*/}"
			[ $n == 1 ] && echo $file>list.txt || echo $file>>list.txt
		fi
	done;
	echo
	read -p "Type the desired $3 number and press [enter] " answr
	if [[ "$answr" -le "0" ]] || [[ "$answr" -gt "$n" ]]; then
		echo Wrong answer. Retrying ..
		SelectFile "$1" "$2" "$3"
	fi;	
}

action=1
step=$1
srczips=source_zips
outzips=converted_roms
srcdir=romfiles
workdir=converted
lf='
'
while true; do
	echo "========================================"
	echo "   P990 ROM Converter v1.0             |"
	#echo "----------------------------------------"
	echo "   Converting script by SpyrosK        |"
	echo "   Converting info   by TonyP          |"
	echo "   Date: Aug 23, 2013                  |"
	echo "========================================"
	echo
	echo "Converts the ROM for the old bootloader."
	echo
	prefixto=oldbl;
	prefixfrom=newbl;
	break;
done
echo

#STEP 1: Select and Extract source zip
[ -d $srcdir ] && rm -r -f $srcdir > /dev/null 2>/dev/null
if [ ! -d $srcdir ]; then
	mkdir $srcdir >/dev/null 2>/dev/null
else
	echo "Folder $srcdir should be empty but it's not."
	echo "Try to empty it manually first then"
	read -p "press [enter] to continue" answr
fi
echo
echo "STEP 1: SELECTING AND EXTRACTING ROM.zip ..."
echo
[ ! -d $srczips ] && mkdir $srczips
if [ "$(ls -A $srczips)" ]; then
	romzip=$srczips/$(ls -A $srczips) #read the nth specific line 
	echo $romzip
#	rm list.txt
else
	echo "No ROM zip found."
	read -p "Drag n' drop here the $prefixfrom-rom.zip to be converted. " romzip
fi;
#Validate this rom is for new bootloader
ValidateBL $romzip
if [[ "$?" != "0" ]]; then
	echo ""
	echo "Selected ROM:'${romzip##*/}' is an $prefixto already."
	echo "!! CONVERTION CANCELED !!"
	exit 99
fi;
#Extract it
echo -n "Extracting ${romzip##*/} ... "
unzip -q -d $srcdir $romzip
if [[ "$?" -ne "0" ]]; then
	echo "Error:$? Something went wrong"
	echo "Please extract rom's zip manually in $srcdir folder"
	read -p "Press [enter] when ready" answr
else
	echo done.
fi;
if [ ! "$(ls -A $srcdir)" ]; then
	echo "No ROM files found in $srcdir directory"
	echo "!! CONVERTION CANCELED !!"
	exit 9
fi;
echo
romzip="${romzip##*/}" #keep filename only for future use

#STEP 2: Extract boot.img
#		if boot.img not found ask for dragging n' dropping boot.img from $srcdir directory
echo
echo "STEP 2: EXTRACTING BOOT.IMG ..."
[ "$step" == "-stepmode" ] && read -p "Press [enter] when ready" answr
echo
bootimg=$srcdir/boot.img
if [ ! -e $bootimg ]; then
	echo "BootImage named 'boot.img' not found in $srcdir directory"
	echo "If it is named differently please type it's name with it's path or"
	read -p "explore $srcdir folder and just drag n' drop it here " bootimg
fi;
cp $bootimg boot.img
[ $? -gt 0 ] && exit 2

./extractboot boot.img
echo
if [[ $action == 1 ]]; then
	echo -n "Removing not used files ... "
	[ -e out/ramdisk/charger ] && rm -f out/ramdisk/charger
	[ -d out/ramdisk/res ] && rm -r -f out/ramdisk/res
	[ -e $srcdir/system/bin/check_sdcard.sh ] && rm -f $srcdir/system/bin/check_sdcard.sh
	[ -e $srcdir/system/bin/lgdrm.img ] && rm -f $srcdir/system/bin/lgdrm.img
	echo done.
fi

#STEP 3: Convert files
echo
echo "STEP 3: CONVERTING NECCESSARY FILES ..."
[ "$step" == "-stepmode" ] && read -p "Press [enter] when ready" answr
echo
if [ -e $workdir ]; then rm -r $workdir; fi
mkdir $workdir
mkdir $workdir/ramdisk
cat files2convert.txt|while read file
do
	if [[ "${file%/*}" == "/ramdisk" ]]; then
		src=out
		dest=$workdir/ramdisk
	else
		src=$srcdir
		dest=$workdir
	fi;
	[ -e $src$file ] && Convert2$prefixto $src$file
done;
echo

#STEP 4: Overwite original files with converted ones
echo
echo "STEP 4: OVERWRITING CONVERTED FILES ..."
[ "$step" == "-stepmode" ] && read -p "Press [enter] when ready" answr
echo
cat files2convert.txt|while read file
do
	fname="${file##*/}"
	dir="${file%/*}"
	if [[ "$dir" == "/ramdisk" ]]; then
		src=$workdir/ramdisk
		dest=out
	else
		src=$workdir
		dest=$srcdir
	fi;
	if [ -e "$src/$fname" ]; then
		echo -n "copying '$fname' ... "
		cp "$src/$fname" "$dest/$file"
		echo done.
	fi;
done;
if [ -e out/ramdisk/init.cm.rc ]; then
	echo -n "Replacing 'liblgeril.so' ... "
	cp keep4$prefixto/cm-liblgeril.so $srcdir/system/lib/liblgeril.so
	echo done.
fi;
if [[ $action == 2 ]]; then
	cp keep4$prefixto/charger out/ramdisk/charger
	cp -r keep4$prefixto/res out/ramdisk/res
	echo done.
	if [ -e out/ramdisk/init.cm.rc ]; then
		echo -n "Adding 'check_sdcard.sh' ... "
		cp keep4$prefixto/check_sdcard.sh $srcdir/system/bin/check_sdcard.sh
		echo done.
		echo -n "Adding 'lgdrm.img' ... "
		cp keep4$prefixto/lgdrm.img $srcdir/system/bin/lgdrm.img
		echo done.
	fi
fi

#STEP 5: Pack new boot.img and replace original
echo
echo "STEP 5: PACKING NEW BOOT.IMG ..."
[ "$step" == "-stepmode" ] && read -p "Press [enter] when ready" answr
echo
let nkrnl=$(ls -1 kernels/$prefixto-*.zImage|wc -l) >/dev/null 2>/dev/null
#let nkrnl=$(find kernels/$prefixto-* -maxdepth 0 -type f | wc -l) >/dev/null 2>/dev/null
if [[ $nkrnl == 0 ]]; then
	echo "No available kernel for $prefixto."
	echo "Please add a kernel image and its modules in kernels folder,"
	echo "according to instructions in xda thread"
	read -p "Press [enter] when ready" answr
	zImage=$(ls kernels/$prefixto-*)
	if [[ "$zImage" == "" ]]; then exit 2; fi;
elif [[ $nkrnl == 1 ]]; then
	zImage=$(ls kernels/$prefixto-*.zImage)
	#zImage=$(find kernels/$prefixto-* -maxdepth 0 -type f)
else
	#Let user select the desired kernel if more than one suitable found
	#SelectFile "kernels/$prefixto-*" "Select the desired kernel to use in converted ROM" "kernel"
	SelectFile "kernels/$prefixto-*.zImage" "Select the desired kernel to use in converted ROM" "kernel"
	zImage=$(sed -n "${answr}{p;q;}" list.txt) #read the nth specific line 
	rm list.txt
fi;
echo "Selected kernel: ${zImage##*/}"
cp "$zImage" boot.img-kernel
./packboot
mv -f boot_new.img $bootimg
echo
#replace kernel data
echo -n "Replacing kernel modules ... "
rm -r $srcdir/system/lib/modules/*
[ -e "$srcdir/system/etc/init.d/95kowalski" ] && rm "$srcdir/system/etc/init.d/95kowalski"
krnldata=${zImage##*/};krnldata=${krnldata%.*}; 
[ ! -d kernels/$krnldata ] && krnldata=$( echo $krnldata | sed "s/$prefixto-//g")
cp -r --preserve=timestamps kernels/$krnldata/* $srcdir/system
echo done.

#cleaning up
rm -f boot.img*
rm -r -f out
rm -r -f $workdir

#Step 6: if zp,unzip are installed Zip new ROM else prompt user to manual zip
echo
echo "STEP 6: ZIPPING NEW CONVERTED ROM ..."
[ "$step" == "-stepmode" ] && read -p "Press [enter] when ready" answr
echo
[[ $romzip == *$prefixfrom* ]] && newrom=$(echo $romzip|sed "s/$prefixfrom/$prefixto/g")
if [[ "$newrom" == "" ]]; then
	#build new name
	newrom="${romzip%.*}-$prefixto.zip"
fi;
echo -n "Creating new ROM: $newrom ... "
[ ! -d $outzips ] && mkdir $outzips
cd $srcdir
zip -q -r ../$outzips/$newrom *
if [[ "$?" == "0" ]]; then
	echo done.
	echo -n "Removing $srcdir ... "
	cd ..
	rm -r -f $srcdir > /dev/null 2>/dev/null
	echo done.
	echo 
	echo "Converted ROM is succesfully created in 'converted_roms' folder."
	echo "ENJOY !!"
else
	echo "Error:$?"
	echo "Something went wrong please zip contents in $srcdir folder manually"
fi;
