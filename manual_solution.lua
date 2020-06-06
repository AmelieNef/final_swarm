-- Use Shift + Click to select a robot
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here
--Initialisation avec la valeur indiquant une qualité extrêment médiocre
PREVIOUS = 0
R_ROOM_COLOR_PREVIOUS = 128
G_ROOM_COLOR_PREVIOUS = 249
B_ROOM_COLOR_PREVIOUS = 255


--[[ This function is executed every time you press the 'execute' button ]]
function init()
	robot.colored_blob_omnidirectional_camera.enable()
	robot.leds.set_all_colors(128, 249, 255)
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
		--Detection of floor color
		color_floor_value = evaluation_couleur()

		--Detection of room color
		R_room, G_room, B_room , door = door_color()
		R_robot, G_robot, B_robot = adapt_door_color(R_room, G_room, B_room,1)

		--Verification of the type of place which we are
		if color_floor_value > 0  then


			--Compute the number of object in the room
			object_value, distance_object = comptage_objet()
			object_normalize_value = (object_value - 2) / 10

			--Compute the room quality
			quality_value =  (color_floor_value + object_normalize_value) /2

			-- Check if an another robot will be at proximity and thinking this room is the best
			distance, compteur = check_neighboor(R_robot, G_robot, B_robot, R_room, G_room, B_room)

			--Check if a robot make currently an advertize 
			stop, new_R_robot, new_G_robot, new_B_robot = stop_aggregation_function(R_robot, G_robot, B_robot)

			-- Comparison in between previous best quality value and actual quality value:
			if PREVIOUS <= quality_value  and distance_object < 300 and PREVIOUS ~= 0 then

				--When the robot enter in the room, he take the room color
				if door < 100 then
					robot.leds.set_all_colors(R_robot, G_robot, B_robot)
					move_robot()

				--If an another robot thinking that it's the best room 
				elseif PREVIOUS > 0 and distance < 50 and  distance_object < 210 and not stop then
					robot.wheels.set_velocity(0,0)

					limite = (compteur/1000)
					if limite > 0.1 then
						limite = 0.1
					end

					if (robot.random.uniform() > (0.965 + limite)) then
						choice = robot.random.uniform()
						if choice < 0.25 then
							robot.leds.set_all_colors(0,0,254)
						elseif choice <0.5 then
							robot.leds.set_all_colors(254,0,254)
						elseif choice < 0.75 then
							robot.leds.set_all_colors(254,0,0)
						else
							robot.leds.set_all_colors(254,139,0)
						end
					end

                --If a robot make an advertise that is not the best room
				elseif stop and  distance_object < 300 and door > 130 then
					robot.leds.set_all_colors(new_R_robot, new_G_robot, new_B_robot)
					move_robot()

				--If a robot are alone.
				else
					move_robot()
				end


			else
				--If the actual quality are more better than previous best quality value but the robot are too much far to the object
				if PREVIOUS < quality_value then

					--If the robot enter in the room
					if enter then
						robot.leds.set_all_colors(R_robot, G_robot, B_robot)
					end

					--Actualize PREVIOUS value when he go out the room
					if before_out_room() then
						PREVIOUS = quality_value
						R_ROOM_COLOR_PREVIOUS = R_room
						G_ROOM_COLOR_PREVIOUS = G_room
						B_ROOM_COLOR_PREVIOUS = B_room
					end

					move_robot()

				--If the quality value of the room are more lower than PREVIOUS
				else
					if distance_object < 210 then
						--make sure to have a differente color than te room
						make_sure_to_advertise(R_robot, G_robot, B_robot)
					end

					move_robot()
				end
			end

		else
			-- Democratia term
			color_R, color_G, color_B, vote  = best_room()
			--If the majority are speak
			if not enter then
				new_R, new_G, new_B = adapt_door_color(color_R, color_G, color_B,1)
				robot.leds.set_all_colors(new_R, new_G, new_B)
				go_to_door(color_R, color_G, color_B)
			end
			move_robot()

		end
