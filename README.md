# Turtle manager

Collection of my own scripts for working with CC: Tweaked's turtles. Includes generic pathfinding, dashboards and the works.

""Pathfinding"" is very generious, the turtle is very stupid and through some brute force and randomness it tries to claw it's way out of a stuck position. When using this script, please be nice and put him on the surface, or at least in a room with an easy vertical path out. He'll have around 100 attempts to get unstuck before giving up.

## Getting started

First get the bootstrap script onto the turtle or computer:

```sh
wget https://raw.githubusercontent.com/rahmerh/turtle-manager/refs/heads/main/bootstrap.lua
```

Next bootstrap the device, you can select from the following roles:

- Quarry `bootstrap quarry`

From there on, check usage below for each role

## Usage

### Quarry

First you have to prepare the job:

```sh
prepare <start_pos_x> <start_pos_y> <start_pos_z> <width> <depth>
```

When the job is created you can then simply start the quarry with: `quarry`
