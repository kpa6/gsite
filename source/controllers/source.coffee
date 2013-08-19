http = require 'http'

source_controller =
  process_image: (img_url, cb)->
    job_data =
      "application_id": process.env.BLITLINE_APPLICATION_ID
      "src":            "http://www.google.com/logos/2011/yokoyama11-hp.jpg"
      
      "functions":      [
        "name":              "resize_to_fill"
        
        "params":
          "width":            50
          "height":           50
        
        "save":
          "image_identifier": "MY_CLIENT_ID"
          "s3_destination":
            "bucket":         process.env.AWS_STORAGE_BUCKET_NAME_IMG
            "key":            "test_image.jpg"
            "headers":
              "x-amz-acl":    "public-read"
        ]

    options =
      host   : 'api.blitline.com'
      port   : 80
      method : "POST"
      path   : '/job'

    req = http.request options, (res)->
      res.on "data", (chunk)->
        console.log "Data=" + chunk
      
      res.on 'error', (e)->
        console.log "Got error: " + e.message

    req.write "json=" + JSON.stringify job_data
    req.end()

module.exports = source_controller