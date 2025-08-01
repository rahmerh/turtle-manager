# Turtle manager

Collection of my own scripts for working with CC: Tweaked's turtles. Includes generic pathfinding, dashboards and the works.

""Pathfinding"" is very generious, the turtle is very stupid and through some brute force and randomness it tries to claw it's way out of a stuck position. When using this script, please be nice and put him on the surface, or at least in a room with an easy vertical path out. He'll have around 100 attempts to get unstuck before giving up.

## Getting started

First get the bootstrap script onto the turtle or computer:

```sh
wget https://raw.githubusercontent.com/rahmerh/turtle-manager/refs/heads/main/bootstrap.lua
```

Next bootstrap the device, you can select from the following roles:

- Manager `bootstrap manager`
- Quarry `bootstrap quarry`

## Usage

### Manager

This is the central computer and should always be running. Because of this, you don't need to run anything, simply attach a modem to a computer and reboot.

If you want to see the current turtles, attach a monitor (minimum 2x2).

### Quarry

First you have to prepare the job:

```sh
prepare <start_pos_x> <start_pos_y> <start_pos_z> <width> <depth>
```

This will create a file called `job-file` which contains the quarry's boundaries and progress. By default a quarry is resumable but this and other data can be edited manually.

When the job is created you can then simply start the quarry with: `quarry`. When the turtle restarts (because of starting a new game or it gets unloaded/loaded) it will also resume the quarry by running that command.

The turtle doesn't go back up to the surface to unload, it will send a pickup command to the manager which will send a runner to retrieve the items. This saves both fuel and time of the quarrying turtle.

### Runner

A runner is a very general helper role which assists others. When a quarry turtle sends a pickup request, a runner will come and retrieve it. When a turtle is out of fuel or chests, a runner will go and rescue it.

## TODO

- Quarry fluids handling
- Wireless rework
- Runner refuel itself
- Display interactivity
