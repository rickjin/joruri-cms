# encoding: utf-8
class Article::Script::EventDocsController < Cms::Controller::Script::Publication
  def publish
    today = Date.today
    0.upto(12) do |i|
      date = today << i
      uri  = "#{@node.public_uri}#{date.strftime('%Y/%m/')}"
      path = "#{@node.public_path}#{date.strftime('%Y/%m/')}"
      break unless publish_page(@node, uri: uri, site: @site, path: path, dependent: (0 - i).to_s)
    end
    1.upto(12) do |i|
      date = today >> i
      uri  = "#{@node.public_uri}#{date.strftime('%Y/%m/')}"
      path = "#{@node.public_path}#{date.strftime('%Y/%m/')}"
      break unless publish_page(@node, uri: uri, site: @site, path: path, dependent: (0 + i).to_s)
    end
    render text: 'OK'
  end
end
