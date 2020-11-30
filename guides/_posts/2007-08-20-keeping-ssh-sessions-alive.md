---
layout: post
title: Keeping SSH sessions alive
---

# {{ page.title }}

<p class="meta">20 August 2007 - Chicago</p>

This is one of those things that I setup once a year when I get a new machine and then I always seem to forget the next time around so I'll post it here as a reference to myself and perhaps also help the occasional Googler. If you are having problems with your SSH connection getting dropped after a certain amount of time (usually caused by NAT firewalls and home routers), you can use the following setting to keep your connection alive

<pre><code>
Host *
    ServerAliveInterval 180
</code></pre>

You can place this either in <code>~/.ssh/config</code> for user level settings or in <code>/etc/ssh/ssh_config</code> for machine level settings. You may also replace * with a specific hostname or something like *.example.com to use on all machines within a domain.
This is the cleanest way of making sure your connections stay up and doesn't require changes to the destination servers (over which you may not have control). I am not sure however how this plays with the IdleTimeout setting on the server. I am guessing that a server should be able to enforce its own policy about how long folks are remained to be idle for security reasons so you might still get disconnected after a certain amount of time.
