require 'ba_upload/error_file'
require 'ba_upload/statistic_file'
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

    def upload(file: nil, partner_id: nil)
      url = base_url(partner_id) + "in/"
      m.get(url)
      form = m.page.forms.first
      form.file_uploads.first.file_name = file
      form.submit
    end

    def error_files(partner_id: nil)
      url = base_url(partner_id)
      m.get(url)
      links = m.page.links_with(text: /ESP|ESV/)
      links.map do |link|
        ErrorFile.new(link)
      end
    end

    def statistics(partner_id: nil)
      url = base_url(partner_id) + "Statistiken"
      m.get(url)
      m.page.links_with(text: /xlsx/).map do |link|
        StatisticFile.new(link)
      end
    end

    def misc(partner_id: nil)
      url = base_url(partner_id)
      m.get url
      m.page.links_with(text: /sonstiges/).first.click
      m.page.links.reject { |i| i.href[/^\?|mailto:/] || i.href == '/' }
    end

    def shutdown
      m.shutdown
    end

    private

    def base_url(partner_id)
      url = "https://hrbaxml.arbeitsagentur.de/"
      url += "daten/#{partner_id}/" unless partner_id.nil?
      url
    end
  end
end
