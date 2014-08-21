# provisioning.sh v16 : A simple system update script
# Copyright (C) 2014 Dog Hunter AG  
# 
# Author : Arturo Rinaldi
# E-mail : arturo@doghunter.org 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/bin/sh

boardname=$(awk '/machine/ {print tolower($4)}' /proc/cpuinfo)

convertmonth () {
    
    months="Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
    month=$1
    string="${months%$month*}"
    temp="$((${#string}/4 + 1))"
    
    printf "%02d\n" $temp

}

settings () {

    dateonboard=$(uname -a | awk {'print $7,$6,$10'} | sed 's/ /-/g')

    datelatest=$(wget -c -q -O 2>&1 - http://download.linino.org/linino_distro/$1/$2/ | grep $boardname -m 1 | awk {'print $7'} | sed 's/align="right">//g')

    if [ -z $datelatest ]
    then

	echo "Run provisioning --help for USAGE" 
	exit 0
	
    fi

}

checkarguments () {

    if [ -z $1 ] || [ -z $2 ]
    then
	
	echo ""
	echo "USAGE : provisioning.sh <branch> ( lininoIO or master ) <revision> ( latest or YYYYMMDD.x where x=0,1,2...n )"
	echo ""
	exit 0
	
    fi
}

templateimage () {

    if [ $1 == 'yun' ] || [ $1 == 'freedog' ]
    then

	args='16M-250k-'
	
    elif [ $1 == 'one' ]
    then

	args='16M-'
	
    elif [ $1 == 'chiwawa' ]
    then

	args=''
	
    fi

    if [ $2 == 'master' ]
    then
	
	template='openwrt-ar71xx-generic-linino-'$1'-'$args'squashfs-sysupgrade.bin'

    elif [ $2 == 'lininoIO' ]
    then
    
	template='lininoIO-generic-linino-'$1'-squashfs-sysupgrade.bin'
	
    fi
    
}
      
infos () {

    echo "Current kernel date : "$dateonboard
    echo ""
    echo "Latest kernel date : "$datelatest
    echo ""
    echo "Board : "$boardname
    echo ""

}

boardavailable () {

    if ( [ $boardname != 'yun' ] && [ $boardname != 'one' ] && [ $boardname != 'freedog' ] && [ $boardname != 'chiwawa' ] )
    then
    
	echo "Your board is not supported ! Aborting..."    
	exit 0
	
    fi
      
} 

online () {
    
    echo "Verifying internet connection..."
    echo ""
    
    ping -c 3 8.8.8.8 > /dev/null 2>&1
    
    if [ $? -eq 1 ]
    then
	
	echo "No internet connection available, aborting..."
	exit 0
	
    fi

}


verifyupgrade () {
  
    d1=`echo $1 | sed 's/-/ /g' | awk {'print $1'}`
    m1=`convertmonth $(echo $1 | sed 's/-/ /g' | awk {'print $2'})`
    y1=`echo $1 | sed 's/-/ /g' | awk {'print $3'}`
    
    d2=`echo $2 | sed 's/-/ /g' | awk {'print $1'}`
    m2=`convertmonth $(echo $2 | sed 's/-/ /g' | awk {'print $2'})`
    y2=`echo $2 | sed 's/-/ /g' | awk {'print $3'}`
     
     
    #echo $d1" "$m1" "$y1
    #echo $d2" "$m2" "$y2
    
    if [ $y1$m1$d1 -lt $y2$m2$d2 ]
    then
	
	echo "A new upgrade is available for your system !"
    
    elif [ $y1$m1$d1 -gt $y2$m2$d2 ]
    then
    
	echo "You're going to revert your system to a previous version of the os !"
	
    elif [ $y1$m1$d1 -eq $y2$m2$d2 ]
    then
	
	echo "Your system is up-to-date !"
	
    fi

}

verifyupgrade_old () {

    if [ $dateonboard!=$datelatest ]
    then
	
	infos
	
	echo "A new upgrade is available for your system ?"
    
    else
    
	echo "Your system is up-to-date !"
	exit 0
	
    fi

}

download () {

    if [ ! -e $1 ]
    then
	
	wget http://download.linino.org/linino_distro/$2/$3/$1
    
    fi
   
    if [ $? -eq 1 ]
    then
	echo "Download failed !"
	exit 0
    fi
	
}

hashsum () {
    
    echo ""
    echo "Calculating MD5 checksums..."
    echo ""

    wget -q -O - http://download.linino.org/linino_distro/$2/$3/md5sums | grep $1 > lininosum_$4
    
    md5sum -c lininosum_$4
    
    flashimage=$1
    hashfile=lininosum_$4
    
    if [ $? -eq 1 ]
    then
	echo "md5sum mismatch ! Aborting process !"
	exit 0
    else
	systemupgrade $flashimage $hashfile
    fi

}

systemupgrade () {
    
    #echo ""
    #echo $(pwd)
    #echo $1
    #echo $2
    #echo ""
    
    while [ "$done" != "true" ]

    do

	echo ""
	echo "1. Upgrade with backup of configuration"
	echo "2. Upgrade and revert to default settings"
	echo "0. Exit"
	    
	echo " "
	echo "Choose : "
	echo " "
    
	read choice
	
	    case $choice in
		  #------------------Choice-1----------------------
		  1) 
			done="true"
			#echo "normal upgrade"
			sysupgrade -v $1
		  ;;

		  #------------------Choice-2----------------------
		  2)
			done="true"
			#echo "total upgrade"
			sysupgrade -v -n $1
		  ;;
		  
		  #------------------Choice-0----------------------
		  0)
			done="true"
			echo ""
			echo "Aborting and deleting files..."
			
			if [ -e $1 ]
			then
			
			    rm $1
			
			fi
			
			if [ -e $2 ]
			then
			
			    rm $2
			
			fi
			
			exit 0
		  ;;
		  #------------------Choice-any----------------------
		  *)
			echo ""boardavailable
			echo "You have to make a choice !"
			echo ""
		  ;; 
			    
	    esac
	
    done
		      
}



checkarguments $1 $2

online

boardavailable

settings $1 $2

templateimage $boardname $1

echo ""
echo $template

verifyupgrade $dateonboard $datelatest

p=1

while [ $p != 0 ]
do
    
    echo ""
    echo "Do you want to upgrade your board now ? (y/n)"
    echo ""
    
    read YN
    
    case $YN in
	  [yY]*)
		echo ""
		echo "Upgrading system...."
		echo ""
		
		cd /tmp
		
		download $template $1 $2
		
		sleep 2
		
		hashsum $template $1 $2 $boardname
		
		sleep 2
		
		p=0
		exit 0
	  ;;	  
	  [nN]*) 	
		echo ""
		echo "Good Bye for now...."
		echo ""
		
		p=0
		exit 0				    
	  ;;
	  *)
		echo ""
		echo "You have to make a choice !"
		echo ""
	  ;;
	  
    esac
    
done
