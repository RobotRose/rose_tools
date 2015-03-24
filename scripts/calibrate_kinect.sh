#!/usr/bin/env sh

CROSSINGS=$1
SQUARESIZE=$2
KINECT_SERIAL=$3

pushd . > /dev/null 2>&1

echo "Starting Kinect calibration." | colorize BLUE
echo "Connect the Kinect to calibrate to your local PC via USB. Then, run $ roslaunch openni_launch openni.launch #in a separate terminal and press <enter> here when done" | colorize BLUE
read -n1
echo "Starting calibration. When the calibration window appears, move the checkerboard around, through every angle, distance and position visible to the kinect" | colorize YELLOW
echo "Once the bars in the right of the window are all green, click the 'Calibrate' button. This starts a lengthy calculation" | colorize YELLOW
echo "When satisfied with the result, click 'Save'." | colorize YELLOW #When Save is clicked, the terminal prints the save location, e.g. /tmp/calibrationdata.tar.gz
echo "Finally, click 'Commit'" | colorize YELLOW
echo ""

# Check the KINECT_SERIAL storage location
CALIBRATION_STORAGE_RGB=`rospack find rose_config`/kinect/rgb_${KINECT_SERIAL}.yaml
CALIBRATION_STORAGE_DEPTH=`rospack find rose_config`/kinect/depth_${KINECT_SERIAL}.yaml

if [ -f $CALIBRATION_STORAGE_RGB ]; then
    echo "Warning a calibration file already exists at ${CALIBRATION_STORAGE_RGB}" | colorize RED
else
    echo "RGB calibration will be saved to ${CALIBRATION_STORAGE_RGB}." | colorize GREEN
fi

if [ -f $CALIBRATION_STORAGE_DEPTH ]; then
    echo "Warning a calibration file already exists at ${CALIBRATION_STORAGE_DEPTH}" | colorize RED
else
    echo "Depth calibration will be saved to ${CALIBRATION_STORAGE_DEPTH}." | colorize GREEN
fi

rosrun camera_calibration cameracalibrator.py image:=/camera/rgb/image_raw camera:=/camera/rgb --size ${CROSSINGS} --square ${SQUARESIZE}

if [ $? -eq 0 ]; then
    echo "Calibration ran successfully" | colorize GREEN
else
    echo "Calibration failed" | colorize RED
    exit 1
fi

# Check if the tool did indeed generate its calibration file
SAVEFILE1=/tmp/calibrationdata.tar.gz

if [ -f $SAVEFILE1 ]; then
    echo "Calibration window saved its data to ${SAVEFILE1}" | colorize GREEN
else
    echo "Calibration should be saved to ${SAVEFILE1} but file does not exist" | colorize RED
    exit 1
fi

echo "Unpacking RGB calibration file..." | colorize BLUE
mkdir -p ~/.ros/calibation_rgb
cd ~/.ros/calibation_rgb
tar zxfv ${SAVEFILE1}

echo "Renaming file to .ini" | colorize BLUE
mv ost.txt ost.ini #Rename the file

echo "Converting .ini to Kinect yaml calibration file" | colorize BLUE
rosrun camera_calibration_parsers convert ost.ini ${CALIBRATION_STORAGE_RGB}
if [ $? -eq 0 ]; then
    echo "Conversion successful" | colorize GREEN
else
    echo "Conversion failed" | colorize RED
    exit 1
fi

#Repeat for IR sensor

echo "Now block off the IR projector and relaunch $ roslaunch openni_launch openni.launch #in a separate terminal and press <enter> here when done" | colorize YELLOW
read -n1
echo "Starting calibration. When the calibration window appears, move the checkerboard around, through every angle, distance and position visible to the kinect" | colorize YELLOW
echo "Once the bars in the right of the window are all green, click the 'Calibrate' button. This starts a lengthy calculation" | colorize YELLOW
echo "When satisfied with the result, click 'Save'." | colorize YELLOW #When Save is clicked, the terminal prints the save location, e.g. /tmp/calibrationdata.tar.gz
echo "Finally, click 'Commit'" | colorize YELLOW

rosrun camera_calibration cameracalibrator.py image:=/camera/ir/image_raw camera:=/camera/ir --size ${CROSSINGS} --square ${SQUARESIZE}

if [ $? -eq 0 ]; then
    echo "Calibration ran successfully" | colorize GREEN
else
    echo "Calibration failed" | colorize RED
    exit 1
fi

SAVEFILE2=/tmp/calibrationdata.tar.gz

if [ -f $SAVEFILE2 ]; then
    echo "Calibration window saved to ${SAVEFILE2}" | colorize GREEN
else
    echo "Calibration should be saved to ${SAVEFILE2} but file does not exist" | colorize RED
    exit 1
fi

echo "Unpacking depth calibration file..." | colorize BLUE
mkdir -p ~/.ros/calibation_depth
cd ~/.ros/calibation_depth
tar zxfv ${SAVEFILE2}

echo "Renaming file to .ini" | colorize BLUE
mv ost.txt ost.ini #Rename the file

echo "Converting .ini to Kinect yaml calibration file" | colorize BLUE
rosrun camera_calibration_parsers convert ost.ini ${CALIBRATION_STORAGE_DEPTH}
if [ $? -eq 0 ]; then
    echo "Conversion successful" | colorize GREEN
else
    echo "Conversion failed" | colorize RED
    exit 1
fi

roscd rose_config
git add ${CALIBRATION_STORAGE_RGB} ${CALIBRATION_STORAGE_DEPTH}
git commit ${CALIBRATION_STORAGE_RGB} ${CALIBRATION_STORAGE_DEPTH} -m "Added/updated Kinect calibration data for ${KINECT_SERIAL}"
echo "Committed calibration to GIT." | colorize GREEN

popd > /dev/null 2>&1 

echo "Calibration of RGB and IR camera was successful. " | colorize GREEN
echo "Next, git push the calibration files, connect the Kinect back to the rosepc1 and run $ source $ROSE_TOOLS/scripts/setup_kinect.sh ${KINECT_SERIAL}" | colorize YELLOW
