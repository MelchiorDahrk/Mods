# Package openmw.ambient

# Package openmw.ambient

API v129

Controls background 2D sounds specific to a given player.

menu
player

## Usage

`local ambient = require('openmw.ambient')`

## Type `ambient`

ambient.isMusicPlaying()

Check if music is playing

ambient.isSoundFilePlaying(fileName)

Check if a sound file is playing

ambient.isSoundPlaying(soundId)

Check if a sound is playing

ambient.playSound(soundId, options)

Play a 2D sound

ambient.playSoundFile(fileName, options)

Play a 2D sound file

ambient.say(fileName, text)

Play an ambient voiceover.

ambient.stopMusic()

Stop the currently playing music

ambient.stopSay(fileName)

Stop an ambient voiceover

ambient.stopSound(soundId)

Stop a sound

ambient.stopSoundFile(fileName)

Stop a sound file

ambient.streamMusic(fileName, options)

Play a sound file as a music track

## Type `Sound`

Sound.isSayActive()

Check if an ambient voiceover is playing

## Type `ambient`

### Field(s)

ambient.isMusicPlaying()

Check if music is playing

### Return value

#boolean:

### Usage

`local isPlaying = ambient.isMusicPlaying();`

ambient.isSoundFilePlaying(fileName)

Check if a sound file is playing

### Parameter

-
` #string fileName `:
Path to a sound file in VFS

### Return value

#boolean:

### Usage

`local isPlaying = ambient.isSoundFilePlaying("Sound\\test.mp3");`

ambient.isSoundPlaying(soundId)

Check if a sound is playing

### Parameter

-
` #string soundId `:
ID of Sound record to check

### Return value

#boolean:

### Usage

`local isPlaying = ambient.isSoundPlaying("shock bolt");`

ambient.playSound(soundId, options)

Play a 2D sound

### Parameters

-
` #string soundId `:
ID of Sound record to play

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `timeOffset` - a floating point number >= 0, to skip some time (in seconds) from the beginning of the sound (default: 0);

- `volume` - a floating point number >= 0, to set the sound's volume (default: 1);

- `pitch` - a floating point number >= 0, to set the sound's pitch (default: 1);

- `scale` - a boolean, to set if the sound's pitch should be scaled by simulation time scaling (default: true);

- `loop` - a boolean, to set if the sound should be repeated when it ends (default: false);

### Usage

`local params = {
timeOffset=0.1,
volume=0.3,
scale=false,
pitch=1.0,
loop=true
};
ambient.playSound("shock bolt", params)`

ambient.playSoundFile(fileName, options)

Play a 2D sound file

### Parameters

-
` #string fileName `:
Path to a sound file in VFS

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `timeOffset` - a floating point number >= 0, to skip some time (in seconds) from the beginning of the sound file (default: 0);

- `volume` - a floating point number >= 0, to set the sound's volume (default: 1);

- `pitch` - a floating point number >= 0, to set the sound's pitch (default: 1);

- `scale` - a boolean, to set if the sound's pitch should be scaled by simulation time scaling (default: true);

- `loop` - a boolean, to set if the sound should be repeated when it ends (default: false);

### Usage

`local params = {
timeOffset=0.1,
volume=0.3,
scale=false,
pitch=1.0,
loop=true
};
ambient.playSoundFile("Sound\\test.mp3", params)`

ambient.say(fileName, text)

Play an ambient voiceover.

### Parameters

-
` #string fileName `:
Path to a sound file in VFS

-
` #string text `:
Subtitle text (optional)

### Usages

-

`-- play voiceover and print messagebox
ambient.say("Sound\\Vo\\Misc\\voice.mp3", "Subtitle text")`

-

`-- play voiceover, without messagebox
ambient.say("Sound\\Vo\\Misc\\voice.mp3")`

ambient.stopMusic()

Stop the currently playing music

### Usage

`ambient.stopMusic();`

ambient.stopSay(fileName)

Stop an ambient voiceover

### Parameter

-
` #string fileName `:
Path to a sound file in VFS

### Usage

`ambient.stopSay();`

ambient.stopSound(soundId)

Stop a sound

### Parameter

-
` #string soundId `:
ID of Sound record to stop

### Usage

`ambient.stopSound("shock bolt");`

ambient.stopSoundFile(fileName)

Stop a sound file

### Parameter

-
` #string fileName `:
Path to a sound file in VFS

### Usage

`ambient.stopSoundFile("Sound\\test.mp3");`

ambient.streamMusic(fileName, options)

Play a sound file as a music track

### Parameters

-
` #string fileName `:
Path to a file in VFS

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `fadeOut` - a floating point number >= 0, time (in seconds) to fade out the current track before playing this one (default 1.0);

### Usage

`local params = {
fadeOut=2.0
};
ambient.streamMusic("Music\\Test\\Test.mp3", params)`

## Type `Sound`

### Field(s)

Sound.isSayActive()

Check if an ambient voiceover is playing

### Return value

#boolean:

### Usage

`local isActive = isSayActive();`

Packages

Package openmw.animation
