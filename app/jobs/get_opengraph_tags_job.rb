class GetOpengraphTagsJob < ActiveJob::Base
  queue_as :low_priority

  def perform(post)
    # Get the first URL
    link = post.body.slice URI.regexp(['http', 'https'])
    result = {}
    # If I dont set the useragent, imgur returns fucky data. It is fucking weird
    http = HTTPClient.new(default_header: {"User-Agent" => "League-For-Gamers"})
    http.transparent_gzip_decompression = true # This is being so weird. I don't even.
    unless link.nil?
      required_keys = ["title", "url"]
      list = {}
      twitter_list = {}
      begin
        head_req = http.head(link)
        type = MIME::Types[head_req.content_type].first
        
        if type == 'text/html'
          doc = Nokogiri::HTML.parse(http.get_content(link))
          doc.css('meta').each do |e|
            if e.attribute('property') and e.attribute('property').value[0..1] == "og"
              tags = e.attribute('property').value[3..-1].split(':')
              list[tags[0]] = {} unless list.has_key? tags[0]
              # I'd like to make some recursive crap but I dont think we'll get tags
              # with more than one child and this is smaller
              if tags.size > 1
                list[tags[0]][tags[1]] = {} unless list[tags[0]].has_key? tags[1]
                list[tags[0]][tags[1]][:value] = e.attribute('content').value  unless list[tags[0]][tags[1]].has_key? :value
              else
                list[tags[0]][:value] = e.attribute('content').value
              end
            end
            if e.attribute('name') and e.attribute('name').value[0..6] == "twitter"
              tags = e.attribute('name').value[8..-1].split(':')
              twitter_list[tags[0]] = {} unless twitter_list.has_key? tags[0]
              # I'd like to make some recursive crap but I dont think we'll get tags
              # with more than one child and this is smaller
              if tags.size > 1
                twitter_list[tags[0]][tags[1]] = {} unless twitter_list[tags[0]].has_key? tags[1]
                twitter_list[tags[0]][tags[1]][:value] = e.attribute('content').value unless twitter_list[tags[0]][tags[1]].has_key? :value
              else
                twitter_list[tags[0]][:value] = e.attribute('content').value
              end
            end
            
          end
          # Check if the list has all required keys for opengraph
          unless list.empty? and required_keys & list.keys == required_keys
            if list.has_key? "type"
              case list["type"][:value]
              # TODO: Article and music handling
              when /\Avideo(\.[\w]+)?\z/ien
                # Fuck you vid.me, reread the fucking spec.
                # I shouldn't have to make a gods damned special case for your shitty site
                if list["site_name"][:value].downcase == "vid.me"
                  result[:video_url] = twitter_list["player"]["stream"][:value]
                else
                  result[:video_url] = list["video"][:value] if list["video"].has_key? :value
                  result[:video_url] = list["video"]["secure_url"][:value]  if list["video"].has_key? "secure_url"
                end
                result[:video_height], result[:video_width] = 
                  list["video"]["height"][:value], list["video"]["width"][:value] if list["video"].has_key? "height" and list["video"].has_key? "width"
              end
            end
            result[:title], result[:url], result[:original_url] = 
              list["title"][:value], list["url"][:value], link

            result[:image] = list["image"][:value] if list.has_key? "image"
            result[:site_name] = list["site_name"][:value] if list.has_key? "site_name"
            result[:description] = list["description"][:value][0..512] if list.has_key? "description"
            if result.has_key? :video_url
              head = http.head(result[:video_url])
              if defined? head.content_type
                result[:mime_type] = MIME::Types[head.content_type].first.media_type
              end
            end
          end
        end
      rescue
        # For if HTTP or nokogiri fails
      end
    end
    # Check to see if the image file exists and is of appropriate file size
    if result.has_key? :image
      begin
        head_req = http.head result[:image]
        length = !head_req.header["content-length"].empty? ? head_req.header["content-length"].first.to_i : 0
        if length <= 1048576
          # Download the image and ensure it does not exceed the maximum filesize
          counter = 0
          http.get_content result[:image] do |c|
            # downloads image in a chunked format, the chunk.size results in the filesize in octets, bytes
            counter += c.size
            break if counter > 1048576
          end
          if counter > 1048576
            result.delete(:image)
          end
        else
          result.delete(:image)
        end
      rescue
      end
    end
    post.extra_data = result
    post.extra_data_date = DateTime.now if result != {}
    post.enable_save_callbacks = false
    post.save
    result
  end
end
