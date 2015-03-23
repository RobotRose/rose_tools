#!/bin/bash

function resource {
	source ~/.bashrc
}

alias sshrosepc1="ssh -X rose@rosepc1"
alias sshrosepc2="ssh -X rose@rosepc2"
alias rviz="rosrun rviz rviz"

alias view_camera="rosrun image_view image_view image:=/camera/rgb/image_color _image_transport:=theora"
alias tf='cd /var/tmp && rosrun tf view_frames && evince frames.pdf &'

alias body='echo "Use bodyXX (for example body20)"'
alias body21='roslaunch rose21_platform body.launch hardware:="rose21" 2>&1 | grep -v "\[pcl::"' #ignoring irrelevant PCL errors
alias platform='echo "Use platformXX (for example platform20)"'
alias platform21='roslaunch rose21_platform platform.launch hardware:="rose21"'

alias gui="roslaunch rose_gui_application ui.launch"
alias app="roslaunch rose_gui_application application.launch"
alias arms="roslaunch arm_controller arm_controller.launch"

# Notifications in ubuntu
alias alert_helper='history|tail -n1|sed -e "s/^\s*[0-9]\+\s*//" -e "s/;\s*alert$//"'
alias alert='notify-send -i /usr/share/icons/gnome/32x32/apps/gnome-terminal.png "[$?] $(alert_helper)"'
alias notify_done='alert "Done" &'
alias notify_failed='alert "Failed" &'

function gitff {
	git fetch && git pull --ff --ff-only origin $(git rev-parse --abbrev-ref HEAD)
}

function git-update-all {
    # Check if wstool is installed
    wstool 2>&1 1> /dev/null

    if [ $? == 127 ]; then
        echo "Installing wstool." | colorize BLUE
        sudo apt-get install -y --force-yes python-wstool 

        if [ $? != 0 ]; then
        	echo "Could not install wstool, aborting." | colorize RED
        	exit 1
        fi

    fi

    # Check if there are changes made to the repositories
    ${ROSE_TOOLS}/scripts/check_repository_state.sh
	changed=$?

	if [ "$changed" == "1" ]; then
		echo "There are changes detected, are you sure you want to continue running git-update-all?" | colorize RED
		select yn in "Yes" "No"; do
		    case $yn in
		        Yes ) echo "Continuing with git-update-all." | colorize BLUE; break;;
		        No ) return;;
		    esac
		done
	else
		echo "No changes detected, continuing with git-update-all..." | colorize GREEN
	fi

	pushd . 2>&1 1> /dev/null

	cd ${ROSE_TOOLS} && gitff ;
	cd ${ROSE_CONFIG} && gitff ;
    wstool update --target-workspace=$ROSINSTALL_ROOT --parallel=50

	popd 2>&1 1> /dev/null
}

# Short for git fetch
function gitf {
	git fetch
}

# Short for git mergetool -t xxdiff
function gitm {
	git mergetool -t xxdiff
}

function rose-core {
    #Get the IP you use for VPN:
    local vpn_ip=$(ifconfig tap0 | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}')
    if [ "$vpn_ip" == "" ]; then
        echo -e "\e[31mAre you only VPN? Cannot find tap0 in ifconfig. Aborting, leaving you on local-core\e[0m"
    else
        source ${ROSE_TOOLS}/scripts/setup_ROS.sh "/opt/ros/hydro/" "$vpn_ip" "http://10.8.0.1:11311"
    fi
}

function local-core {
    source ${ROSE_TOOLS}/scripts/setup_ROS.sh "/opt/ros/hydro/" "127.0.0.1" "http://localhost:11311"
}

function speech_report {
    if [ "$?" = 0 ]; then
        espeak "OK $1" 2> /dev/null > /dev/null
    else
        espeak "Error $2" 2> /dev/null > /dev/null
    fi
}

function vpn {
	sudo ${ROSE_TOOLS}/scripts/select_vpn.sh $1
}

