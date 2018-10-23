# Bundesagentur fuer Arbeit upload

[![Gem Version](https://badge.fury.io/rb/ba_upload.svg)](https://badge.fury.io/rb/ba_upload)

This is a Ruby Gem that aids to simplify interaction with the API of the Arbeitsagentur of Germany.

Since early 2016 Arbeitsagentur switched to a HTTPS client certificate (hrbaxml.arbeitsagentur.de) instead their beloved FTP upload tool. The OpenSSL library helps to convert that cert to a format Mechanize/curl can understand.

## Installation

Needs Ruby > 2.1 with OpenSSL.

Add this line to your application's Gemfile:

```ruby
gem 'ba_upload'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ba_upload

## Usage

```ruby
require 'ba_upload'

# your supplied certificate and passphrase
connection = BaUpload.open_connection(file_path: 'config/Zertifikat-1XXXX.p12', passphrase: 'YOURPASSPHRASE')

# Upload a xml-file
connection.upload(file: File.open('/opt/vam-transfer/data/DSP000132700_2016-08-08_05-00-09.xml'))

# later cronjob to download all error files

connection.error_files.each do |error_file|
  target_path = "/opt/vam-transfer/data/#{error_file.filename}"
  next if File.exists?(target_path)
  tf = error_file.tempfile
  FileUtils.cp(tf.path, target_path)
end
```

### Usage from outside Ruby (e.g. Cronjob/script):

```ruby
#!/usr/bin/env ruby
require 'ba_upload'
connection = BaUpload.open_connection(file_path: 'config/Zertifikat-1XXXX.p12', passphrase: 'YOURPASSPHRASE')
connection.upload(file: File.open(ARGV[0]))
```

Save to a file and just run it with the xml file as argument



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

