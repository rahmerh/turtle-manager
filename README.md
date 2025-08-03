# Turtle manager

Collection of my own scripts for working with CC: Tweaked's turtles. Includes generic pathfinding, dashboards and the works.

""Pathfinding"" is very generious, the turtle is very stupid and through some brute force and randomness it tries to claw it's way out of a stuck position. When using this script, please be nice and put him on the surface, or at least in a room with an easy vertical path out. He'll have around 100 attempts to get unstuck before giving up.

## Getting started

First get the bootstrap script onto the turtle or computer:

```sh
wget https://raw.githubusercontent.com/rahmerh/turtle-manager/refs/heads/main/bootstrap.lua
```

Next bootstrap the turtle/computer, you can select from the following roles:

- Manager `bootstrap manager`
- Quarry `bootstrap quarry`
- Runner `bootstrap runner`

## Usage

### Manager

This is the central computer and should always be running. Because of this, you don't need to run anything, simply attach a modem to a computer and reboot.

If you want to see the current turtles, attach a monitor (minimum 2x2).

### Quarry

First you have to prepare the job by running `prepare` and entering the quarry dimensions.

This will create a file called `job.conf` which contains the quarry's boundaries and progress. By default a quarry is resumable but this and other data can be edited manually.

You can start the quarry by rebooting the turtle.

The turtle doesn't go back up to the surface to unload or to resupply, it will send a command to the manager which will send a runner to retrieve the items or provide requested resources.

### Runner

A runner is a very general helper role which assists others. When a quarry turtle sends a pickup request, a runner will come and retrieve it. When a turtle is out of fuel or chests, a runner will go and rescue it.

First you need to run `prepare` and enter the correct values. The resupply chest requires some additional setup. Due to turtle limitations, it can't directly suck up a specified item, which is why it requires an additional "buffer" chest on top. This means the supply chest's setup is like this:

```
[buffer chest]
[air]
[supply chest]
```

The turtles only request coal and chests, so make sure to always have these supplies in your supply chest. Personal recommendation is to either have an AE2 interface which always has 64 coal and chests or use another mod to always have those items in the supply chest.

## TODO

- Quarry fluids handling
- Display interactivity
