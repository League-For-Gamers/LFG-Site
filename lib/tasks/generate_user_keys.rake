namespace :db do
  task :generate_user_keys => :environment do
  	User.all.each do |user|
  		user.save
  	end
  end

  task :reencrypt_email_addresses => :environment do
    User.all.each do |user|
      puts "Processing #{user.username}..."
      begin
        # Decrypt.
        decrypt = OpenSSL::Cipher::AES256.new(:CBC)
        decrypt.decrypt
        decrypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + user.username)
        decrypt.iv = user.email_iv
        address = decrypt.update(user.email) + decrypt.final

        # Encrypt.
        crypt = OpenSSL::Cipher::AES256.new(:CBC)
        crypt.encrypt
        crypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + user.enc_key)
        iv = user.email_iv || crypt.random_iv
        crypt.iv = iv
        user.email_iv = iv
        user.email = crypt.update(address) + crypt.final
        user.save
      rescue OpenSSL::Cipher::CipherError
        puts "#{user.username} could not be decrypted with old cipher, assuming they're already on the new cipher"
      end
    end
  end
end