# SWARM_PROJECT
==============================

First step :
-------------
Download all files and make sure all files are be present in a same folder. You need to have argos in your computer, if it's not the case, you can dowload it here : https://www.argos-sim.info/download.php


Launch the Lua process :
-------------
The name of manual_solution.lua is actually writing in the decision-making-modife.argos file. So if you want to launch it, you need to launch a terminal in the folder where all files are be present, and write the next command : "argos3 -c decision-making-modifie.argos". If you want to modified any value of parameters you need to do manually.


Launch the PSO process :
-------------
You need to have all files in a the same folder. The aim function are present in PSO.py. It's possible to launch it if you open a terminal in the folder with all files and write the next command : "python3 PSO.py". If you want to modified any value of parameters you need to do manually.


Items
------------
~~~~
├── interface.py : files with all definitions to make a bridge between the PSO algorithm, ARGOS file and Lua file. 
├──PSO.py : files with all definitions contains in different originals files from the course on PSO optimisation.
├──passerelle.argos : reworked file of the robotics part to make PSO worked.
├── decision-making-modifie.argos : file to launch without visualisation Lua file.
├──manual_solution.lua : original file of the robotics part
└──pso_solution_template.lua : reworked file of the robotics part
