# Django on Convox Example

This repository contains an example Django 2.1 app configured for local development and deployment to Convox.

The following is a step-by-step walkthrough of how the app was configured and why. The sample app is copied from the [Django 2.1 tutorial](https://docs.djangoproject.com/en/2.1/intro/tutorial01/)

### Application Components

#### Dockerfile

Starting from the [python:3](https://hub.docker.com/_/python/) image, the [Dockerfile](https://github.com/convox-examples/django/blob/master/Dockerfile) executes the remaining build steps that your Django app needs. There are basically 2 steps in this process, and they are executed in a particular order to take advantage of Docker's build caching behavior.

1. Requirements.txt is copied and `pip install` is run. This happens first because it is slow and something that's done infrequently. After running once, this step will be cached unless the cache is busted by later edits to `requirements.txt`.

2. The application source is copied over. These files will change frequently, so this step of the build will very rarely be cached.

#### Convox.yml

The [convox.yml](https://github.com/convox-examples/django/blob/master/convox.yml) file explains how to run the application. This file has two sections.

1. Resources: These are network-attached dependencies of your application. In this case we have a single resource which is a postgres database. When [running locally](https://docs.convox.com/development/running-locally) Convox will automatically startup up a container running Postgres and will inject a ```DATABASE_URL``` environment variable into your application container that points to the Postgres database. When your application is [deployed](https://docs.convox.com/deployment/deploying-to-convox) to production Convox will startup an RDS postgres database for your application to use. 

2. Services: This is where we define our application(s). In this case we have a single application called ```web``` which is built from our dockerfile, executes the standard Django development server command to startup, and uses the postgres resources for a database. You will also notice we have an [environment](https://docs.convox.com/management/environment) section where we are setting a default secret key for development. In production application you may have additional services defined for things like Celery task workers. You will also likely use a more robust web server such as [Gunicorn](https://gunicorn.org/) in place of the built in development server. 

### Running Locally

A few steps to get started:

1. Make sure you have [Docker](https://www.docker.com/products/docker-desktop) installed on your local machine. 
2. [Signup for a Convox account](https://convox.com/signup) It's free!
3. Install the [Convox CLI](https://docs.convox.com/development/installation). 
4. Install the [Convox local Rack](https://docs.convox.com/development/running-locally)

Once you are all setup you can switch to your local rack with ```convox switch local``` and start your local application with ```convox start``` (make sure you are in the root directory).

Now that your app is up and running you will need to run the migrations with a [one-off command](https://docs.convox.com/management/one-off-commands):

```bash
convox run web python manage.py migrate
```

And create a super user for the Django Admin

```bash
convox run web python manage.py createsuperuser
```

You should now be able to access your application by going to [https://web.django.convox](https://web.django.convox). If you renamed anything you may need to modify your local URL. The format is https://[service name].[app name].convox

### Deploying to production

In order to deploy to production we have to ensure we have completed the following steps:

1. [Signup for a Convox account](https://convox.com/signup)
2. [Connect and AWS account](https://docs.convox.com/introduction/getting-started#connect-an-aws-account)
3. [Install an AWS Rack](https://docs.convox.com/introduction/getting-started#install-an-aws-rack)
4. Make sure your CLI is [logged in](https://docs.convox.com/reference/login-and-authentication) to your Convox account using ```convox login``` and your [CLI Key](https://console.convox.com/account)

Once you are all set here you can see the name of your production rack

```bash 
convox racks
```

And switch your CLI to your production rack

```bash
convox switch [rack name]
```

Now you can create an empty application in your production rack

```bash
convox apps create --wait
```

And you can deploy your application to production (the first time you do this it may take up to 15 minutes to create the necessary resources)

```bash
convox deploy --wait
```

Then you can run your migrations and create your super user same as you did against your local rack

```bash
convox run web python manage.py migrate
```

```bash
convox run web python manage.py createsuperuser
```

Finally you can retrieve the URL from your production application with

```bash
convox services
```


### Notes

Please take note of the ```ALLOWED_HOSTS``` section of [settings.py]((https://github.com/convox-examples/django/blob/master/mysite/settings.py) ). If this is not configured correctly your application will not pass the load balancer health checks.
````
ALLOWED_HOSTS = ['.convox', '.site']

# allow AWS internal IPs for healthcheck
import requests
EC2_PRIVATE_IP  =   None
try:
    EC2_PRIVATE_IP  =   requests.get('http://169.254.169.254/latest/meta-data/local-ipv4', timeout = 0.01).text
except requests.exceptions.RequestException:
    pass

if EC2_PRIVATE_IP:
    ALLOWED_HOSTS.append(EC2_PRIVATE_IP)
````

Also note that regardless of what webserver you are running it should be listening on ```0.0.0.0``` not localhost or ```127.0.0.1```


