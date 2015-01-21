request = require('request')
fs = require('fs')
SnooCore = require('snoocore')
OAuth = require('oauth')
config = require('./config.json')

apiUrl = 'https://api.twitter.com/'
uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json'
tweetUrl = apiUrl + '/1.1/statuses/update.json'

options = {
  subreddit: '/r/SpacePorn' #which subreddit to parse
  limit: 2 #how many top posts to grab
  folder: './images/' #save the downloaded pictures
  frequency: 30 #seconds
}

#Define in config.json, from https://apps.twitter.com
keys = {
  consumer_key: config.consumer_key
  consumer_secret: config.consumer_secret
  token: config.token
  token_secret: config.token_secret
}

#authorize with OAuth, for posting tweets with media
oauth = new OAuth.OAuth(
  apiUrl + 'oauth/request_token', apiUrl + 'oauth/access_token',
  keys.consumer_key, keys.consumer_secret,
  '1.0', null, 'HMAC-SHA1'
)

reddit = new SnooCore(userAgent: 'tweetEarth@0.0.1 by /u/hawkfalcon')
#save previously posted URLs to ensure no duplicate tweets
posted = []

#grab the top hot posts from a subreddit
scrapeReddit = () ->
  console.log('Scraping reddit for fresh content!')
  reddit(options.subreddit + '/hot').listing({
  limit: options.limit
  }).then((slice) ->
    slice.children.forEach((child, i) ->
      url = child.data.url
      if url not in posted #has not been posted before
        downloadImage(url, child.data.title)
    )
  )

#parse url and download the file
downloadImage = (url, title) ->
  #flickr doesn't let you scrape
  if ~url.indexOf('.jpg') and not ~url.indexOf('staticflickr')
    console.log('>' + url)
    filename = url.replace(/\//gi, '') #remove slashes from file path
    download(url, options.folder + filename, ->
      posted.push(url) #save url to already posted
      tweetPicture(title, filename)
    )

download = (url, filename, callback) ->
  request.head(url, (err, res, body) ->
    request(url).pipe(fs.createWriteStream(filename)).on 'close', callback
  )

#two parts: upload media, send a tweet
tweetPicture = (title, filename) ->
  upload(filename, (err, response) ->
    console.log(err) if err
    console.log(response)
    media = JSON.parse(response.body)
    tweet(title, media.media_id_string, (err, response, body) ->
      console.log(err) if err
      console.log(response)
    )
  )

#upload to get a media_id
upload = (filename, callback) ->
  r = request.post(uploadUrl, oauth:keys, callback)
  form = r.form()
  form.append('media', fs.createReadStream(options.folder + filename))

#tweet using oauth and the media_id
tweet = (status, media, callback) ->
  body = (status: status, media_ids: media)
  oauth.post(tweetUrl, keys.token, keys.token_secret, body, 'application/json', callback)

#repeat forever
repeat = setInterval(->
  scrapeReddit()
  return
, options.frequency*1000)