require 'ba_upload/error_file'
module BaUpload
  class StatisticFile < ErrorFile
    def tempfile
      tf = Tempfile.new(['statistic_file', '.xlsx'])
      tf.binmode
      tf.write(read)
      tf.flush
      tf.rewind
      tf
    end

    def read
      @mechanize_link.click.body
    end
  end
end

