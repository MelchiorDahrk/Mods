# Package openmw_aux.calendar

# Package openmw_aux.calendar

API v129

`openmw_aux.calendar` defines utility functions for formatting game time.

Implementation can be found in `resources/vfs/openmw_aux/calendar.lua`.

global
menu
local

## Usage

`local calendar = require('openmw_aux.calendar')`

## Type `calendar`

calendar.daysInMonth(monthIndex)

The number of days in a month

calendar.daysInWeek

The number of days in a week

calendar.daysInYear

The number of days in a year

calendar.formatGameTime(format, time)

An equivalent of `os.date` for game time.

calendar.gameTime(table)

An equivalent of `os.time` for game time.

calendar.monthCount

The number of months in a year

calendar.monthName(monthIndex)

The name of a month

calendar.monthNameInGenitive(monthIndex)

The name of a month in genitive (for English is the same as `monthName`, but in some languages the form can differ).

calendar.weekdayName(dayIndex)

The name of a weekday

## Type `calendar`

### Field(s)

calendar.daysInMonth(monthIndex)

The number of days in a month

### Parameter

-
` monthIndex `:

### Return value

#number:

#number

calendar.daysInWeek

The number of days in a week

#number

calendar.daysInYear

The number of days in a year

calendar.formatGameTime(format, time)

An equivalent of `os.date` for game time.

See the Lua date and time reference for formatting details.
It is a slow function. Please try not to use it in every frame.

### Parameters

-
` #string format `:
format of date (optional)

-
` #number time `:
time to format (default value is current time)

### Return value

#string:
a formatted string representation of `time`.

calendar.gameTime(table)

An equivalent of `os.time` for game time.

See the Lua date and time reference for formatting details.

### Parameter

-
` #table table `:
a table which describes a date (optional).

### Return value

#number:
a timestamp.

#number

calendar.monthCount

The number of months in a year

calendar.monthName(monthIndex)

The name of a month

### Parameter

-
` monthIndex `:

### Return value

#string:

calendar.monthNameInGenitive(monthIndex)

The name of a month in genitive (for English is the same as `monthName`, but in some languages the form can differ).

### Parameter

-
` monthIndex `:

### Return value

#string:

calendar.weekdayName(dayIndex)

The name of a weekday

### Parameter

-
` dayIndex `:

### Return value

#string:

Auxiliary Packages

Package openmw_aux.time
