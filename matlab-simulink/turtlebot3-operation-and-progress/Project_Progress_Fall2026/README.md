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
   Run the .m file you need or just copy and paste the contents of the file in the terminal.

   
You should have vel_ts and ang_vel_ts in your workspace
<img width="1791" height="957" alt="matlab_robotbridgemodel_terminal" src="https://github.com/user-attachments/assets/3d58dcb4-f4c1-4bf6-a7d1-3eb005bfd00e" />



4. Open the simulink file turtlebot_odomtest.slx
    - It may show a warning sign in the vel_ts and ang_vel_ts from workspace blocks. If so click the warning sign label above it and press fix. It just needed to refresh and see the data that was uploaded in the workspace.
   <img width="732" height="657" alt="matlab_robotbridgemodel_simulink_error" src="https://github.com/user-attachments/assets/7f10842d-e472-4d25-8a70-b910a2650e36" />


    - Place the robot on the ground in an open space
    - Set Run time to inf or 94.5
    - Press Run and the robot should be able to follow the set path
      > The error should not be on vel_ts and ang_vel_ts. This is just an image to give an idea of what the workflow should look like.
   

   <img width="1690" height="755" alt="matlab_robotbridgemodel_simulink_workflow" src="https://github.com/user-attachments/assets/369082dc-b7f8-4ed2-8455-6348ce344ffe" />


5. Seeing the path through the odometry
     - The robot can measure its own position and velocity.
       > Fun fact: It does this through the combination of IMU for its angle and the encoders within both of its wheels :)
       <img width="1127" height="540" alt="matlab_robotbridgemodel_simulink_odom" src="https://github.com/user-attachments/assets/179acf65-4c87-4b10-92d2-bd105ee63f9f" />

      - Click on the XY graph and you should see its path

      

   


     
   
   
