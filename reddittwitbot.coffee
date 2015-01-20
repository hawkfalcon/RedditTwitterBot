request = require('request')
fs = require('fs')
snoocore = require('snoocore')
config = require('./config.json')

apiUrl = 'https://api.twitter.com/1.1/statuses/update_with_media.json'
uploadUrl = 'https://upload.twitter.com/1.1/media/upload.json'
tweetUrl = 'https://api.twitter.com/1.1/statuses/update.json'

oauth = {
  consumer_key: config.consumer_key
  consumer_secret: config.consumer_secret
  token: config.token
  token_secret: config.token_secret
}

reddit = new snoocore(userAgent: "tweetEarth@0.0.1 by /u/hawkfalcon")

posted = []

scrapeReddit = () ->
  console.log("Scraping reddit for fresh content!")
  reddit('/r/EarthPorn/hot').listing({
  limit: 1
  }).then((slice) ->
    slice.children.forEach((child, i) ->
      url = child.data.url
      if url not in posted
        downloadImage(url, child.data.title)
    )
  )

downloadImage = (url, title) ->
  #flickr doesn't let you scrape
  if ~url.indexOf(".jpg") and not ~url.indexOf("staticflickr")
    console.log(">" + url)
    filename = url.replace(/\//gi, '') #Remove slashes
    download(url, "./images/" + filename, ->
      posted.push(url)
      tweetPicture(title, filename)
    )

download = (url, filename, callback) ->
  request.head(url, (err, res, body) ->
    request(url).pipe(fs.createWriteStream(filename)).on "close", callback
  )

tweetPicture = (title, filename) ->
  upload(filename, (err, response) ->
    console.log(err) if err
    console.log(response)
    media = JSON.parse(response.body)
    console.log(">" + media.media_id_string)
    tweet(title, media.media_id_string, (err, response) ->
      console.log(err) if err
      console.log(response)
    )
  )

upload = (filename, callback) ->
  r = request.post(uploadUrl, oauth:oauth, callback)
  form = r.form()
  form.append('media', fs.createReadStream('./images/' + filename))

tweet = (status, media, callback) ->
  console.log(media)
  r = request.post(tweetUrl, oauth:oauth, callback)
  form = r.form()
  form.append('media_ids', media)
  form.append('status', status)

repeat = setInterval(->
  scrapeReddit()
  return
, 3000)