function deploy {
	source ${ROSE_TOOLS}/scripts/install_deployment.sh
}

function source-deployment {
	${ROSE_TOOLS}/scripts/source_deployment.sh
}

function update-rosinstall {
	${ROSE_TOOLS}/scripts/update_rosinstall.sh
}

function update-workspaces {
	${ROSE_TOOLS}/scripts/update_workspaces.sh
}

function cdws {
	cd `get-workspace-path $1`
}

function timing {
	if [ "$1" == "catkin_make" ]; then
		TIMEFILE="$HOME/logging/cm_timing_$USER.log"
	else
		TIMEFILE="$HOME/$1_timing_$USER.log"
	fi
	echo "Timing command '$1', logging at file '${TIMEFILE}'"

	touch ${TIMEFILE}
	
	#Format:
	# date YY-MM_DD, TIME HH:MM:SS, nanoseconds, username, hostname, dir, command, exit state, user time, system time, real time, filesys inputs, filesys outputs
	fmt="$(date +"%Y-%m-%d, %H:%M:%S, %N"), $USER, $(hostname), $(pwd), %C, %x, %U, %S, %e, %I, %O"
	/usr/bin/time -f "$fmt" --quiet -o "${TIMEFILE}" -a "$@"
}

function get-all-workspace-paths {
	if [ -f ${WORKSPACES_FILE} ]; then
		# Return path with ordered by build order
		cat ${REPOS_ROOT}/.workspaces_build_order | cut -d ':' -f 3
	fi
}

function get-workspace-path {
	if [ "$#" = 0 ]; then
		pwd
		return
  	fi

	for ws in $(cat ${WORKSPACES_FILE})
	do
		# Find workspace
		MATCH_CNT=$(cat ${WORKSPACES_FILE} | grep -c $1)
		if [ "$MATCH_CNT" -gt "0" ]; then
			echo "${REPOS_ROOT}/$(cat ${WORKSPACES_FILE} | grep $1 | sed -n 1p)"
			return 
		fi
	done

	pwd
	return
}

function get-workspace-build-order-name {
	cat ${REPOS_ROOT}/.workspaces_build_order | cut -d ':' -f 1,2
}

function get-workspace-build-order-path {
	cat ${REPOS_ROOT}/.workspaces_build_order | cut -d ':' -f 1,3
}

function cm {
	pushd . > /dev/null 2>&1
	
	# To keep track of the workspaces that are built
	failed_workspaces=()
	successful_workspaces=()

  	if [ "$#" = 0 ]; then
  		ws=`pwd`
  		echo "Building current workspace $ws" | colorize BLUE
  		catkin_make
  		if [ $? -ne 0 ]
		then
			failed_workspaces+=( $(get-workspace-path $var) )
		else
			successful_workspaces+=( $(get-workspace-path $var) )
		fi
  	else
	  	if [ "$1" = "all" ]; then
	  		echo "Building all workspaces" | colorize BLUE
	  		for ws in `get-all-workspace-paths`
	  		do
	  			cd $ws && catkin_make
	  			if [ $? -ne 0 ]
	  			then
	  				failed_workspaces+=( $(get-workspace-path $var) )
	  			else
	  				successful_workspaces+=( $(get-workspace-path $var) )
	  			fi
	  		done
	  	else
			for var	do
			    echo "Building $var..." | colorize BLUE
			    cdws $var && catkin_make
			    
			    if [ $? -ne 0 ]
			    then
	  				failed_workspaces+=( $(get-workspace-path $var) )
	  			else
	  				successful_workspaces+=( $(get-workspace-path $var) )
	  			fi
			done
		fi
	fi

	# Execute the successful and unsuccessful workspaces
	echo "Build summary:" 		| colorize YELLOW
	for bws in "${successful_workspaces[@]}"
	do
		echo "  $bws built succesfully" | colorize GREEN
	done

	for bws in "${failed_workspaces[@]}"
	do
		echo "! $bws build failed" | colorize RED
	done

	notify_done
	popd > /dev/null 2>&1
	return
}

