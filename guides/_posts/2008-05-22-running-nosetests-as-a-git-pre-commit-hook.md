---
layout: post
title: Running nosetests as a git pre-commit hook
---

# {{ page.title }}

<p class="meta">22 May 2008 - Chicago</p>

I've started using git for all my development recently (since it integrates so nicely with svn). I wanted to experiment with running my test as a pre-commit hook in git. In case you're curious all the hooks in git live in the hooks folder inside of .git

Inside of this folder you will see various example scripts. The names should make it obvious when each hook is supposed to run. For example the pre-commit file will run before a commit (before you're even asked for the commit message). There are also hooks that can intercept the commit message, run after updates happen, etc. By default none of these files are executable, so git doesn't actually run them. If you would like to execute a hook simply put your code in the correct file and mark it executable.

In the case of the pre-commit hook git will abort the commit if the pre-commit file returns with a status code other than 0. By default this file contains some perl code that checks for lines with trailing spaces and lines that have a space before a tab at the beginning. You can safely remove this code (I found the trailing space to be an annoying check)).

So let's say you want to run your unit tests before each commit (and abort the commit if they fail). I'm going to use nose (a Python unit testing framework) as an example. To run your nose tests you can simply issue the nosetests command. This will discover your tests, run them and exit with status code of 0 if everything passed. So you can simply put

<pre class="terminal"><code>
    #!/usr/bin/env bash
    nosetests
</code></pre>

in your pre-commit file and now your unit tests will run and your commit will abort if the are test failures. This works well, unless you have tests that you expect to fail but still have something you would like to commit. You have to choices: either remove the executable bit from the pre-commit file or adjust your script to give you some options. Here is a little script I put together to prompt you if you would like to commit anyway in the even of test failures. Keep in mind I know very little if any bash scripting so if there is a better way to do this please let me know.

<pre><code>
    nosetests
    code=$?

    if [ "$code" == "0" ]; then
    exit 0
    fi

    echo -n "Not all tests pass. Commit (y/n): "
    read response
    if [ "$response" == "y" ]; then
    exit 0
    fi

    exit $code
</code></pre>

Hope this helps.
