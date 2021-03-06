---
layout: post
title: Things you (probably) didn't know about xargs
---

# {{ page.title }}

<p class="meta">26 June 2011 - Bangalore, India</p>

If you've spent any amount of time at a Unix command line you've probably already seen <code>xargs</code>. In case you haven't, xargs is a command used to execute commands based on arguments from standard input.


### Common use cases

I often see xargs used in combination with <code>find</code> in order to do something with the list of files returned by find.

<i>Pedantic note:</i> As people have correctly pointed out on Twitter and on Hacker News, find is a very powerful command and it has built in flags such as <code>-exec</code> and <code>-delete</code> that you can often use instead of piping to xargs. However people either don't know about the options to find, forget how to invoke -exec with it's archaic syntax, or prefer the simplicity of xargs. There are also performance implications to the various choices. I should write a follow up post on find.

<i>Contrived examples warning:</i> I needed something simple examples that would not detract from the topic. This is the best I could do given the time I had. <a target="_blank" href="https://github.com/offbytwo/offbytwo.github.com">Patches are welcome</a> :)

Recursively find all Python files and count the number of lines
<code>find . -name '*.py' | xargs wc -l </code>


Recursively find all Emacs backup files and remove them
<code>find . -name '*~' | xargs rm </code>

Recursively find all Python files and search them for the word 'import'
<code>find . -name '*.py' | xargs grep 'import' </code>


### Handling files or folders with spaces in the name

One problem with the above examples is that it does not correctly handle files or directories with a space in the name. This is because xargs by default will split on any white-space character. A quick solution to this is to tell find to delimit results with NUL (\0) characters (by supplying <code>-print0</code> to find), and to tell xargs to split the input on NUL characters as well (<code>-0</code>).

Remove backup files recursively even if they contain spaces
<code>find . -name '*~' -print0 | xargs -0 rm </code>

<i>Security note:</i> filenames can often contain more than just <a href="http://www.dwheeler.com/essays/fixing-unix-linux-filenames.html">spaces</a>.


### Placement of the arguments

In the examples above xargs reads all non-white-space elements from standard input and concatenates them into the given command line before executing it. This alone is very useful in many circumstances. Sometimes however you might want to insert the arguments into the middle of a command. The <code>-I</code> flag to xargs takes a string that will be replaced with the supplied input before the command is executed. A common choice is %.

Move all backup files somewhere else
<code>find . -name '*~' -print 0 | xargs -0 -I % cp % ~/backups </code>


### Maximum command length

Sometimes the list of arguments piped to xargs would cause the resulting command line to exceed the maximum length allowed by the system. You can find this limit with

<code>getconf ARG_MAX</code>

In order to avoid hitting the system limit, xargs has its own limit to the maximum length of the resulting command. If the supplied arguments would cause the invoked command to exceed this built in limit, xargs will split the input and invoke the command repeatedly. This limit defaults to 4096, which can be significantly lower than ARG_MAX on modern systems. You can override xargs's limit with the <code>-s</code> flag. This will be particularly important when you are dealing with a large source tree.


### Operating on subset of arguments at a time

You might be dealing with commands that can only accept 1 or maybe 2 arguments at a time. For example the diff command operates on two files at a time. The <code>-n</code> flag to xargs specifies how many arguments at a time to supply to the given command. The command will be invoked repeatedly until all input is exhausted. Note that on the last invocation you might get less than the desired number of arguments if there is insufficient input. Let's simply use xargs to break up the input into 2 arguments per line

<pre>
$ echo {0..9} | xargs -n 2

0 1
2 3
4 5
6 7
8 9
</pre>

In addition to running based on a specified number of arguments at time you can also invoke a command for each line of input at a time with <code>-L 1</code>. You can of course use an arbitrary number of lines a time, but 1 is most common. Here is how you might diff every git commit against its parent.

<code>git log --format="%H %P" | xargs -L 1 git diff </code>

### Executing commands in parallel

You might be using xargs to invoke a compute intensive command for every line of input. Wouldn't it be nice if xargs allowed you to take advantage of the multiple cores in your machine? That's what <code>-P</code> is for. It allows xargs to invoke the specified command multiple times in parallel. You might use this for example to run multiple <code>ffmpeg</code> encodes in parallel. However I'm just going to show you yet another contrived example.


Parallel sleep

<pre>
$ time echo {1..5} | xargs -n 1 -P 5 sleep

real    0m5.013s
user    0m0.003s
sys     0m0.014s
</pre>

Sequential sleep

<pre>
$ time echo {1..5} | xargs -n 1 sleep

real    0m15.022s
user    0m0.004s
sys     0m0.015s
</pre>

If you are interested in using xargs for parallel computation also consider <a href="http://www.gnu.org/software/parallel/">GNU parallel</a>. xargs has the advantage of being installed by default on most systems, and easily available on BSD and OS X, but parallel has some really nice features.
