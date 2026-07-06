# Physical Robotic Bridge Model Progress

This is documentation for how we went about uploading the predetermined command velocities for the robot. 
We used the turtlebot_odomtest.slx project instead. It was easier to debug and get it to work at the simplest model. 


From a given csv file that has a list of velocities and angular velocities, we can recreate the predetermined path.



## How to use turtlebot_odomtest.slx project
Please read "How to use turtlebot3 and simple demo" before attempting here on forward.

The parameters need to be set first and the list of linear/angular velocities need to be obtained from the csv file before the project can be used. 

1. Set the right simulation parameters
   - This can be set in Simulink or just enter the following in the Matlab terminal


   ```
      %makes sure that simulink is talking to the robot at the correct rate
      set_param(gcs, 'EnablePacing', 'on')
      set_param(gcs, 'PacingRate', '1')
      set_param(gcs, 'SolverType', 'Fixed-step')
      set_param(gcs, 'FixedStep', '0.1')
   ```

2. Obtain the linear/angular velocities from the csv file
   - After the robot is initialized in matlab, go to the following directory. This gives us access to the csv file we need from the project. 
     
      ```
      cd("/home/linuxpc/Downloads/Summer2026-Simulation-main/matlab-simulink/physics-robot-bridge-model/outputs");
      ```

      
   - Paste the following code in the matlab terminal to enter the linear velocity list in the workspace.

     ```
      % collects colum of linear velocities and makes it run much more evenly
      T = readtable('stage12_turtle_cmd_vel_schedule.csv');
      velocities = T{1:1:end, 'linear_velocity_mps'} / 3.6;   % every other row, m/s
      % Build a proper evenly spaced time vector
      dt = 95.4 / (length(velocities) - 1);
      time_base = (0:dt:95.4)';
      vel_ts = timeseries(velocities, time_base);
     
     ```


    - Paste the following code in the matlab terminal to enter the linear velocity list in the workspace.
      
      ```
      %for angular velocity
      T = readtable('stage12_turtle_cmd_vel_schedule.csv');
      ang_velocities = T{1:1:end, 'angular_velocity_radps'};   % every other row, m/s
      % Build a proper evenly spaced time vector
      dt = 95.4 / (length(ang_velocities) - 1);
      time_base = (0:dt:95.4)';
      ang_vel_ts = timeseries(ang_velocities, time_base);
      ```
You should have the following in the matlab window.
<img width="1791" height="957" alt="matlab_robotbridgemodel_terminal" src="https://github.com/user-attachments/assets/3d58dcb4-f4c1-4bf6-a7d1-3eb005bfd00e" />



3. Open the simulink file turtlebot_odomtest.slx
    - It may show a warning sign in the vel_ts and ang_vel_ts from workspace blocks. If so click the warning sign label above it and press fix. It just needed to refresh and see the data that was uploaded in the workspace.
   <img width="732" height="657" alt="matlab_robotbridgemodel_simulink_error" src="https://github.com/user-attachments/assets/7f10842d-e472-4d25-8a70-b910a2650e36" />


    - Place the robot on the ground in an open space
    - Set Run time to inf or 94.5
    - Press Run and the robot should be able to follow the set path
      > The error should not be on vel_ts and ang_vel_ts. This is just an image to give an idea of what the workflow should look like.
   

   <img width="1690" height="755" alt="matlab_robotbridgemodel_simulink_workflow" src="https://github.com/user-attachments/assets/369082dc-b7f8-4ed2-8455-6348ce344ffe" />


4. Seeing the path through the odometry
     - The robot can measure its own position and velocity.
       > Fun fact: It does this through the combination of IMU for its angle and the encoders within both of its wheels :)
       <img width="1127" height="540" alt="matlab_robotbridgemodel_simulink_odom" src="https://github.com/user-attachments/assets/179acf65-4c87-4b10-92d2-bd105ee63f9f" />

      - Click on the XY graph and you should see its path

YAY! it should work, if not I will add a troubleshooting file to help understand how to pinpoint where the issue may be in recreating the project. 


## What does each block do?
   To recreate or customize your own you need to understand the ROS blocks and input function.

   - ROS Blocks:
        * Subscriber
        * Publisher
        * Bus Assignment
        * Blank Message
   - Input Function Blocks:
        * From Workspace
        * Matlab Function
        * [that one weird block I forgot the name off. Bea please look it up again when rewriting this]
        
      

   


     
   
   
