# Image Bot

Image Bot

## Setup

#### Dependencies

Install these dependencies using [Homebrew](). They're used for image compression.

`brew install advancecomp gifsicle jpegoptim jpeg optipng pngcrush`

#### Code

* `git clone https://github.com/erikperson/image-bot.git`
* `cd image-bot`
* `bundle`

#### settings.yml

* `cp config/example_settings.yml config/settings.yml`
** `config/settings.yml` is listed in `.gitignore`. You'll need to repeat this step for production.
* Create a Github user for your bot.
* Add the new username and password to `config/settings.yml`.
* [Register a new OAuth application with Github](https://github.com/settings/applications/new).
* Copy the client id and secret to `config/settings.yml`.
* Add a random string to the `state` setting in `config.settings.yml`
** Easy way to generate this string is to create a new Rails app (`rails new statestring && cd statestring`), then `rake secret`.
* Add the repository owner and repository name to `config/settings.yml`.
** Ex: In <https://github.com/erikperson/bot-images/>, `erikperson` is the repository owner, and `bot-images` is the repository name.

#### Post-Receive Hook

Github will POST to an arbitrary url after every push it receives. The bot uses this POST request


## Running

#### Development

`ruby app.rb`

#### Testing

To simulate the github post-receive hook, we can manually POST a greatly simplified payload to our Sinatra app.

This is what the payload looks like.
```json
{
  "after": "<hash of last commit>",
  "commits": [
    {
      "added": [ "<path to existing .png image>" ]
    }
  ],
  "ref": "refs/heads/master"
}
```

Example cURL POST request
`curl --data '{"after": "f8231858c270d2bab0ccf1b694d558f5553a4cc6","commits": [{"added": ["subdir/subbot.png"]}],"ref": "refs/heads/master"}' http://localhost:4567`


### Todo
* What if the bot's commit is not a fast forward?
* Handle [rate limiting](http://developer.github.com/v3/#rate-limiting)
* Only watch a particular branch(es)

### Reference

This is what a typical payload sent by Github's Post-Receive hook looks like. Some minor details have been replaced with "<...>" for brevity.
```json
{
  "after": "f8231858c270d2bab0ccf1b694d558f5553a4cc6",
  "before": "0f5631c800fe0bdc8ab4c7387c15e85723ca4382",
  "commits": [
    {
      "added": [ "subdir/subbot.png" ],
      "author": <...>,
      "committer": <...>,
      "distinct": true,
      "id": "f8231858c270d2bab0ccf1b694d558f5553a4cc6",
      "message": "Adding a subdirectory with a compressible image.",
      "modified": [],
      "removed": [],
      "timestamp": "2013-01-22T12:31:01-08:00",
      "url": "https://github.com/erikperson/bot-images/commit/f8231858c270d2bab0ccf1b694d558f5553a4cc6"
    }
  ],
  "compare": "https://github.com/erikperson/bot-images/compare/0f5631c800fe...f8231858c270",
  "created": false,
  "deleted": false,
  "forced": false,
  "head_commit": {
    "added": [ "subdir/subbot.png" ],
    "author": <...>,
    "committer": <...>,
    "distinct": true,
    "id": "f8231858c270d2bab0ccf1b694d558f5553a4cc6",
    "message": "Adding a subdirectory with a compressible image.",
    "modified": [],
    "removed": [],
    "timestamp": "2013-01-22T12:31:01-08:00",
    "url": "https://github.com/erikperson/bot-images/commit/f8231858c270d2bab0ccf1b694d558f5553a4cc6"
  },
  "hook_callpath": "new",
  "pusher": <...>,
  "ref": "refs/heads/master",
  "repository": {
    "created_at": "2013-01-22T12:23:28-08:00",
    "description": "",
    "fork": false,
    "forks": 0,
    "has_downloads": true,
    "has_issues": true,
    "has_wiki": true,
    "id": 7760491,
    "name": "bot-images",
    "open_issues": 0,
    "owner": <...>,
    "private": false,
    "pushed_at": "2013-01-22T12:31:08-08:00",
    "size": 152,
    "stargazers": 0,
    "url": "https://github.com/erikperson/bot-images",
    "watchers": 0
  }
}
```