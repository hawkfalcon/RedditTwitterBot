request = require('request')
fs = require('fs')
SnooCore = require('snoocore')
OAuth = require('oauth')
config = require('./config.json')

apiUrl = 'https://api.twitter.com/'
uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json'
tweetUrl = apiUrl + '/1.1/statuses/update.json'

options = {
  subreddit: '/r/EarthPorn' #which subreddit to parse
  limit: 10 #how many top posts to grab
  folder: './images/' #save the downloaded pictures
  frequency: 30 #seconds
}

#authorize with OAuth, for posting tweets with media
oauth = new OAuth.OAuth(
  apiUrl + 'oauth/request_token', apiUrl + 'oauth/access_token',
  config.consumer_key, config.consumer_secret,
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
  media = fs.readFileSync(options.folder + filename).toString("base64")
  oauth.post(uploadUrl, config.token, config.token_secret, media: media, (err, data, res) ->
    console.log(err) if err
    console.log(data)
    body = (status: title, media_ids: JSON.parse(data).media_id_string)
    oauth.post(tweetUrl, config.token, config.token_secret, body, (err, data, res) ->
      console.log(err) if err
      console.log(data)
    )
  )

#repeat forever
repeat = setInterval(->
  scrapeReddit()
  return
, options.frequency*1000)