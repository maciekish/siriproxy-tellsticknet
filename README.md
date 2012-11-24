# SiriProxy plugin for Tellstick Live! #

This is a SiriProxy plugin to control Tellstick Live! lights with Siri. It has been developed for and tested with [SiriProxy](https://github.com/plamoni/SiriProxy).

## Example Commands ##

- Turn off|on the *light name* light
- Turn the *light name* light off|on
- Set the *light name* to *50* percent
- Is the *light name* light on|off|dimmed? (This command takes it's best guess. Tellstick *cannot* read switch positions!)

## Setup ##

- Download and install SiriProxy.
- Download and authenticate tdtool.py with your Tellstick Live! account. You can get it here [tdtool.py](http://developer.telldus.com/browser/examples/python/live/tdtool/tdtool.py)
- Make sure tdtool.py is somewhere in your $path.
- Add the plugin to your SiriProxy config.

## Notes ##

You may use the vanilla tdtool and bypass Tellstick Live! if you have a Tellstick Duo and edit the script.

## Credit ##

This SiriProxy plugin was created by Maciej Swic, but there's a ton of people who have put work into SiriProxy, thanks to them for making this possible.