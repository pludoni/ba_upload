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


### Downloading "misc" files

BA provides a often updated Position description databae ("VAM" Berufe). The Gem can help to download it:

```ruby
connection.misc.each do |link|
  target = "vendor/ba/#{link.href}"
  next if File.exist?(target)
  response = link.click
  File.open(target, "wb+") { |f| f.write(response.body) }
end
```

### Usage with multiple client certificats

Since September 2022, users with multiple client certificats issued to the same email address need to provide their respective partner ID when using the API.
For user with only one certificat issued to their email address, providing the partner ID is optional.

The partner ID can be provided as an optional keyword argument to the `upload`, `error_files` and `misc` methods:

```ruby
require 'ba_upload'
connection = BaUpload.open_connection(file_path: 'config/Zertifikat-1XXXX.p12', passphrase: 'YOURPASSPHRASE')

connection.upload(file: 'your_file_path', partner_id: 'P000XXXXXX')
connection.error_files(partner_id: 'P000XXXXXX')
connection.misc(partner_id: 'P000XXXXXX')

```

## Appendix: Berufe

Sooner or later, you have to provide a TitleCode = Vocation "Beruf" for each job. To fetch and process the Berufe, we create a ActiveRecord Model in our database:

Here an example of a implementation at Empfehlungsbund. You can also use our [search mask](https://login.empfehlungsbund.de/arbeitsagentur) to search for occupations.

We put the "help" / "validation" messages, that we found in the appropriate scopes, too, as "Ausbildungen" and "Duale Studiengänge" need different types of professions.

<details>
<summary>ActiveRecord Model for Ba::Profession</summary>

```ruby 
# migration:
create_table :ba_professions do |t|
 t.string "bkz"
 t.string "typ"
 t.string "lbkgruppe"
 t.string "hochschulberuf"
 t.string "kuenstler"
 t.string "bezeichnung_nl"
 t.string "bezeichnung_nk"
 t.string "suchname_nl"
 t.datetime "created_at"
 t.datetime "updated_at"
 t.integer "ebene"
 t.integer "qualifikationsniveau"
 t.datetime "deleted_on"
end
```


lbkgruppe hochschulberuf ebene kuenstler bezeichnung_nl bezeichnung_nk suchname_nl

class Ba::Profession < ApplicationRecord
  has_many :jobs

  scope :undeleted, -> { where 'deleted_on is null' }
  scope :berufe, -> { where typ: 'B' }
  scope :ausbildungen, -> { where typ: 'A' }
  scope :sorted, -> { order(Arel.sql('deleted_on is not null, bezeichnung_nl')) }
  # Bei Auswahl von „Ausbildung“ (EducationType=0) sind die Berufe mit dem
  # Qualifikationsniveau 2 zulässig. Zusätzlich sind hier alle Berufe folgender
  # berufskundlicher Gruppen erlaubt: [...]
  scope :reine_ausbildungen, -> {
    where(qualifikationsniveau: 2).or(
      where(lbkgruppe: [1150, 3110, 5130])
    ).ausbildungen
  }
  # Wird ein Stellenangebot vom Typ „Duales Studium“ (EducationType=1) übermittelt, sind der
  # Studiengang und der ggf. vorhandene Ausbildungsberuf getrennt anzugeben. Als
  # Studiengang (Course) sind Berufe mit ausschließlich dem Qualifikationsniveau 4 zulässig.
  # Diese Berufe entstammen alle der berufskundlichen Gruppe 3120 („A Grundständige
  # Studienfächer/-gänge“). Der als Ausbildung (TitleCode) angegebene Beruf darf
  # dementsprechend nicht ausschließlich das Qualifikationsniveau 4 haben.
  scope :duale_studiengaenge, -> { ausbildungen.where ebene: 3, qualifikationsniveau: 4 }

  def duales_studium?
    ebene == 3 && qualifikationsniveau == 4 && typ == 'A'
  end

  def self.download_from_ba
    require 'tty/prompt'
    prompt = TTY::Prompt.new
    link = Ba::Distributor.ba_connection.misc.last do |link|
    link.click
    target = "public/ba/#{link.href}"
    response = link.click
    File.open(target, "wb+") { |f| f.write(response.body) }

    puts "Unzipping vam_beruf_kurz.xml..."
    `unzip -o -d public/ba/ #{target} vam_beruf_kurz.xml`
  end

  def self.import(path: 'public/ba/vam_beruf_kurz.xml')
    doc = Nokogiri::XML.parse(File.open(path))
    berufe_vorher = Ba::Beruf.undeleted.pluck(:id)
    doc.search('beruf').each do |beruf_doc|
      beruf = where(id: beruf_doc['id']).first_or_initialize

      beruf.bkz = beruf_doc['bkz']

      beruf.typ = beruf_doc.at('typ').text == 't' ? 'B' : 'A'
      beruf.qualifikationsniveau = beruf_doc.at('qualifikationsNiveau[niveau]')['niveau']
      beruf_doc.search(*%w[lbkgruppe hochschulberuf ebene kuenstler bezeichnung_nl bezeichnung_nk suchname_nl]).each do |i|
        beruf.send("#{i.name}=", i.text)
      end
      beruf.save
      berufe_vorher.delete(beruf.id)
    end
    Ba::Beruf.where(id: berufe_vorher).update_all deleted_on: Time.zone.now if berufe_vorher.any?
  end
  scope :duale_studiengaenge, -> { where ebene: 3, qualifikationsniveau: 4 }

  def display_name
    prefix = if deleted_on?
               "[!VERALTET!] "
             end
    if typ == 'A'
      if ebene == 3 && qualifikationsniveau == 4
        "#{prefix}#{bezeichnung_nk} (DUALES STUDIUM/praxisorientiert)"
      else
        "#{prefix}#{bezeichnung_nk} (AUSBILDUNG)"
      end
    else
      "#{prefix}#{bezeichnung_nk}"
    end
  end

  def as_json(opts = {})
    {
      id: id,
      display_name: display_name
    }
  end
```

</details>

## Appendix: How to construct a Job-Posting XML file to upload

- Download the most recent JobPosting xsd from https://baxml.arbeitsagentur.de/geschuetzt/download/
- You can visualize the xsd here: http://www.xml-tools.net/schemaviewer.html
- Now, you can construct the file with xml-builder:

<details>
<summary>Example for constructing a feed using XmlBuilder</summary>

```ruby
    xml = Builder::XmlMarkup.new(indent: 1)
      xml.instruct!
      xml.tag!("HRBAXMLJobPositionPosting") do
        xml.tag!("Header") do
          xml.tag!("SupplierId", SUPPLIER_ID)
          xml.tag!("Timestamp", Time.zone.now.to_s(:db).tr(" ", "T"))
          xml.tag!("Amount", obs.count)
          # F: Full
          # D: Diff
          if @only_jobs
            xml.tag!("TypeOfLoad", "D")
          else
            xml.tag!("TypeOfLoad", "F")
          end
        end
        xml.tag!("Data") do
          jobs.each do |job|
            generate_xml_for_job(xml, job)
          end
          
          jobs_to_delete.each do |job|
            xml.tag! "DeleteEntry" do
              xml.tag! "EntryId", id
            end
          end
        end
      end
      xml
```
</details>

- Then, you should validate your feed:

```ruby
xsd = Nokogiri::XML::Schema(File.open("vendor/ba/HRBAXML_JobPosition_Current.xsd"))
doc = Nokogiri::XML(xml.to_s)
xsd.validate(doc)
```

- Then, you can put that into a file - so you will need to generate a filename **according to the spec**:

<details>
<summary>Generate a filename</summary>
```ruby
# for historic reasons, you could transmit a bunch of files with the same timestamp using an index/offset, but usually, just putting 0 here should be enought
index = 0
number_of_feeds_to_push_now = 1
ended = index == (number_of_feeds_to_push_now - 1)
flag = ended ? "E" : "C"
date = Time.zone.now.strftime "%Y-%m-%d_%H-%M-%S_F#{'%03d' % (index + 1)}#{flag}"
"DS#{SUPPLIER_ID}_#{date}.xml"
```
</details>

- Upload the file using this Gem. You should wait a "couple of minutes" (tip: enqueue a activeJob for 10 minutes later), to fetch the resulting **error file**, and analyse that.



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

