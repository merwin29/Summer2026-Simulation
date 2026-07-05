# How to use Turtlebot3 and simple demo

This is a quick start guide for the MAAS Laboratory in how to setup a pre-assembled (with software already installed) Turtlebot3.
This will show how to get it connected to the terminal and Matlab/Simulink.


## Setup
###  Turtlebot Raspberry Pi Setup (where firmware is already installed)

You have to set up the raspberry pi within the robot. 
1. Turn it on with the blue OpenCR circuit board switch
2. Enter username (ubuntu) and password (turtlebot)
   
       [it will not show the password when you type]
   
3. then put the following code
   
       [Bea put code here]
   
5. Once entered you should see a lot of things loaded and it should end with

       Calibration End
   

### Ubuntu Setup (Victus was used in this with ROS1 already installed)

1. In a terminal

        roscore

2. In anothter new terminal window

        ssh 192.165.0.200 [Bea check that this is the correct IP address]

3. The password is

        turtlebot
   
5. Check if robot is connected enter the following and it should show a list of topics such as /cmd, /odom, etc.

       rostopic list
   
### Matlab/Simulink Setup
1. Initialized Robot
2. Check with rostopic list
3. Now you should be able to use the robot

##Simple Demo 
You would need the following libraries installed

    ROS toolbox
    [Bea check if it was simulink encoder or matlab encoder]
    
If you want an already made simulink project, open turtlebot_test0.slx and make sure stop time is inf.



If you need to make your own project use simulink boxes like the following
[Bea add that here]






   
    