end


--When the robot enter in a room
--Check if the robot will be enter
function enter_in_room()
	compteur_grey = 0
	compteur_black = 0
	enter = false
	for x = 1, 4 do
		if robot.motor_ground[x].value == 0 then
			compteur_black = compteur_black + 1
		elseif robot.motor_ground[x].value ~= 0 then
			compteur_grey = compteur_grey + 1
		end
	end
	if compteur_grey ~= 0 and compteur_black ~= 0 then
		enter = true
	end
	return enter
end

--Check if the robot go out the room
function before_out_room()
	before = false
	if robot.motor_ground[1].value ~= 0 and robot.motor_ground[2].value ~= 0 and robot.motor_ground[3].value ~= 0 and robot.motor_ground[4].value ~= 0 then
		color, proximity = door_color()
		if proximity  < 150 then
			before = true
		end
	end
	return before
end

--Looking the door color
function door_color()
	R_room1, G_room1, B_room1, proximity_room1, compteur_room1  = check_color(0,0,255)
	R_room2, G_room2, B_room2, proximity_room2, compteur_room2  = check_color(255,0,255)
	R_room3, G_room3, B_room3, proximity_room3, compteur_room3  = check_color(255,0,0)
	R_room4, G_room4, B_room4, proximity_room4, compteur_room4  = check_color(255,140,0)

	if proximity_room1 < proximity_room2 and proximity_room1 < proximity_room3 and proximity_room1 < proximity_room4 then
		proximity = proximity_room1
		R = R_room1
		G = G_room1
		B = B_room1

	elseif proximity_room2 < proximity_room1 and proximity_room2 < proximity_room3 and proximity_room2 < proximity_room4 then
		proximity = proximity_room2
		R = R_room2
		G = G_room2
		B = B_room2

	elseif proximity_room3 < proximity_room2 and proximity_room3 < proximity_room1 and proximity_room3 < proximity_room4 then
		proximity = proximity_room3
		R = R_room3
		G = G_room3
		B = B_room3

	else
		proximity = proximity_room4
		R = R_room4
		G = G_room4
		B = B_room4
	end
	return R, G, B, proximity
end

--Evalue the floor color
function evaluation_couleur()
	floor = 0
	if robot.motor_ground[1].value ~= 0 and robot.motor_ground[4].value ~= 0 then
		floor = robot.motor_ground[1].value
	end
	return floor
end

--Adaptation of color door for the color of robot (make a distinction between them)
function adapt_door_color(R_room, G_room, B_room, index)
	R_robot_new = adapt_color(R_room, index)
	G_robot_new = adapt_color(G_room, index)
	B_robot_new = adapt_color(B_room, index)
	return R_robot_new, G_robot_new, B_robot_new
end

function adapt_color(color, index)
	new_color = color
	if color ~= 0 then
		if index == 1 then
			new_color = color - 1
		else
			new_color = color + 1
		end
	end
	return new_color
end

--Action to look the neighbors colors

