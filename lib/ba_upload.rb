require "ba_upload/version"
require "openssl"

module BaUpload
  def self.export_certificate(file_path:, passphrase:)
    cert = OpenSSL::PKCS12.new(File.read(file_path), passphrase)
    {
      key: Tempfile.new(['key','.pem']).tap{|f| f.write(cert.key.to_s); f.flush},
      cert: Tempfile.new(['cert','.pem']).tap{|f| f.write(cert.certificate.to_s); f.flush},
      ca_cert: Tempfile.new(['ca_cert','.pem']).tap{|f| f.write(cert.ca_certs.reverse.join("\n")); f.flush }
    }
  end

  def self.open_connection(file_path:, passphrase:)
    cert = BaUpload.export_certificate(file_path: file_path, passphrase: passphrase)
    BaUpload::Connection.new(cert[:key], cert[:cert], cert[:ca_cert])
  end

  def self.postings_filename(partner_id, *args)
    params = args && args.count > 0 ? ('_' + args.join('_')) : ''
    "DS#{partner_id}_#{DateTime.now.strftime("%Y-%m-%d_%H-%M-%S")}#{params}.xml"
  end
end

require 'ba_upload/connection'
