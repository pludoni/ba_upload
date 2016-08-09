module BaUpload
  class ErrorFile
    def initialize(mechanize_link)
      @mechanize_link = mechanize_link
      @link = mechanize_link.href
    end

    def read
      response = @mechanize_link.click
      response.xml.to_s
    end

    def filename
      @mechanize_link.text
    end

    def tempfile
      tf = Tempfile.new(['error_file', '.xml'])
      tf.write(read)
      tf.flush
      tf
    end
  end
end
