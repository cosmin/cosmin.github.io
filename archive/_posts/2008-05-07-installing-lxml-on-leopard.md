---
layout: post
title: Installing lxml 2 on OS X Leopard
---

# {{ page.title }}

<p class="meta">7 May 2008 - Chicago</p>

Update: the post below is about installing lxml 2.0 (2.0.5 is the specific version I installed).

One way to install lxml is to install the py25-lxml package from MacPorts, but I hate installing python packages from MacPorts as it insists on installing it's own version of Python. I like installing setuptools and using easy_install to manage my Python packages. I got lxml to install just fine in the past, but when I tried to do it again last night I ran into some problems so I figured this time I'm going to write down exactly how I solved it so I can refer back to it next time.

I vaguly remembered from last time that I needed to install libxml2 and libxslt in order to build lxml. So I used MacPorts to install libxml2 and libxslt and I tried building lxml again. Still had the same problems as before. It seems that Leopard comes with a version of libxml2 (/usr/include/libxml2), but lxml refuses to build against it (seems to be missing some header files, I'm guessing it's the wrong version but I didn't investigate further). It seems that lxml was picking up the system libxml2 instead of the MacPorts version.

Looking through the lxml documentation I found some options for specifying the library to build against

<code>python setup.py build --with-xslt-config=/path/to/xslt-config</code>

If this doesn't help, you may have to add the location of the header files to the include path like:

<code>python setup.py build_ext -i  -I /usr/include/libxml2</code>

I don't really like this options since I really want to do easy_install lxml and have it work. But the first suggestion got me thinking that maybe I need to change my path to have /opt/local/bin before /usr/bin. So I added /opt/local/bin in front of my PATH and sure enough lxml now installs with easy_install without a problem.
Update: Kumar discovered a possible problem with my instruction. See his comments below for the details. Until version 2.0.6 is released set <code>CFLAGS='-flat_namespace'</code> before <code>easy_install lxml</code>

<b>A summary for the lazy readers:</b>

<pre><code>
sudo port install libxml2 libxslt
export PATH=/opt/local/bin:$PATH
export CFLAGS='-flat_namespace'
sudo easy_install lxml
</code></pre>
