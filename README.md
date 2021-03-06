# :rocket: Mission Control [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/calendly/mission-control/blob/master/LICENSE) [![Build Status](https://travis-ci.org/calendly/mission-control.svg?branch=master)](https://travis-ci.org/calendly/mission-control) [![Coverage Status](https://coveralls.io/repos/github/calendly/mission-control/badge.svg?branch=master)](https://coveralls.io/github/calendly/mission-control?branch=master)

Mission Control is an application to enforce more complex Github Review rules.


## Getting Started

### Setup Mission Control Server
###### Deploy the App
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

###### Generate Credentials
* [Generate an Access Token](https://github.com/settings/tokens)
* Generate a random string to be used as your Webhook Secret.

###### Add Credentials to Mission Control
* Go to your Heroku App and select Settings => Reveal Config Vars
* Set `MISSION_CONTROL_GITHUB_ACCESS_TOKEN` to your Access Token generated above
* Set `MISSION_CONTROL_GITHUB_WEBHOOK_SECRET` to your Webhook Secret generated above

### Add Mission Control to a Project
###### Setup `.mission-control.yml` File
* Create a file with the correct format in the root of the project you would like to manage. See [Example](https://github.com/calendly/mission-control/blob/master/samples/.mission-control.yaml)

###### Setup Webhook
* From your Github Project, select Settings => Webhooks => Add Webhook
* Set `Payload URL` to `#{heroku_app_url}/hooks/github`
* Set `Content Type` to `application/json`
* Set `Secret` to the Webhook Secret generated above
* Select `Let me select individual events` and select `Pull Requests` and `Pull Request Reviews`
* Save

###### Configure Github
* You should configure github to have your branches (such as `master`) set to protected along with required status checks being enabled. You can view and manage your projects settings at Settings => Branches

## Understanding the `.mission-control.yml` Format

See the [example .mission-control.yml](https://github.com/calendly/mission-control/blob/master/example/.mission-control.yml) to understand the basic layout and options that are allowed.

Notes:
* Users is required and indicates which users can provide this approval
* Name is used to provide context in the Github Status
* Count is optional and defaults to `1` if not provided.
* Paths is optional and defaults to `*` if not provided.
* Paths uses the gitignore pathspec syntax.


## Contributing to Mission Control

###### Run the App Locally

To run the app locally, you will need to setup a webhook that points to your local machine via a tool like ngrok or forwardhq. You should setup this webhook with a Webhook Secret. You will also need to generate a Github Access Token (as seen above).

Create a `.env` file locally that contains the following, replacing the values with your created values.
````
export MISSION_CONTROL_GITHUB_ACCESS_TOKEN=access_token
export MISSION_CONTROL_GITHUB_WEBHOOK_SECRET=webhook_secret
````

###### Run the App

````
bundle install
bundle exec foreman start
````

###### Run the Specs

````
bundle install
bundle exec rspec
````

###### Run the Linter

````
bundle install
bundle exec rubocop
````
