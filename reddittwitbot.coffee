request = require('request')
fs = require('fs')
snoocore = require 'snoocore'
config = require('./config.json')

api_url = 'https://api.twitter.com/1.1/statuses/update_with_media.json'

auth_settings = {
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
  limit: 10
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
  post(title, filename, (err, response) ->
    console.log(err) if err
    console.log(response)
  )

repeat = setInterval(->
  scrapeReddit()
  return
, 30000)
 
post = (status, file_path, callback) ->
  r = request.post(api_url, oauth:auth_settings, callback)
  form = r.form()
  form.append('status', status)
  form.append('media[]', fs.createReadStream('./images/' + file_path))