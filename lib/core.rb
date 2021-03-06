# encoding: utf-8
class Core
  ## Core attributes.
  cattr_reader   :now
  cattr_reader   :config
  cattr_reader   :title
  cattr_reader   :env
  cattr_reader   :params
  cattr_reader   :mode
  cattr_reader   :site
  cattr_reader   :script_uri
  cattr_reader   :request_uri
  cattr_reader   :internal_uri
  cattr_accessor :ldap
  cattr_accessor :user
  cattr_accessor :user_group
  cattr_accessor :dispatched
  cattr_accessor :concept
  cattr_accessor :messages
  cattr_accessor :publish

  ## Initializes.
  def self.initialize(env = nil)
    @@now          = Time.now.to_s(:db)
    @@config       = Util::Config.load(:core)
    @@title        = @@config['title'] || 'Joruri'
    @@env          = env
    @@params       = parse_query_string(env)
    @@mode         = nil
    @@site         = nil
    @@script_uri   = env['SCRIPT_URI'] || "http://#{env['HTTP_HOST']}#{env['PATH_INFO']}"
    @@request_uri  = nil
    @@internal_uri = nil
    @@ldap         = nil
    @@user         = nil
    @@user_group   = nil
    @@dispatched   = nil
    @@concept      = nil
    @@messages     = []
    @@publish      = nil # for mobile

    # require 'page'
    Page.initialize
  end

  ## Now.
  def self.now
    return @@now if @@now
    @@now = Time.now.to_s(:db)
  end

  ## Proxy.
  def self.proxy(schema = 'http')
    schema.to_s =~ /^https/ ? (@@config['https_proxy'] || @@config['http_proxy']) : @@config['http_proxy']
  end

  ## Parses query string.
  def self.parse_query_string(env)
    env['QUERY_STRING'] ? CGI.parse(env['QUERY_STRING']) : nil
  end

  ## Sets the mode.
  def self.set_mode(mode)
    old = @@mode
    @@mode = mode
    old
  end

  ## URI
  def self.full_uri
    # @@env["SCRIPT_URI"].gsub(/^([a-z]+:\/\/[^\/]+\/).*/, '\\1')
    "#{@@env['rack.url_scheme']}://#{@@env['HTTP_HOST']}/"
  end

  ## LDAP.
  def self.ldap
    return @@ldap if @@ldap
    @@ldap = Sys::Lib::Ldap.new
  end

  ## Controller was dispatched?
  def self.dispatched?
    @@dispatched
  end

  ## Controller was dispatched.
  def self.dispatched
    @@dispatched = true
  end

  ## Recognizes the path for dispatch.
  def self.recognize_path(path)
    Page.error    = false
    Page.uri      = path
    @@request_uri = path

    recognize_mode
    recognize_site

    @@internal_uri = '/404.html' unless @@internal_uri
  end

  def self.search_node(path)
    return nil unless Page.site

    if dir = Page.site.dirname
      return nil if path !~ /^\/#{Regexp.escape(dir)}/
      path = path.gsub(/^\/#{Regexp.escape(dir)}/, '')
    end

    if path =~ /\.html\.r$/
      Page.ruby = true
      path = path.gsub(/\.r$/, '')
    end
    path = path.gsub(/\.p[0-9]+\.html$/, '.html') if path =~ /\.p[0-9]+\.html$/
    path += 'index.html' if path =~ /\/$/

    ## preview
    if path =~ /^\/\*\.html(|\.r)$/
      return @@internal_uri = '/_public/cms/node_preview/'
    end

    node     = nil
    rest     = ''
    paths    = path.gsub(/\/+/, '/').split('/')
    paths[0] = '/'

    paths.size.times do |i|
      if i == 0
        current = Cms::Node.find(Page.site.node_id)
      else
        n = Cms::Node
            .where(site_id: Page.site.id)
            .where(parent_id: node.id)
            .where(name: paths[i])
        n = n.published if @@mode != 'preview'
        current = n.order(id: :desc).first
      end
      break unless current

      node = current
      rest = paths.slice(i + 1, paths.size).join('/')
    end
    return nil unless node

    Page.current_node = node
    @@internal_uri = "/_public/#{node.model.underscore.pluralize.gsub(/^(.*?\/)/, '\\1node_')}/#{rest}"
    #    return "/_public/#{node.model.underscore.pluralize.gsub(/^(.*?\/)/, "\\1node_")}/#{rest}"
  end

  def self.concept(key = nil)
    return nil unless @@concept
    key.nil? ? @@concept : @@concept.send(key)
  end

  def self.concept_id=(concept_id)
    @@concept = Cms::Concept.find_by(id: concept_id)
    @@concept = Cms::Concept.new.readable_children[0] unless @@concept
  end

  private

  def self.recognize_mode
    @@mode = if @@request_uri =~ /^#{Regexp.escape(Joruri.admin_uri)}/
               'admin'
             elsif @@request_uri =~ /^\/_[a-z]+(\/|$)/
               @@request_uri.gsub(/^\/_([a-z]+).*/, '\1')
             else
               'public'
             end
  end

  def self.recognize_site
    case @@mode
    when 'admin'
      @@site         = get_site_by_cookie
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'preview'
      site_id        = @@request_uri.gsub(/^\/_[a-z]+\/([0-9]+).*/, '\1').to_i
      site_mobile    = @@request_uri =~ /^\/_[a-z]+\/([0-9]+)m/
      @@site         = Cms::Site.find(site_id)
      Page.site      = @@site
      Page.mobile    = site_mobile
      @@internal_uri = @@request_uri
    when 'public'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = search_node @@request_uri
    when 'common'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'layouts'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'files'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'emfiles'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'tools'
      @@site         = Cms::Site.find_by_script_uri(@@script_uri)
      Page.site      = @@site
      @@internal_uri = @@request_uri
    when 'script'
      if @@env.key?('SERVER_PROTOCOL') == false
        @@site         = nil
        Page.site      = @@site
        @@internal_uri = @@request_uri
      end
    end
  end

  def self.get_site_by_cookie # admin
    site_id = get_cookie('cms_site')
    return Cms::Site.find_by(id: site_id) if site_id

    host = Cms::Site.connection.quote_string(@@env['HTTP_HOST'].to_s)
                    .gsub(/([_%])/, '\\\\\1')

    sites = Cms::Site.arel_table

    site = Cms::Site.where(sites[:admin_full_uri].matches("http://#{host}/%"))
                    .order(:id).first
    return site if site

    site = Cms::Site.where(sites[:admin_full_uri].eq(nil)
            .or(sites[:admin_full_uri].eq(''))).order(:id).first
    return site if site
  end

  def self.get_cookie(name)
    cookies = CGI::Cookie.parse(Core.env['HTTP_COOKIE'])
    return cookies[name].value.first if cookies.key?(name)
    nil
  end
end
