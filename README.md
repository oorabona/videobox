VideoBox
========

# What it is

This project is an attempt to create a remote controlled website that can serve as a torrent stream-capable multimedia box.

Something like [BlissFlix](http://blissflixx.rocks) in full stack Javascript.
Other projects exists, like [TV.js](https://github.com/SamyPesse/tv.js/) and I wanted to experiment [WebTorrent API](https://webtorrent.io/). Being able to play indistinctly from either your remote controller or your remote display, searching and playing happening in the same device or in a 1:1 (1 remote/1 display) or N:1 (N remotes/1 display) ... Sounds interesting :smile:

Also, a major difference with __TV.js__ is that I wanted to minimize relying on external software being ```spawn```-ed. I only spawn a new interpreter (__coffee__) to take advantage of the 4-CPU armv7l on the Raspberry Pi 2... :wink:

It has been tested on both a ```Ubuntu Linux``` running on x64 virtualized Core i7 and a Raspberry Pi 2 with ```Raspbian```.

This is at the moment more a proof-of-concept than a ready-to-be-used solution.
There are still a lot of ```console.log``` out there :)

# Usage

As both parts of the website can be opened as web page on the same device or different devices, two different web pages exist, each showing whatever own content. Contents can be same or different, the point is to display insightful elements at the right size :smile:

As a use case, imagine your Raspberry Pi 2 connected to your TV. With or without Web Interface does not make alot of differences if you are only using it from your remote(s) device(s). But you may want to show something on screen instead of keeping it black..

Now, from your remote device, open up a Web browser and go to your Raspberry Pi 2 IP address/hostname and you will see the beginning of something...

__Search__ your torrent, __get__ the results, click __play__ and __done__ ! :beer:

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

> From now on we can drop our super powers !

We need to install some dependencies manually.
These can be installed either in the user context or system-wide (for that you need to add ```-g```).

```
$ npm i webtorrent torrent-project-api q
```

That should do it !

# Next steps

Apart from the usual testing and bug hunting which are background processes, here are ideas of improvements:
- [REMOTE] implement ```menu``` with views on "best movies", "top 100", "latest", etc.
- [REMOTE] implement ```settings``` with config page (system players, etc) and search API
- [DISPLAY] better error handling when playing file (mplayer does not like MZ files!)
- [DISPLAY] implement 'widget' like elements on TV screen for weather/headlines/etc.
- [COMMON] add new ```search``` API, ```subtitles``` API, better plugin support
- [COMMON] implement ```YouTube```, ```Vimeo```, etc players as plugins

# About

Written in CoffeeScript for use in Meteor framework !

License GPLv3