function cm-clean {
	pushd . > /dev/null 2>&1 
  	if [ "$#" = 0 ]; then
  		rm -rf build devel && catkin_make
  	else
	  	if [ "$1" = "all" ]; then
	  		echo "Clearing all build and devel folders" | colorize BLUE
	  		for ws in `get-all-workspace-paths`
	  		do
	  			cd $ws && rm -rf build devel
	  		done
	  		cm all
	  	else
	  		# search for var in ws-file
			for var	do
				echo "Clearing all build and devel folder for $var" | colorize BLUE
			    cdws $var && rm -rf build devel
			    cm $var
			done
		fi
	fi
	notify_done
	popd > /dev/null 2>&1
}

function mergeclean {
	pushd . > /dev/null 2>&1 
	cd ~/git/rose2_0
	for file in `find . -name *.orig -type f -print`
	do
	   echo "Deleting file $file"
	   rm $file -f       
	done
	popd > /dev/null 2>&1
}

function send_command_to_all_pcs {
	if [[ -z "$1" ]]; then
		echo "No argument given" | colorize RED
		return
	fi

	echo 'Executing "'$1'" on rosepc2...' | colorize BLUE
	ssh -t rose@rosepc2 $1

	if [ $? -eq 255 ] ; then
		echo "Could not reach rosepc2, do you want to send the command to rosepc1?" | colorize RED
		select yn in "Yes" "No"; do
		    case $yn in
		        Yes ) break;;
		        No ) return;;
		    esac
		done
	fi

	echo 'Executing "'$1'" on rosepc1...' | colorize BLUE
	ssh -t rose@rosepc1 $1

	if [ $? -eq 255 ] ; then
		echo "Could not reach rosepc1." | colorize RED
		return
	fi

	echo 'Succes!' | colorize GREEN
	return
}

function rose-shutdown {
	send_command_to_all_pcs "sudo halt -p"
}

function rose-restart {
	send_command_to_all_pcs "sudo reboot"
}

