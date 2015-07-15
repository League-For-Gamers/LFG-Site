namespace :assets do
  task :gzip do
    require 'zlib'

    Dir['public/assets/**/*.{js,css}'].each do |path|
      gz_path = "#{path}.gz"
      next if File.exist?(gz_path)

      Zlib::GzipWriter.open(gz_path) do |gz|
        gz.mtime = File.mtime(path)
        gz.orig_name = path
        gz.write(IO.binread(path))
      end
    end
  end

  desc 'Synchronize assets to remote (assumes assets are already compiled)'
  task :sync => [:environment, :gzip] do
    AssetSync.sync
  end
end