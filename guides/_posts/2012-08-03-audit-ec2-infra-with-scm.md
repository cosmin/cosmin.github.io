---
layout: post
title: Audit your EC2 infrastructure with source control
---

# {{ page.title }}

<p class="meta">03 August 2012 - Dallas, TX</p>

You are performing a routine analysis of request logs on an internal web server when you notice a series of interesting requests from `10.191.12.13`. A quick search determines that, as of this moment, this address does not belong to any of your servers. The requests happened 7 days ago, and much has changed during that time. Can you tell which of your instances had that IP address 7 days ago?

Just to be sure, you review the security groups for this instance to make sure only internal traffic is allowed. You discover a rule that explicitly allows traffic from `10.191.12.13`. Can you tell how long this rule has been present? Can you find the time period during which traffic from `10.191.12.13` was allowed, and yet that address did not belong to you?

These questions, and many others about the historic state of your infrastructure, could be answered easily if this information was present in a source control repository. You could then easily see when changes happened, browse to a specific point in time, and even use your source control infrastructure for things like email alerts.

This is where [ec2audit](https://github.com/SimpleFinance/ec2audit) comes in. It can write the current state of your EC2 instances, security groups and ELB volumes to a series of JSON or YAML files that are suitable for version control.

In order to set up `ec2audit` you need IAM credentials, a source control repository, and some way to run it on a schedule. At Simple, we use Jenkins to schedule the runs, and Git for source control. Things like `git log -S` make it easy to find when things changed.

To install `ec2audit`, use `pip` or `easy_install`. You can also [download a tarball](http://pypi.python.org/pypi/ec2audit) and run `python setup.py install`.

You can then run `ec2audit` as follows

```
ec2audit -I <access-key> -S <secret-key> us-east-1 -o outputdir
```

You can also supply AWS credentials via the standard environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

The AWS credentials must be granted read access to the EC2 APIs. You should create an IAM user with only the adequate permissions. If you are using the AWS Console, you can use the `Amazon EC2 Read Only Access` policy template for convenience. The following policy will also work:

<pre><code>
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "EC2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "elasticloadbalancing:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "autoscaling:Describe*",
      "Resource": "*"
    }
  ]
}
</code></pre>

Remember to run `ec2audit` regularly and version control the output. You can create an empty git repository (or use your SCM of choice), and you can run it on a schedule using `cron` or your CI server.
