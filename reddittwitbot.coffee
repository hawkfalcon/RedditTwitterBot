request = require('request')
fs = require('fs')
SnooCore = require('snoocore')
OAuth = require('oauth')
config = require('./config.json')

apiUrl = 'https://api.twitter.com/'
uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json'
tweetUrl = apiUrl + '/1.1/statuses/update.json'

#authorize with OAuth, for posting tweets with media
oauth = new OAuth.OAuth(
  apiUrl + 'oauth/request_token', apiUrl + 'oauth/access_token',
  config.keys.consumer_key, config.keys.consumer_secret,
  '1.0', null, 'HMAC-SHA1'
)

reddit = new SnooCore(userAgent: 'tweetEarth@0.0.1 by /u/hawkfalcon')
#save previously posted URLs to ensure no duplicate tweets
posted = []

#grab the top hot posts from a subreddit
scrapeReddit = () ->
  console.log('Scraping reddit for fresh content!')
  reddit('/r/' + config.options.subreddit + '/hot').listing({limit: config.options.limit}).then((slice) ->
    downloadImage(child.data.url, child.data.title) for child in slice.children
  )

alreadyPosted = (url) -> 
  return url in posted

addPosted = (url) ->
  posted.push(url) #save url to already posted


#parse url and download the file
downloadImage = (url, title) ->
  #flickr doesn't let you scrape
  if ~url.indexOf('.jpg') and not ~url.indexOf('staticflickr') and not alreadyPosted(url)
    console.log('>' + url)
    path = './' + config.options.folder + '/' + url.replace(/\//gi, '') #path, no slashes
    download(url, path, ->
      addPosted(url)
      tweetPicture(title, path)
    )

download = (url, path, callback) ->
  request.head(url, (err, res, body) ->
    request(url).pipe(fs.createWriteStream(path)).on 'close', callback
  )

#two parts: upload media, send a tweet
tweetPicture = (status, path) ->
  media = fs.readFileSync(path).toString("base64")
  oauth.post(uploadUrl, config.token, config.token_secret, media: media, (err, data, res) ->
    if err 
      console.log(err)
    else
      console.log(data)
      body = (status: status, media_ids: JSON.parse(data).media_id_string)
      oauth.post(tweetUrl, config.token, config.token_secret, body, (err, data, res) ->
        console.log(err) if err
        console.log(data)
      )
  )

#repeat forever
repeat = setInterval(->
  scrapeReddit()
  return
, config.options.frequency*1000)