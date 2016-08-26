request = require('request')
fs = require('fs')
OAuth = require('oauth')
config = require('./config.json')

redditUrl = 'https://www.reddit.com/r/'
redditPath = '/hot/.json?limit=' + config.options.limit

apiUrl = 'https://api.twitter.com/'
uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json'
tweetUrl = apiUrl + '/1.1/statuses/update.json'

#authorize with OAuth, for posting tweets with media
oauth = new OAuth.OAuth(
  apiUrl + 'oauth/request_token', apiUrl + 'oauth/access_token',
  config.keys.consumer_key, config.keys.consumer_secret,
  '1.0A', null, 'HMAC-SHA1'
)

options = {
  url: redditUrl + config.options.subreddit + redditPath,
  json: true, 
  headers: {
    'User-Agent': 'RedditTwitterBot by /u/hawkfalcon v0.1'
  }
}

#save previously posted URLs to ensure no duplicate tweets
posted = fs.readFileSync("data.log").toString().split('\n')

#grab the top hot posts from a subreddit
scrapeReddit = () ->
  request(options, (err, res, body) ->
    downloadImage(child.data.url, child.data.title, child.data.id) for child in body.data.children
  )
  console.log('Scraping reddit for fresh content!')

addPosted = (url) ->
  posted.push(url) #save url to already posted
  fs.appendFileSync('data.log', url + '\n')

#parse url and download the file
downloadImage = (url, title, id) ->
  #flickr doesn't let you scrape
  if ~url.indexOf('.jpg') and not ~url.indexOf('staticflickr') and not url in posted
    console.log('>' + url)
    path = './' + config.options.folder + '/' + url.replace(/\//gi, '') #path, no slashes

    request(url).pipe(fs.createWriteStream(path)).on('close', ->
      addPosted(url)
      tweetPicture(title, path, id)
    )

parseTitle = (status) ->
  if status.length >= 90 #140 max, - 26 for '... http://redd.it/123456 ' and 22 for pic.twitter link
    status.substring(0, 90) + '... http://redd.it/'
  else 
    status + ' http://redd.it/'

#two parts: upload media, send a tweet
tweetPicture = (status, path, id) ->
  media = fs.readFileSync(path).toString("base64")
  oauth.post(uploadUrl, config.keys.token, config.keys.secret, media: media, (err, data, res) ->
    if err 
      console.log(err)
    else
      body = (status: parseTitle(status) + id, media_ids: JSON.parse(data).media_id_string) #id adds 20 chars
      oauth.post(tweetUrl, config.keys.token, config.keys.secret, body, (err, data, res) ->
        if err
          console.log(err) 
        else
          console.log(JSON.parse(data).entities.media[0].url)
      )
  )

scrapeReddit()
#repeat forever
repeat = setInterval(->
  scrapeReddit()
  return
, config.options.frequency*1000)