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
posted = fs.readFileSync("data.log").toString().split('\n')

#grab the top hot posts from a subreddit
scrapeReddit = () ->
  console.log('Scraping reddit for fresh content!')
  reddit('/r/' + config.options.subreddit + '/hot').listing({limit: config.options.limit}).then((slice) ->
    downloadImage(child.data.url, child.data.title, child.data.id) for child in slice.children
  )

alreadyPosted = (url) -> 
  return url in posted

addPosted = (url) ->
  posted.push(url) #save url to already posted
  fs.appendFileSync('data.log', url + '\n')

#parse url and download the file
downloadImage = (url, title, id) ->
  #flickr doesn't let you scrape
  if ~url.indexOf('.jpg') and not ~url.indexOf('staticflickr') and not alreadyPosted(url)
    console.log('>' + url)
    path = './' + config.options.folder + '/' + url.replace(/\//gi, '') #path, no slashes
    download(url, path, ->
      addPosted(url)
      tweetPicture(title, path, id)
    )

download = (url, path, callback) ->
  request.head(url, (err, res, body) ->
    request(url).pipe(fs.createWriteStream(path)).on 'close', callback
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
        console.log(err) if err
        console.log(JSON.parse(data).entities.media[0].url)
      )
  )

scrapeReddit()
#repeat forever
repeat = setInterval(->
  scrapeReddit()
  return
, config.options.frequency*1000)