# RedditTwitterBot
A bot that gets images from Reddit and posts them to Twitter

There is now a python and a coffeescript version.

### Python
Brand new version

#### Dependencies
The python version has two dependencies to install with pip:
```
requests
oauth2
```

#### Config
```
{  
    "options": {  
        "subreddit": "EarthPorn", # Subreddit to fetch from  
        "limit": 10, # Number of posts to check  
        "frequency": 30, # How often script should run in seconds  
        "user_agent": "RedditTwitterBot/0.1 by /u/hawkfalcon" # Reddit will stop access without this
    },
    "reddit_oauth": { # Reddit credentials
        "username": "-", 
        "password": "-",
        "client_id": "-", # Get from creating app here https://www.reddit.com/prefs/apps
        "client_secret": "-"
    },
    "twitter_oauth": { # Twitter credentials
        "consumer_key": "-", # Get from here https://dev.twitter.com/oauth/overview/application-owner-access-tokens
        "consumer_secret": "-",
        "key": "-",
        "secret": "-"
    }
}
```

#### Usage
Similar config to above, only Twitter OAuth.
```
python reddittwitterbot.py
```

### Coffeescript
The original which started this project

#### Dependencies
The coffeescript version has two dependencies to install with npm (via the json):
```
npm install
```

#### Usage
```
coffee reddittwitterbot.coffee
```

### How it works
1. Uses Reddit API to get subreddit posts
   1. Get image urls, title, and post id
2. Get images themselves, encode to base64 (coffeescript version downloads them, while python keeps in memory)
3. Uses Twitter API to upload images and get media id
4. Tweet with API using media id and a link back to Reddit