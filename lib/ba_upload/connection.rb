require 'ba_upload/error_file'
module BaUpload
  class Connection
    attr_reader :m

    def initialize(key_file, cert_file, ca_cert_file)
      require 'mechanize'
      @key = key_file
      @cert = cert_file
      @ca_cert = ca_cert_file
      @m = Mechanize.new
      @m.key = @key.path
      @m.ca_file = @ca_cert.path
      @m.cert = @cert.path
    end

    def upload(file: nil)
      m.get 'https://hrbaxml.arbeitsagentur.de/in/'
      form = m.page.forms.first
      form.file_uploads.first.file_name = file
      form.submit
    end

    def error_files
      m.get 'https://hrbaxml.arbeitsagentur.de/'
      links = m.page.links_with(text: /ESP|ESV/)
      links.map do |link|
        ErrorFile.new(link)
      end
    end

    def misc
      m.get 'https://hrbaxml.arbeitsagentur.de/'
      m.page.links_with(text: /sonstiges/).first.click
      m.page.links.reject { |i| i.href[/^\?|mailto:/] || i.href == '/' }
    end

    def shutdown
      m.shutdown
    end
  end
end
