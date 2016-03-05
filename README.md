VideoBox
========

# What it is

This project is an attempt to create a website that acts as a torrent stream-capable multimedia box. That website can also be remote controlled. It also streams to the remote device so that you can watch your movie
from your TV, and continue watching from your smartphone when you are away !

Several projects exists:
* [BlissFlix](http://blissflixx.rocks) is in PHP
* [Kodi](http://www.kodi.tv) is a whole interface written in native code and scripts
* [TV.js](https://github.com/SamyPesse/tv.js/) nice interface written in Javascript

This piece of software has a different purpose and implementation. This software is designed to be a web application, with two views: one is the local display and the other, the remote controller.
Being able to play indistinctly from either your remote controller or your remote display, searching and playing happening in the same device or in a 1:1 (1 remote/1 display) or N:1 (N remotes/1 display).. A new world of possibilities :smile:

[WebTorrent API](https://webtorrent.io/) provides a nice API to handle torrent download.
[TorrentProject](https://torrentproject.se/) is the definitive source for torrents.

To minimize adherence on external software being ```spawn```-ed, I tried to integrate most of the code by using their Javascript implementations. The only software spawned is the interpreter (__coffee__) to still take advantage of the 4-CPU armv7l on the Raspberry Pi 2... :wink:

> ### Notes:
> * At the moment the only software spawned is the player
> * __omxplayer__ and __mplayer__ are reported to work when called to play video files.
> * You can set your own command (with its arguments) on your Mongo Database in collection ```config```.

Pure Javascript implementations exist, like [Node-OpenMAX](https://github.com/jean343/Node-OpenMAX/)) which would avoid spawning omxplayer. Similar options might exist to avoid spawning of mplayer (or even vlc!). This needs some investigation though and will definitely make a more complex code base.

It has been tested on both a ```Ubuntu Linux``` running on x64 virtualized Core i7 and a Raspberry Pi 2 with ```Raspbian```.

Still, this is at the moment more a proof-of-concept than a ready-to-be-used solution. There are still a lot of ```console.log``` out there... :smile:

# Usage

As both parts of the website can be opened on the same device or different devices, two different web pages exist, each showing its own content. Contents can be same or different, the point is to display insightful elements :smile:

As a use case, let's say your Raspberry Pi 2 is connected to your TV. You can have a website opened on the TV (with a nice interface to read and select options from your TV). Or you might not care and keep your background blank waiting for a video to start.

Now, from your remote device, open up a Web browser and go to your Raspberry Pi 2 IP address/hostname and you will see the beginning of something...

In simple words:
* You __search__ your video file
* Then, you __select__ from the results
* Click to show __details__ or directly __play__
* __done__ ! :beer:

There are definitely __alot__ more to do, contributions are most welcomed!

# Installation notes

## Raspberry Pi 2

Let's start from a blank ```Raspbian Jessie``` image downloaded from [here](https://www.raspberrypi.org/downloads/raspbian/).

For the following, it's better to first get super powers with ```sudo -i```

Once privileged, let's update stuff by issuing the usual:

```
# aptitude update && aptitude dist-upgrade
```

Takes some time, then run the following script to get the latest NodeJS 0.10 branch.

```
# curl -sL https://deb.nodesource.com/setup_0.10 | bash -
# apt-get install -y nodejs
```

Wait some more time, but now we have both ```node``` and ```npm``` globally installed!
This will help for startup script later on...

Since you have those super powers, you can keep going and install __CoffeeScript__ globally.

```
# npm i -g coffee-script
```

Of course you can install it with your user account as long as ```coffee``` can be
called from the command line !

> From now on we can drop our super powers !

We need to install some dependencies manually.
These can be installed either in the user context or system-wide (for that you need to add ```-g```).

```
$ npm i webtorrent torrent-project-api q chokidar
```

That should do it !

# Roadmap

Here are some ideas of improvements:
- [REMOTE] implement ```menu``` with views on "best movies", "top 100", "latest", etc.
- [REMOTE] implement ```settings``` with config page (system players, etc) and search APIs
- [DISPLAY] better error handling when playing file (mplayer does not like MZ files!)
- [DISPLAY] implement 'widget' like elements on TV screen for weather/headlines/etc.
- [COMMON] add new ```search``` APIs, sources,... (RSS, YT, Dailymotion, Twitch etc.)
- [COMMON] implement ```subtitles``` API search/find/display
- [COMMON] better plugin support (add envelope to bind messages events)
- [COMMON] implement ```YouTube```, ```Vimeo```, etc players as plugins

What has been done is described in the [Changelog](Changelog.md)!

# About

Written in _CoffeeScript_ for use in _Meteor_ framework !

License GPLv3
