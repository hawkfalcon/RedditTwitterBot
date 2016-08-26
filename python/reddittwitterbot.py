import oauth2 as oauth
import requests
import requests.auth
import urllib.parse
from html import unescape
import threading

import base64
import json

reddit_access_token_url = 'https://www.reddit.com/api/v1/access_token'
reddit_posts_url = 'https://oauth.reddit.com/r/'
reddit_posts_path = '/hot'

twitter_upload_url = 'https://upload.twitter.com/1.1/media/upload.json'
twitter_tweet_url = 'https://api.twitter.com/1.1/statuses/update.json'

config = json.load(open('config.json'))

posted = open('data.log').read().splitlines()

def get_reddit_access_token():
   reddit_oauth = config['reddit_oauth']
   client_auth = requests.auth.HTTPBasicAuth(reddit_oauth['client_id'], reddit_oauth['client_secret'])

   post_data = {'grant_type': 'password', 'username': reddit_oauth['username'], 'password': reddit_oauth['password']}
   headers = {'User-Agent': config['options']['user_agent']}

   response = requests.post(reddit_access_token_url, auth=client_auth, data=post_data, headers=headers)
   json = response.json()

   return json['access_token']


def get_reddit_images(access_token):
   params = {'limit': config['options']['limit']}
   headers = {'Authorization': 'bearer ' + access_token, 'User-Agent': config['options']['user_agent']}
   reddit_url = reddit_posts_url + config['options']['subreddit'] + reddit_posts_path

   response = requests.get(reddit_url, params=params, headers=headers)
   json = response.json()

   children = json['data']['children']
   images = []

   for child in children:
      data = child['data']
      url = unescape(data['url'])
      if url not in posted:
         images.append((url, data['title'], data['id']))
         
         posted.append(url)
         with open('data.log', 'a') as log:
            log.write(url + '\n')

   return images


def get_base64_image(url):
   image = requests.get(url).content
   return base64.b64encode(image)

def twitter_oauth_request(url, http_method='GET', post_body='', http_headers=''):
   twitter_oauth = config['twitter_oauth']
   consumer = oauth.Consumer(key=twitter_oauth['consumer_key'], secret=twitter_oauth['consumer_secret'])
   token = oauth.Token(key=twitter_oauth['key'], secret=twitter_oauth['secret'])
   client = oauth.Client(consumer, token)

   resp, content = client.request(url, method=http_method, body=urllib.parse.urlencode(post_body), headers=urllib.parse.urlencode(http_headers))
   return content
 
def twitter_tweet_image(url, title):
   image = get_base64_image(url)

   body = {'media_data': image}
   headers = {'Content-type': 'multipart/form-data'}
   media_id = twitter_oauth_request(twitter_upload_url, 'POST', body, headers)

   media_id_json = json.loads(media_id.decode('utf-8'))

   if not 'error' in media_id_json:
      body = {'status': title, 'media_ids': media_id_json['media_id'], 'tweet_mode':'extended'}
      resp = twitter_oauth_request(twitter_tweet_url, 'POST', body)
      print('Tweeted')
   else:
      print('Ignored')

def create_title(title, id):
  if (len(title) >= 85): #140 max, - 26 for '... http://redd.it/123456 ' and 22 for pic.twitter link
     return title[:85] + '... http://redd.it/' + id
  else: 
     return title + ' http://redd.it/' + id

def tweet_reddit_pics():
   print('Scraping reddit for fresh content!')
   
   token = get_reddit_access_token()
   reddit_images = get_reddit_images(token)

   for (url, title, id) in reddit_images:
      title = create_title(title, id)
      print(title)
      print(url)

      twitter_tweet_image(url, title)
      print()

   threading.Timer(config['options']['frequency'], tweet_reddit_pics).start()

tweet_reddit_pics()


