![ember's fps controller titlecard](titlecard.png)

My KinematicBody solution to smooth stairstepping in Godot.

# What does this character controller do?

This character controller lets you smoothly step on top of objects that are waist-height and lower. Your horizontal velocity is not lost when going uphill, and your character will raise itself to meet the height of the obstacle it's currently sitting on.

Walking over bumpy or uneven terrain should be really simple for the player - move towards it and your player will step over it. It reduces the feeling of punishment for traversing uphill, and keeps the game feeling responsive.

# How is it different from other stair-stepping solutions?

It uses a **RayShape** CollisionShape to snap up to stairs, and falls using gravity and `move_and_slide()` to go down stairs. The camera's y position is interpolated from the player's actual y position to give the illusion of smooth movement.

I wanted this controller to use built-in Godot physics and nodes as the solution. I also wanted it to be simple to maintain or adjust going forward. It doesn't even jump yet, the focus is just on good stair stepping and movement. Unless RayShape is drastically changed, the concept and execution should remain compatible with future versions of Godot.

# Wait, did you say no jumping?

I'm leaving that up to you to decide how to implement it alongside this stair stepping. Some games (like my walking simulators) require no jumping if the player can automatically traverse small vertical obstacles.

But also, I made this after being inspired by Casey Muratori's 2018 talk [Killing the Walk Monster](https://www.youtube.com/watch?v=YE8MVNMzpbo) which showed a really clever way of stair stepping using two cylinders to accomplish the same task. The Witness has no jumping, so its stair stepping becomes really important. Godot's KinematicBody and built-in physics lacks the ability to ignore horizontal collisions on a shape, unless the whole thing was written with RigidBody and `integrate_forces()`.

I made this template for demonstration purposes so it could be improved, not as a perfect slot-in solution to replace the development work that comes from tweaking a character controller.

# Shortcomings

This template only gives you one RayShape, in the middle of the KinematicBody. Your current height is determined by one point, so you have no depth as a player. You can fix this by adding more RayShape CollisionShapes in a ring that matches the cylinder's radius, and this will let the player stand on the edge of surfaces. The only downside to this fix is that not enough rays will have the player's height dip repeatedly while turning the body, or when intersecting geometry between rays.

The head's shape can still let you sink into the ground a bit if you hit your head on a descending slope.

The head is the only means of stopping you from going up really steep slopes, including 90 degree slopes. You're free to adjust the `move_and_slide()` parameters to try and fix this, or finding a way of catching it in `physics_process()`, but so far I haven't found a way to prevent huge increases in height for any steep slope that reaches beneath the player's head radius.

# Examples
An earlier, buggier version of this controller has been used in my game [Winter Weather](https://deertears.itch.io/winter-weather), a first person poem-reader.

# Contact

Ember#1765 on Discord, @goodnight_grrl on Twitter. Let me know if you have questions about the controller or want to discuss options for how to improve it. You can also just raise an issue for anything, I'm not picky with this repo.
