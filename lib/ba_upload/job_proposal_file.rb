module BaUpload
  class JobProposalFile
    def initialize(mechanize_link)
      @mechanize_link = mechanize_link
      @link = mechanize_link.href
    end

    def read
      response = @mechanize_link.click
      response.body
    end

    def filename
      @mechanize_link.text
    end

    def tempfile
      tf = Tempfile.new(['job_proposal', '.zip'])
      tf.binmode
      tf.write(read)
      tf.flush
      tf
    end
  end
end
