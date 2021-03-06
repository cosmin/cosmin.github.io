---
layout: post
title: Deploying Django applications on Heroku
---

# {{ page.title }}

<p class="meta">18 January 2012 - Melbourne, Australia</p>

For a long time Ruby developers enjoyed painless deployment to [Heroku](http://www.heroku.com/)

The Python landscape was limited to Google App Engine for quite some time (and I do mean *limited* but I'll save that for another time). Once Heroku was acquired by Salesforce it seems that the market for cloud hosting of Python applications has exploded. Now we have plenty of choices such as [epio](http://ep.io "gondor) that seems to support just about everything. It's a good time to be a Python developer.

After their acquisition Heroku has released new features faster than ever. Their [Cedar](http://devcenter.heroku.com/articles/cedar) stack now officially supports Ruby, Node.js, Clojure, Java, Python and Scala. Let's take a look at how we can deploy a fairly typical, albeit simple, Django application to Heroku.

### Prerequisites: pip and virtualenv

Before we get started we'll need to install [pip](http://www.pip-installer.org/en/latest/index.html and "virtualenv)

If you have setuptools installed you should be able to install both using:

<pre>sudo easy_install pip
pip install virtualenv
</pre>

If you need more detailed instructions please take a look at [installing pip](http://www.pip-installer.org/en/latest/installing.html).

### Create git repository

You should already know how to create a new git repository.

<pre>git init myawesomeproject
cd !$
</pre>

In case you are wondering, `!$` expands to the last argument to the last command (myawesomeproject in this case).

### Create virtual-environment

If you have been using virtualenv for a while you might be used to creatting virtual environments in a folder called _ve_, _env_ or similar. For the best experience when working
 with Heroku you should however create the virtual environment directly at the root of your checkout.

<pre>virtualenv --no-site-packages .
source bin/activate
</pre>

You have now created and activated your virtual environment. You will need to run bin/activate every time you are working on this project. While we're at it let's also ignore the virtualenv artifacts. Put the following in your .gitignore file

<pre>
/bin
/include
/lib
/share
</pre>

While you're at it you should also consider adding `*.pyc` to .gitignore.

### Install dependencies and freeze

For a simple Django application you will only need Django and psycopg2 (to talk to Postgres). Install them using pip and then freeze the exact versions used to a file called requirements.txt. Heroku will use requirements.txt to automatically install your dependencies when you push.

<pre>pip install Django psycopg2
pip freeze > requirements.txt
</pre>

When you add new requirements to your project you can `pip install` them directly and regenerate _requirements.txt_ with `pip freeze`.

### Create Django application

Now you can create a Django project

`django-admin.py startproject myproject`

and make it awesome...

### Handling database migrations

You are going to quickly need to migrate your database schema. Fortunately you can use Django [South](http://south.aeracode.org/) to handle data and schema migrations. Install it with pip

`pip install south`

and re-create your requirements file.

`pip freeze > requirements.txt`

Add it to your `INSTALLED_APPS` in `settings.py` and start converting your applications using `convert_to_south`

`myawesomeproject/manage.py syncdb`
`myawesomeproject/manage.py convert_to_south your_application`

Let's also tell South that our current database schema is up to date, by fake applying the initial migration.

`myawesomeproject/manage.py migrate --fake your_application`

Now every time you make a change to your Django models, you can create new migrations and apply them.

<pre><code>myawesomeproject/manage.py schema_migration --auto your_application
myawesomeproject/manage.py schema_migration migrate your_application
</code></pre>

You can learn more about South, including using it for data migrations, by checking out the [tutorial](http://south.aeracode.org/docs/tutorial/index.html and "documentation)

### Handling static files

In a more traditional hosting setup you might use Apache or Nginx to handle serving static files. When deploying to Heroku though you should consider hosting your static files in S3. Luckily Django can easily support a variety of storage backends, and the [django-storages](http://django-storages.readthedocs.org/en/latest/index.html) package allows you to easily use S3.

First, create a bucket in S3, using either the [AWS Console](http://aws.amazon.com/console/) or your favorite tool. Then, modify your `settings.py` and add the following values:

```
import os

AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = '<YOUR BUCKET NAME>'

STATICFILES_STORAGE = 'storages.backends.s3boto.S3BotoStorage'
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto.S3BotoStorage'

STATIC_URL = 'http://' + AWS_STORAGE_BUCKET_NAME + '.s3.amazonaws.com/'
ADMIN_MEDIA_PREFIX = STATIC_URL + 'admin/'
```


Notice that we are using environment variables to store the AWS access key and secret key. While we are on this topic, if you are planning to open source the Django application you are deploying, consider also storing your `SECRET_KEY` in an environment variable.

`SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')`

We are now ready to Deploy to Heroku.

### Creating an environment in Heroku

Let's start by installing the Heroku gem

`gem install heroku`

followed by creating a new Cedar stack in Heroku.

`heroku create --stack cedar`

Optionally, you might want to map your own domain name to your Heroku stack.

<pre><code>heroku addons:add custom_domains
heroku domains:add www.example.com
heroku domains:add example.com
</code></pre>

You can find information on managing custom domains in Heroku [here](http://devcenter.heroku.com/articles/custom-domains)

Let's add the necessary environment variables (do the same for `SECRET_KEY` if necessar)

<pre><code>heroku config:add AWS_ACCESS_KEY_ID=youraswsaccesskey
heroku config:add AWS_SECRET_ACCESS_KEY=yourawssecretkey
</code></pre>

For extra security you should use the Identity & Access Management (IAM) service to create a separate user account with the following policy

<pre><code> {
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::BUCKETNAME",
        "arn:aws:s3:::BUCKETNAME/*"
      ]
    }
  ]
}</code></pre>

This way if the credentials stored in Heroku are ever compromised, the attacker will only have access to the files stored in the bucket of this application.

### Deploying application to Heroku

This is as easy as running running git push.

`git push heroku master`

Your application is now deployed, but you still need to configure the database

`heroku run manage.py syncdb`
`heroku run manage.py migrate`

You should now have a working application, but we have not yet deployed our static files.

`heroku run manage.py collectstatic`

At this point you should have a fully functional Django application deployed to Heroku with static files hosted in S3. If you are having problems you can investigate the logs with `heroku logs`. You can also consider turning on `DEBUG` temporarily, but *don't* forget to turn this off. To make it easier to turn DEBUG on and off consider adding the following to your `settings.py`

<pre><code>DEBUG = bool(os.environ.get('DJANGO_DEBUG', ''))
TEMPLATE_DEBUG = DEBUG
</code></pre>

Now you can turn debug on and off using `heroku config:add DJANGO_DEBUG=true` and turning it off with `heroku config:remove DJANGO_DEBUG`
