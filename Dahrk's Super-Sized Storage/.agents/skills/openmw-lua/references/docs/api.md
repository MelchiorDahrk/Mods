# API Reference

# API Reference

API v129

API packages

API packages provide functions that can be called by scripts. I.e. it is a script-to-engine interaction.
A package can be loaded with ` require('<package name>') `.
It can not be overloaded even if there is a lua file with the same name.
The list of available packages is different for global and for local scripts.
Player scripts are local scripts that are attached to a player.

Package

Context

Description

ambient

menu player

Controls background sounds for given player.

animation

local

Animation controls.

async

global menu local load

Timers and callbacks.

camera

player

Controls camera.

content

load

Content manipulation.

core

global menu local load

Functions that are common for both global and local scripts

debug

player

Collection of debug utils.

input

menu player

User input.

interfaces

global menu local load

Public interfaces of other scripts.

markup

global menu local load

API to work with markup languages.

menu

menu

Main menu functionality, such as managing game saves

nearby

local

Read-only access to the nearest area of the game world.

postprocessing

player

Controls post-process shaders.

self

local

Full access to the object the script is attached to.

storage

global menu local load

Storage API. In particular can be used to store data between game sessions.

types

global local player

Functions for specific types of game objects.

ui

menu player

Controls user interface .

util

global menu local load

Defines utility functions and classes like 3D vectors, that don’t depend on the game world.

vfs

global menu local load

Read-only access to data directories via VFS.

world

global

Read-write access to the game world.

Auxiliary packages

` openmw_aux.* ` are built-in libraries that are itself implemented in Lua. They can not do anything that is not possible with the basic API, they only make it more convenient.
Sources can be found in ` resources/vfs/openmw_aux `. In theory mods can override them, but it is not recommended.

Module

Context

Description

calendar

global menu local

Game time calendar

time

global menu local

Timers and game time utils

ui

menu player

User interface utils

util

global menu local load

Miscellaneous utils

Interfaces of built-in scripts

Interface

Context

Description

Activation

global

Allows to extend or override built-in activation mechanics.

AI

local

Control basic AI of NPCs and creatures.

AnimationController

local

Control animations of NPCs and creatures.

Camera

player

Allows to alter behavior of the built-in camera script without overriding the script completely.

Controls

player

Allows to alter behavior of the built-in script that handles player controls.

Crimes

global

Commit crimes.

Combat

local

Control combat of NPCs and creatures

GamepadControls

player

Allows to alter behavior of the built-in script that handles player gamepad controls.

ItemUsage

global

Allows to extend or override built-in item usage mechanics.

MWUI

menu player

Morrowind-style UI templates.

Settings

global menu player

Save, display and track changes of setting values.

SkillProgression

player

Control, extend, and override skill progression of the player.

UI

player

High-level UI modes interface. Allows to override parts of the interface.

Overview

Packages