# beep sounds
alias beep-enable="sudo modprobe pcspkr"
alias beep-aerodynamic="beep-enable && beep -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 && beep -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 370 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 587.3 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 415.3 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 784 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 493.9 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 659.3 -l 122 -d 0 -n -f 440 -l 122 -d 0 -n -f 554.4 -l 122 -d 0 -n -f 440 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 && beep -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 740 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1174.7 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 830.6 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1568 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 987.8 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1318.5 -l 122 -d 0 -n -f 880 -l 122 -d 0 -n -f 1108.7 -l 122 -d 0 -n -f 880 -l 122 -d 0"
alias beep-axel-f="beep-enable && beep -f 659 -l 460 -n -f 784 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 880 -l 230 -n -f 659 -l 230 -n -f 587 -l 230 -n -f 659 -l 460 -n -f 988 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 1047-l 230 -n -f 988 -l 230 -n -f 784 -l 230 -n -f 659 -l 230 -n -f 988 -l 230 -n -f 1318 -l 230 -n -f 659 -l 110 -n -f 587 -l 230 -n -f 587 -l 110 -n -f 494 -l 230 -n -f 740 -l 230 -n -f 659 -l 460"
alias beep-star-wars="beep-enable && beep -l 350 -f 392 -D 100 -n -l 350 -f 392 -D 100 -n -l 350 -f 392 \
	-D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 -D 100 -n \
	-l 350 -f 392 -D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 \
	-D 100 -n -l 700 -f 392 -D 100 -n -l 350 -f 587.32 -D 100 -n \
	-l 350 -f 587.32 -D 100 -n -l 350 -f 587.32 -D 100 -n -l 250 \
	-f 622.26 -D 100 -n -l 25 -f 466.2 -D 100 -n -l 350 -f 369.99 \
	-D 100 -n -l 250 -f 311.1 -D 100 -n -l 25 -f 466.2 -D 100 -n \
	-l 700 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n -l 250 -f 392 \
	-D 100 -n -l 25 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n \
	-l 250 -f 739.98 -D 100 -n -l 25 -f 698.46 -D 100 -n \
	-l 25 -f 659.26 -D 100 -n -l 25 -f 622.26 -D 100 -n \
	-l 50 -f 659.26 -D 400 -n -l 25 -f 415.3 -D 200 -n \
	-l 350 -f 554.36 -D 100 -n -l 250 -f 523.25 -D 100 -n \
	-l 25 -f 493.88 -D 100 -n -l 25 -f 466.16 -D 100 -n \
	-l 25 -f 440 -D 100 -n -l 50 -f 466.16 -D 400 -n \
	-l 25 -f 311.13 -D 200 -n -l 350 -f 369.99 -D 100 -n \
	-l 250 -f 311.13 -D 100 -n -l 25 -f 392 -D 100 -n \
	-l 350 -f 466.16 -D 100 -n -l 250 -f 392 -D 100 -n \
	-l 25 -f 466.16 -D 100 -n -l 700 -f 587.32 -D 100 -n \
	-l 350 -f 784 -D 100 -n -l 250 -f 392 -D 100 -n \
	-l 25 -f 392 -D 100 -n -l 350 -f 784 -D 100 -n \
	-l 250 -f 739.98 -D 100 -n -l 25 -f 698.46 -D 100 -n \
	-l 25 -f 659.26 -D 100 -n -l 25 -f 622.26 -D 100 -n \
	-l 50 -f 659.26 -D 400 -n -l 25 -f 415.3 -D 200 -n \
	-l 350 -f 554.36 -D 100 -n -l 250 -f 523.25 -D 100 -n \
	-l 25 -f 493.88 -D 100 -n -l 25 -f 466.16 -D 100 -n \
	-l 25 -f 440 -D 100 -n -l 50 -f 466.16 -D 400 -n \
	-l 25 -f 311.13 -D 200 -n -l 350 -f 392 -D 100 -n \
	-l 250 -f 311.13 -D 100 -n -l 25 -f 466.16 -D 100 -n \
	-l 300 -f 392.00 -D 150 -n -l 250 -f 311.13 -D 100 -n"
alias beep-christmas="beep-enable &&  beep -f 200 -l 444 
	beep -f 265 -l 444
	beep -f 265 -l 222
	beep -f 295 -l 222
	beep -f 265 -l 222
	beep -f 245 -l 222
	beep -f 220 -l 444
	beep -f 220 -l 444
	beep -f 220 -l 444
	beep -f 295 -l 444
	beep -f 295 -l 222
	beep -f 330 -l 222
	beep -f 295 -l 222
	beep -f 265 -l 222
	beep -f 245 -l 444
	beep -f 200 -l 444
	beep -f 200 -l 444
	beep -f 330 -l 444
	beep -f 330 -l 222
	beep -f 345 -l 222
	beep -f 330 -l 222
	beep -f 300 -l 222
	beep -f 265 -l 444
	beep -f 220 -l 444
	beep -f 200 -l 444
	beep -f 220 -l 444
	beep -f 300 -l 444
	beep -f 245 -l 444
	beep -f 265 -l 888"
alias beep-jingle-bells="beep-enable &&  beep -f 659 -l 400
	sleep 0.05
	beep -f 659 -l 400
	sleep 0.05
	beep -f 659 -l 800
	sleep 0.05
	beep -f 659 -l 400
	sleep 0.05
	beep -f 659 -l 400
	sleep 0.05
	beep -f 659 -l 800
	sleep 0.05
	beep -f 659 -l 400
	sleep 0.05
	beep -f 783 -l 400
	sleep 0.05
	beep -f 523 -l 400
	sleep 0.05
	beep -f 587 -l 400
	sleep 0.05
	beep -f 659 -l 800"
