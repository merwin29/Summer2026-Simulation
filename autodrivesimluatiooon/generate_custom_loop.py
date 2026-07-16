import pandas as pd
import numpy as np
import os

# Parameters for the 8-segment octagon loop
dt = 0.1  # 10 Hz time steps

# Adjust these to control the size and shape of the loop
drive_speed = 1.0       # Forward speed (m/s)
drive_duration = 6.0    # Time spent driving straight per segment (seconds)

stop_duration = 0.0     # Time spent stopped before and after turns (seconds)

# To turn exactly 45 degrees (pi/4 radians = ~0.7854 rad) in 10 seconds:
# Angular velocity = 0.7854 / 10.0 = 0.07854 rad/s
turn_duration = 20.0     # Time spent turning on the spot (seconds)
turn_speed = 0.15   # Angular velocity during turn (rad/s)

# We will generate 8 segments to complete a closed loop (360 degrees)
num_segments = 8

time_s = 0.0
data = []

current_heading = 0.0

for segment in range(1, num_segments + 1):
    # 1. Drive Phase
    num_drive_steps = int(drive_duration / dt)
    for _ in range(num_drive_steps):
        data.append({
            'time_s': round(time_s, 2),
            'command_phase': 'drive',
            'segmentId': segment,
            'linear_velocity_mps': drive_speed,
            'angular_velocity_radps': 0.0,
            'target_heading_rad': current_heading,
            'grade_pct': 0,
            'ros_topic': '/cmd_vel'
        })
        time_s += dt
        
    # 2. Stop before turn
    num_stop_steps = int(stop_duration / dt)
    for _ in range(num_stop_steps):
        data.append({
            'time_s': round(time_s, 2),
            'command_phase': 'stop',
            'segmentId': segment,
            'linear_velocity_mps': 0.0,
            'angular_velocity_radps': 0.0,
            'target_heading_rad': current_heading,
            'grade_pct': 0,
            'ros_topic': '/cmd_vel'
        })
        time_s += dt

    # 3. Turn Phase (turn left by 45 degrees)
    num_turn_steps = int(turn_duration / dt)
    for _ in range(num_turn_steps):
        data.append({
            'time_s': round(time_s, 2),
            'command_phase': 'turn',
            'segmentId': segment,
            'linear_velocity_mps': drive_speed,
            'angular_velocity_radps': turn_speed,
            'target_heading_rad': current_heading + (turn_speed * (time_s - (time_s - dt))),
            'grade_pct': 0,
            'ros_topic': '/cmd_vel'
        })
        time_s += dt
    current_heading += (turn_speed * turn_duration)

    # 4. Stop after turn
    for _ in range(num_stop_steps):
        data.append({
            'time_s': round(time_s, 2),
            'command_phase': 'stop',
            'segmentId': segment,
            'linear_velocity_mps': 0.0,
            'angular_velocity_radps': 0.0,
            'target_heading_rad': current_heading,
            'grade_pct': 0,
            'ros_topic': '/cmd_vel'
        })
        time_s += dt

# Final stop to settle the robot
for _ in range(int(3.0 / dt)):
    data.append({
        'time_s': round(time_s, 2),
        'command_phase': 'stop',
        'segmentId': num_segments,
        'linear_velocity_mps': 0.0,
        'angular_velocity_radps': 0.0,
        'target_heading_rad': current_heading,
        'grade_pct': 0,
        'ros_topic': '/cmd_vel'
    })
    time_s += dt

# Convert to DataFrame and save to the outputs folder
df = pd.DataFrame(data)
output_path = r'C:\Users\merwinmendoza\Downloads\Summer2026-Simulation-main\Summer2026-Simulation-main\matlab-simulink\physics-robot-bridge-model\outputs\stage12_turtle_cmd_vel_schedule.csv'

# Ensure parent directory exists
os.makedirs(os.path.dirname(output_path), exist_ok=True)
df.to_csv(output_path, index=False)

print(f"Generated custom 8-segment loop trajectory at: {output_path}")
print(f"Total duration: {round(time_s, 2)} seconds.")
