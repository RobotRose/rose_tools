#!/usr/bin/env sh

# To be sure we have colorize in the PATH
export PATH="$ROSE_TOOLS/scripts:$PATH"
KINECT_SERIAL=$1

pushd .

echo "Symlinking calibration data from git to .ros" | colorize BLUE
mkdir -p ~/.ros/camera_info
cd ~/.ros/camera_info
ln -s `rospack find rose_config`/kinect/rgb_${KINECT_SERIAL}.yaml rgb_${KINECT_SERIAL}.yaml
ln -s `rospack find rose_config`/kinect/depth_${KINECT_SERIAL}.yaml depth_${KINECT_SERIAL}.yaml

popd . 

echo "Kinect '${KINECT_SERIAL}' succesfully configured on this computer" | colorize GREEN