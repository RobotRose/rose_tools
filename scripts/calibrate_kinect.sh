#!/usr/bin/env sh

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

CROSSINGS=$1
SQUARESIZE=$2
KINECT_SERIAL=$3

pushd .

echo "Starting Kinect calibration." | colorize BLUE
echo "Connect the Kinect to calibrate to your local PC via USB. Then, run $ roslaunch openni_launch openni.launch #in a separate terminal and press <enter> here when done" | colorize BLUE
read -n1
echo "Starting calibration. When the calibration window appears, move the checkboard around, through every angle, distance and position visible to the kinect" | colorize YELLOW
echo "Once the bars in the right of the window are all green, click the 'Calibrate' button. This starts a lengthy calculation" | colorize YELLOW
echo "When satisfied with the result, click 'Save'." | colorize YELLOW #When Save is clicked, the terminal prints the save location, e.g. /tmp/calibrationdata.tar.gz
echo "Finally, click 'Commit'" | colorize YELLOW

rosrun camera_calibration cameracalibrator.py image:=/camera/rgb/image_raw camera:=/camera/rgb --size ${CROSSINGS} --square ${SQUARESIZE}

if [ $? -eq 0 ]; then
    echo "Calibration ran successfuly" | colorize GREEN
else
    echo "Calibration failed" | colorize RED
    exit 1
fi

if [ -f $SAVEFILE1 ]; then
    echo "Calibration window saved its data to ${SAVEFILE1}" | colorize GREEN
else
    echo "Calibration should be saved to ${SAVEFILE1} but file does not exist" | colorize RED
    exit 1
fi

SAVEFILE1=/tmp/calibrationdata.tar.gz
echo "Unpacking calibration file..." | colorize BLUE
mkdir -p ~/.ros/calibation_rgb
cd ~/.ros/calibation_rgb
tar zxfv ${SAVEFILE1}

echo "Renaming file to .ini" | colorize BLUE
mv ost.txt ost.ini #Rename the file

echo "Converting .ini to Kinect yaml calibration file" | colorize BLUE
rosrun camera_calibration_parsers convert ost.ini `rospack find rose_config`/kinect/rgb_${KINECT_SERIAL}.yaml
if [ $? -eq 0 ]; then
    echo "Conversion successful" | colorize GREEN
else
    echo "Conversion failed" | colorize RED
    exit 1
fi

#Repeat for IR sensor

echo "Now block off the IR projector and relaunch $ roslaunch openni_launch openni.launch #in a separate terminal and press <enter> here when done" | colorize YELLOW
read -n1
echo "Starting calibration. When the calibration window appears, move the checkboard around, through every angle, distance and position visible to the kinect" | colorize YELLOW
echo "Once the bars in the right of the window are all green, click the 'Calibrate' button. This starts a lengthy calculation" | colorize YELLOW
echo "When satisfied with the result, click 'Save'." | colorize YELLOW #When Save is clicked, the terminal prints the save location, e.g. /tmp/calibrationdata.tar.gz
echo "Finally, click 'Commit'" | colorize YELLOW
rosrun camera_calibration cameracalibrator.py image:=/camera/ir/image_raw camera:=/camera/ir --size ${CROSSINGS} --square ${SQUARESIZE}
if [ $? -eq 0 ]; then
    echo "Calibration ran successfuly" | colorize GREEN
else
    echo "Calibration failed" | colorize RED
    exit 1
fi

SAVEFILE2=/tmp/calibrationdata.tar.gz

if [ -f $SAVEFILE2 ]; then
    echo "Calibration window saved to ${SAVEFILE}" | colorize GREEN
else
    echo "Calibration should be saved to ${SAVEFILE} but file does not exist" | colorize RED
    exit 1
fi

echo "Unpacking calibration file..." | colorize BLUE
mkdir -p ~/.ros/calibation_ir
cd ~/.ros/calibation_ir
tar zxfv ${SAVEFILE2}

echo "Renaming file to .ini" | colorize BLUE
mv ost.txt ost.ini #Rename the file

echo "Converting .ini to Kinect yaml calibration file" | colorize BLUE
rosrun camera_calibration_parsers convert ost.ini `rospack find rose_config`/kinect/depth_${KINECT_SERIAL}.yaml
if [ $? -eq 0 ]; then
    echo "Conversion successful" | colorize GREEN
else
    echo "Conversion failed" | colorize RED
    exit 1
fi

roscd rose_config
git add `rospack find rose_config`/kinect/rgb_${KINECT_SERIAL}.yaml `rospack find rose_config`/kinect/depth_${KINECT_SERIAL}.yaml
git commit `rospack find rose_config`/kinect/rgb_${KINECT_SERIAL}.yaml `rospack find rose_config`/kinect/depth_${KINECT_SERIAL}.yaml -m "Added Kinect calibration data for ${KINECT_SERIAL}"
echo "Committed calibration to GIT" | colorize GREEN

popd

echo "Calibration of RGB and IR camera was successful. " | colorize GREEN
echo "Next, git push the calibration files, connect the Kinect back to the rosepc1 and run $ source $ROSE_TOOLS/scripts/setup_kinect.sh ${KINECT_SERIAL}" | colorize YELLOW