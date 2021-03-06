---
layout: post
title: Working securely for multiple clients
---

# {{ page.title }}

<p class="meta">06 February 2010 - Dallas</p>

As a consultant I often end up working with sensitive client information on my laptop. Since laptops have a tendency to get misplaced or stolen, I  need to keep this client information encrypted. At the same time however I need to be able to work with this data effectively without having to jump through too many hoops.

I believe that effective security requires a degree of convenience, since most people will inevitable circumvent security measures that interfere with their work. Therefore working securely on a laptop needs to be as convenient and natural as possible. I have a system I have developed over time that allows me to easily work with confidential client information on my laptop. I hope this guide will be useful to anyone in a similar situation. The specific examples used in this post involve OS X, TrueCrypt and Maven. It should be possible however to extrapolate and apply the same techniques to other technologies you might be using.

### The ideal state

At this point you might be wondering what I consider to be secure and yet convenient, so I'll go ahead and describe my ideal setup. When I fire up a new Terminal I would like to type a single command to start working on a particular client project, such as

<pre class="terminal"><code>$ work_on_project_a</code></pre>

This single command should mount my encrypted volume if not already mounted, change directory to the respective project, and alter my PATH and environment variables accordingly so that any tools I use will just work as expected for the given project. So let's get started.

### Mounting the encrypted volume on demand

For storing information securely I prefer using [TrueCrypt](http://www.truecrypt.org) because it is free, reliable and cross platform. Here is an example function that will check if our TrueCrypt volume is mounted, and attempt to mount it if not. In addition to easily mounting the encrypted volume, I want to also be able to quickly unmount it, since leaving a volume mounted unnecessarily increases the risk of compromise. Let's also add a function to work_on_project_a that allows us to unmount from the command line.

```
function work_on_project_a() {
    TRUECRYPT="/Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt"
    SOURCE="/Volumes/someclient.tc"
    DESTINATION="/Volumes/SomeClient"
    
    function dismount() {
        $TRUECRYPT -d $SOURCE
    }
    
    if [ -z "`ls $DESTINATION`" ]; then
        echo "Trying to mount..."
        $TRUECRYPT --mount $SOURCE
    fi
    
    cd $DESTINATION/project_a
    
    # more stuff will go here
}
```

### Configure the environment

I want any project specific scripts to automatically be in my PATH after activating a project. Let's make that happen by adding the following to the work_on_project_a function.

```
    OLD_PATH="$PATH"
    export PATH="$DESTINATION/bin:$PATH"
```

In addition to configuring PATH, this might be a good place to configure other environment variables, such as JAVA_HOME if your project requires a specific version of JAVA, etc.

### Configure maven to store artifacts securely

If you are using Maven, or a similar tool that automatically downloads and install artifacts, then I recommend configuring it to store all artifacts securely inside of the encrypted volume. In order to do so create a maven-settings.xml file under your encrypted volume and override localRepository setting.

```
    <localRepository>/Volumes/SomeClient/mavenRepo</localRepository>
```

You might also want to configure the mirrors in case you have a project specific repository.

```
    <mirrors>
        <mirror>
            <id>internal</id>
            <name>Internal Maven Repo</name>
            <url>http://internal.maven.repo/</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
    </mirrors>
```

Now you can override Maven's global settings file in order to pick up the appropriate mirrors and local repository. The best way to do this is to create a mvn script inside of your project's bin folder that contains the following

```
#!/bin/sh

/usr/bin/mvn -s /Volumes/SomeClient/maven-settings.xml $*
```

### Further configurations

If you need to perform further environment configuration you can do so in the work_on_project_a function. For example, if you have Nginx installed you might want to override the default Nginx configuration with the project specific one. I find this easier than trying to juggle multiple configurations in one Nginx file with vhosts. So for example I would use

```
    sudo rm $NGINX_DESTINATION
    sudo ln -sf $DESTINATION/nginx.conf $NGINX_DESTINATION
```

You can do something similar with Apache, etc.

### Full example of work_on_project_a

Here is a full example that goes above and beyond what we described so far by adding a function to clean up after ourselves, as well as modifying PS1 to show the project we're currently working on.

```
function work_on_project_a() {
    TRUECRYPT="/Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt"
    SOURCE="/Volumes/someclient.tc"
    DESTINATION="/Volumes/SomeClient"
    NGINX_DESTIONAT="/usr/local/nginx/conf/nginx.conf"
    
    if [ -z "`ls $DESTINATION`" ]; then
        echo "Trying to mount..."
        $TRUECRYPT --mount $SOURCE
    fi
    
    OLD_PATH="$PATH"
    OLD_JAVA_HOME="$JAVA_HOME"
    OLD_PS1="$PS1"
    
    export PATH="$DESTINATION/bin:$PATH"
    export JAVA_HOME="/path/to/java/1.5"
    export PS1="\[\033[01;32m\]PROJ_A:\[\033[01;34m\]\W$\[\033[0m\] "
    
    sudo rm $NGINX_DESTINATION
    sudo ln -sf $DESTINATION/nginx.conf $NGINX_DESTINATION
    
    cd $DESTINATION/project_a
    
    function deactivate {
        export PATH=$OLD_PATH
        export JAVA_HOME=$OLD_JAVA_HOME
        export PS1=$OLD_PS1
        cd ~
    }
    
    function dismount() {
        $TRUECRYPT -d $SOURCE
    }
}
```

Note that this doesn't clean up nginx's configuration, but that's OK, next project I activate will configure nginx properly.

### Conclusion

The function we just developed allows me to conveniently start working on a project by mounting the encrypted volume on demand and setting up my environment accordingly. It also provides 2 functions for deactivating this environment to return to the default environment and for unmounting the encrypted volume when done. I hope you find this useful.
