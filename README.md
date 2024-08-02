# FluidPlatfomerController
A feature full and configurable platformer movement controller for Godot 4.3 +

## What can this controller do?
- Standard Movement
- Dashing
- Double Jumps
- Wall Jumping
- Wall and Ceiling Climbing
- Wall Sliding

## Extra Features
- Coyote Time
- Input Buffering
- Peak Gravity Multiplication
- Corner Correction

## Configure to suit your game
Almost every aspect of this controller is configurable via the supplied Config class. 
All movement settings can be toggled and tweaked. 
The nodes generated to handle motion can also be replaced with your own

## React to locomotion
The controller provides a number of signals to connect your animations, sound effects etc.
This enables the controller to handle everything to do with motion, and allows you to react with ease.

## How do I use it?
You will need to download the scripts and place them somewhere in your project, this isn't set up as a plugin, so this can be where you please as long as it is in the `res://` folder somewhere.
Then, for the most basic usage, just attach the Platformer Controller.
![image](https://github.com/user-attachments/assets/ca01bcf7-c8a3-4bec-9531-4a02051f8d1a)

## Configuring the Controller
To configure the controller, you can click the node in the scene tree, and then in the inspector, add a new config.
![image](https://github.com/user-attachments/assets/63fe5c8b-d1ce-467e-b31f-4e80ff0ebe3c)

Once you have added the config, you will see a number of settings that you can tweak too your hearts content.
![image](https://github.com/user-attachments/assets/8b45403f-e51f-4b92-b00a-3dbf0e4d568e)

