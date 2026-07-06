# How to use Turtlebot3 and simple demo

This is a quick start guide for the MAAS Laboratory in how to setup a pre-assembled (with software already installed) Turtlebot3.
This will show how to get it connected to the terminal and Matlab/Simulink.


## Setup
###  Turtlebot Raspberry Pi Setup (where firmware is already installed)

You have to set up the raspberry pi within the robot. 
1. Turn it on with the blue OpenCR circuit board switch
2. Enter username (ubuntu) and password (turtlebot)
   
> [it will not show the password when you type]
   
3. Then put the following code
   
       roslaunch turtlebot3_bringup turtlebot3_robot.launch
   
5. Once entered you should see a lot of things loaded and it should end with

       Calibration End
   

### Ubuntu Setup (The Victus laptop was used in this with ROS1 already installed)

1. In a terminal enter

        roscore

2. In anothter new terminal window enter [ssh ubuntu@ROBOT_IP]
      - In this case the ROBOT_IP is 192.168.0.200  

        ssh ubuntu@192.168.0.200  

4. The password is

        turtlebot
5. Set up the environment by entering
   
        source /opt/ros/noetic/setup.bash
   
6. Check if robot is connected enter the following and it should show a list of topics such as /cmd, /odom, etc.

       rostopic list


> (You can skip to the Matlab/Simulink Setup, the following is showing how you can control the robot throug the Ubuntu terminal)


 To see data from robot from a given topic (ie. /odom):
      
       
       rostopic echo /[add topic name here]
       
       
 To command robot to move forward (change numbers in the [] as needed):
      
      
      
      rostopic pub /cmd_vel geometry_msgs/Twist -r 10 -- '[0.3, 0.0, 0.0]' '[0.0, 0.0, -0.9]' 
      #or 
      rostopic pub /cmd_vel geometry_msgs/Twist "linear:
        x: 0.05        # keep it slow, default max is 0.22 m/s
        y: 0.0
        z: 0.0
      angular:
        x: 0.0
        y: 0.0
        z: 0.0" -r 10
      
 
 -----------------------------------------------------------------------------------------------------------
### Matlab/Simulink Setup
 1. Open a new terminal open Matlab

    /usr/local/MATLAB/R2026a/bin/matlab

 2. In Matlab Command Window initialize the Robot conneciton

   ``` 
   % Initialize connection between turtlebot BigMac with matlab:
   setenv('ROS_MASTER_URI', 'http://192.168.0.200:11311')  % robot = master
   setenv('ROS_IP', '192.168.0.165')                        % laptop's own IP
   setenv('ROS_HOSTNAME', '192.168.0.165')
   rosinit('http://192.168.0.200:11311', 'NodeHost', '192.168.0.165')
   ```

 3. Check connection by seeing the topic list

      rostopic list

 > The robot is ready to be used for Simulink and the Simple Demo. The following can be skipped.

   To see data from robot:
    
    rostopic echo /[add topic name here]
   
   To download any add on you need to open matlab like this:
   
      sudo /usr/local/MATLAB/R2026a/bin/matlab
   
   To get into Tinotenda's folder:
   
      cd("/home/linuxpc/Downloads/Summer2026-Simulation-main/matlab-simulink")
      

## Simple Demo 
You would need the following add-on installed

    - ROS Toolbox
    - Robotics System Toolbox
    - Simulink Coder
    - MATLAB Coder

> If an add-on needs to be installed, open Matlab with sudo /usr/local/MATLAB/R2026a/bin/matlab instead and install the add-on then re-open the program.





The following lets you control the Robot's movement.
<img width="1459" height="400" alt="Screenshot from 2026-07-06 13-06-04" src="https://github.com/user-attachments/assets/ba75af0e-42b7-486f-978a-3a3b9d2f015b" />





The following lets you see the robot detecting its own position. While the project is running double click into the XY Graph block or look into the scope to see its speed in the linear x direction.
<img width="1695" height="962" alt="Screenshot from 2026-07-06 13-11-55" src="https://github.com/user-attachments/assets/6c48e625-68fb-45f8-92da-abb2017bc153" />


Make sure the Stop Time is inf if you want it to go on forever or until you press stop.






   
    
