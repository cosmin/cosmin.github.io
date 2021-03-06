---
layout: post
title: Scripted installation of Java on Ubuntu
---

# Scripted installation of Java on Ubuntu (with Bash or Puppet)

<p class="meta">20 July 2011 - Dallas</p>

Every few months I need to script the installation of Java on Ubuntu, and I always seem to forget quite how to do it. I also seem to fail at finding anything useful on Google. Most of the posts either skip critical steps or involve manual steps. So I'm going to document this here for future reference.

Bash version (add sudo as necessary):

<pre><code>
add-apt-repository "deb http://archive.canonical.com/ $(lsb_release -s -c) partner"
apt-get update

echo "sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true" | debconf-set-selections
echo "sun-java6-jre shared/accepted-sun-dlj-v1-1 select true" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive aptitude install -y -f sun-java6-jre sun-java6-bin sun-java6-jdk
</code></pre>

Given that I do most of my automation with Puppet these days, here is a Puppet class that will accomplish the same.

<pre><code>
class sun_java_6 {

  $release = regsubst(generate("/usr/bin/lsb_release", "-s", "-c"), '(\w+)\s', '\1')

  file { "partner.list":
    path => "/etc/apt/sources.list.d/partner.list",
    ensure => file,
    owner => "root",
    group => "root",
    content => "deb http://archive.canonical.com/ $release partner\ndeb-src http://archive.canonical.com/ $release partner\n",
    notify => Exec["apt-get-update"],
  }

  exec { "apt-get-update":
    command => "/usr/bin/apt-get update",
    refreshonly => true,
  }

  package { "debconf-utils":
    ensure => installed
  }

  exec { "agree-to-jdk-license":
    command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
    unless => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
    path => ["/bin", "/usr/bin"], require => Package["debconf-utils"],
  }

  exec { "agree-to-jre-license":
    command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
    unless => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
    path => ["/bin", "/usr/bin"], require => Package["debconf-utils"],
  }

  package { "sun-java6-jdk":
    ensure => latest,
    require => [ File["partner.list"], Exec["agree-to-jdk-license"], Exec["apt-get-update"] ],
  }

  package { "sun-java6-jre":
    ensure => latest,
    require => [ File["partner.list"], Exec["agree-to-jre-license"], Exec["apt-get-update"] ],
  }

}

include sun_java_6
</code></pre>
