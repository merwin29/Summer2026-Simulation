# Physical Robotic Bridge Model Progress

This is documentation for how we went about uploading the predetermined command velocities for the robot. 
We used the turtlebot_odomtest.slx project instead. It was easier to debug and get it to work at the simplest model. 


From a given csv file that has a list of velocities and angular velocities, we can recreate the predetermined path.



## How to use turtlebot_odomtest.slx project
Please read "How to use turtlebot3 and simple demo" before attempting here on forward.

The parameters need to be set first and the list of linear/angular velocities need to be obtained from the csv file before the project can be used. 

1. Set the right simulation parameters
   - This can be set in Simulink or just enter the following in the Matlab terminal
            set_param(gcs, 'EnablePacing', 'on')
             set_param(gcs, 'PacingRate', '1')
set_param(gcs, 'SolverType', 'Fixed-step')
set_param(gcs, 'FixedStep', '0.1')