--Democration function 
function best_room ()
	R_new = R_ROOM_COLOR_PREVIOUS
	G_new = G_ROOM_COLOR_PREVIOUS
	B_new = B_ROOM_COLOR_PREVIOUS

	R_room1, G_room1, B_room1, proximity_room1, compteur_room1  = check_color(0,0,254)
	R_room2, G_room2, B_room2, proximity_room2, compteur_room2  = check_color(254,0,254)
	R_room3, G_room3, B_room3, proximity_room3, compteur_room3  = check_color(254,0,0)
	R_room4, G_room4, B_room4, proximity_room4, compteur_room4  = check_color(254,139,0)

	unanime = false

	stochastique = robot.random.uniform()

	--Solution Deterministic/exploitation
	if stochastique < 0.99 then
		if #robot.colored_blob_omnidirectional_camera > 4 then
		    if compteur_room1 >= (#robot.colored_blob_omnidirectional_camera /2)  then
				R_new = 0
				G_new = 0
				B_new = 255
				unanime = true

			elseif compteur_room2 >= (#robot.colored_blob_omnidirectional_camera /2)  then
				R_new = 255
				G_new = 0
				B_new = 255
				unanime = true

			elseif compteur_room3 >= (#robot.colored_blob_omnidirectional_camera /2)  then
				R_new = 255
				G_new = 0
				B_new = 0
				unanime = true

			elseif compteur_room4 >= (#robot.colored_blob_omnidirectional_camera /2) then
				R_new = 255
				G_new = 140
				B_new = 0
				unanime = true
			end
		end

	--Solution stochastic/exploration
	else
		R_new, G_new, B_new = pick_random_color()
		unanime = true
	end

	return R_new, G_new, B_new, unanime
end

function pick_random_color()
	pick_random = robot.random.uniform()
	if pick_random < 0.25 then
		R_new = 0
		G_new = 0
		B_new = 255
	elseif pick_random < 0.5 then
		R_new = 255
		G_new = 0
		B_new = 255
	elseif pick_random < 0.75 then
		R_new = 255
		G_new = 0
		B_new = 0
	else
		R_new = 255
		G_new = 140
		B_new = 0
	end
	return R_new, G_new, B_new
end

--Count all robot with a same color
function check_color(r,g,b)
	R = 0
	G = 0
	B = 0
	proximity = 1000
	compteur = 0

	for x = 1, #robot.colored_blob_omnidirectional_camera do
		if robot.colored_blob_omnidirectional_camera[x].color.red == r and robot.colored_blob_omnidirectional_camera[x].color.green == g and robot.colored_blob_omnidirectional_camera[x].color.blue == b then
			compteur = compteur + 1
			if robot.colored_blob_omnidirectional_camera[x].distance < proximity then
				proximity = robot.colored_blob_omnidirectional_camera[x].distance
				R = r
				G = g
				B = b
			end
		end
	end
	return R, G, B, proximity, compteur
end


--Look the room color robot
function check_neighboor(r,g,b, r_room, g_room, b_room)
	proximity = 1000
	compteur = 0

	for x = 1, #robot.colored_blob_omnidirectional_camera do
		if robot.colored_blob_omnidirectional_camera[x].color.red == r and robot.colored_blob_omnidirectional_camera[x].color.green == g and robot.colored_blob_omnidirectional_camera[x].color.blue == b then
			compteur = compteur + 1
			if proximity > robot.colored_blob_omnidirectional_camera[x].distance then
				proximity = robot.colored_blob_omnidirectional_camera[x].distance
			end
		end
	end
	return proximity, compteur
end

--Count number of object present in the room
function comptage_objet()
	compteur_green = 0
	proximity = 0
	for x = 1, #robot.colored_blob_omnidirectional_camera do
		if robot.colored_blob_omnidirectional_camera[x].color.green > 150 and robot.colored_blob_omnidirectional_camera[x].color.red == 0 and robot.colored_blob_omnidirectional_camera[x].color.blue == 0 then
			compteur_green = compteur_green + 1

			if proximity <  robot.colored_blob_omnidirectional_camera[x].distance then
				proximity = robot.colored_blob_omnidirectional_camera[x].distance
			end
		end
	end
	return compteur_green, proximity
end

--Check if a robot advertise that it's not hte best room
function stop_aggregation_function(r,g,b)
	stop = false
	new_r = 0
	new_g = 0
	new_b = 0
	for x = 1, #robot.colored_blob_omnidirectional_camera do
		if not (robot.colored_blob_omnidirectional_camera[x].color.blue == b and robot.colored_blob_omnidirectional_camera[x].color.green == g and robot.colored_blob_omnidirectional_camera[x].color.red == r) and not(robot.colored_blob_omnidirectional_camera[x].color.blue== 0 and robot.colored_blob_omnidirectional_camera[x].color.green > 150 and robot.colored_blob_omnidirectional_camera[x].color.red == 0 )  and not (robot.colored_blob_omnidirectional_camera[x].color.blue == 255 and robot.colored_blob_omnidirectional_camera[x].color.green == 249 and robot.colored_blob_omnidirectional_camera[x].color.red == 128) then
			if robot.colored_blob_omnidirectional_camera[x].distance < 100 then
				stop = true
				new_r = robot.colored_blob_omnidirectional_camera[x].color.red
				new_g = robot.colored_blob_omnidirectional_camera[x].color.green
				new_b = robot.colored_blob_omnidirectional_camera[x].color.blue
			end
		end
	end
	return stop,new_r, new_g, new_b
end

--Count total robot are be present
function make_sure_to_advertise(R_rb, G_rb, B_rb)
	personal_influence_ = robot.random.uniform()

	if personal_influence_ < 0.99 then
		new_R = R_rb
		new_G = G_rb
		new_B = B_rb

		while new_R == R_rb and new_G == G_rb and new_B == B_rb do
			new_R_plausible, new_G_plausible, new_B_plausible = pick_random_color()
			new_R, new_G, new_B = adapt_door_color(new_R_plausible, new_G_plausible,
			new_B_plausible,1)

		robot.leds.set_all_colors(new_R, new_G, new_B)

		end

	else
		R_new, G_new, B_new = adapt_door_color(R_ROOM_COLOR_PREVIOUS, G_ROOM_COLOR_PREVIOUS, B_ROOM_COLOR_PREVIOUS,1)
		robot.leds.set_all_colors(R_new, G_new, B_new)
	end
end




--Actions to move

--Avoid obstacle (wall, object, robot)
function evitement(number)
	move = false
	if number > 7 then
		move = true
		if number == 9 then
			robot.wheels.set_velocity(0,300)
		else
			robot.wheels.set_velocity(300,0)
		end

	else
		if look_around(1,9) == 1 or look_around(22,24) == 1 then
			robot.wheels.set_velocity(0,300)
			move = true
		elseif look_around(16,24) == 1 or look_around(1,3) == 1 then
			robot.wheels.set_velocity(300,0)
			move = true
		elseif look_around(22,24) == 1 or look_around(1,3) == 1 then
			pioche = robot.random.uniform_int(0,2)
			if pioche <1 then
				robot.wheels.set_velocity(0,300)
			else
				robot.wheels.set_velocity(300,0)
			end
			move = true
		end
	end
	return move
end

--Check presence or not of entity near to the robot
function look_around(debut, fin)
	value = 0
	for x = debut,fin do
			if robot.proximity[x].value > 0 then
				value = 1
			end
	end
return value
end

--Move in the room
function move_robot()
	number = robot.random.uniform_int(0,10)
	ending = evitement(number)
	if not ending then
		if number < 5 then
			robot.wheels.set_velocity(30,30)
		elseif number < 7 then
			robot.wheels.set_velocity(100,20)
		else
			robot.wheels.set_velocity(20,100)
		end
	end
end

function go_to_door(R_i, G_i, B_i)
	for x = 1, #robot.colored_blob_omnidirectional_camera do
		if robot.colored_blob_omnidirectional_camera[x].color.red == R_i and robot.colored_blob_omnidirectional_camera[x].color.green == G_i and  robot.colored_blob_omnidirectional_camera[x].color.blue == B_i then
			distance = robot.colored_blob_omnidirectional_camera[x].distance
			angle_radian = robot.colored_blob_omnidirectional_camera[x].angle
			angle_degres = (180/3.14)*angle_radian

			if angle_degres > - 21 and angle_degres <= 23 then
				robot.wheels.set_velocity(30, 30)
			elseif angle_degres > 0 then
				robot.wheels.set_velocity(30,angle_degres+30)
			else
				angle_degres = - angle_degres
				robot.wheels.set_velocity(angle_degres+30,30)
			end
		end
	end
end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
	robot.colored_blob_omnidirectional_camera.enable()
	robot.leds.set_all_colors(128, 249, 255)
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
