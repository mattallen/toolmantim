require 'rubygems'
gem 'sinatra', '~> 0.3'
require 'sinatra'

__DIR__ = File.dirname(__FILE__)

%w(article quip).each do |model|
  require File.join(File.dirname(__FILE__), "/lib/#{model}")
end

Article.path = File.join(Sinatra.application.options.root, "articles")

# Add Ruby 1.9's xmlschema method
class Date
  def xmlschema
    strftime("%Y-%m-%dT%H:%M:%S%Z")
  end unless defined?(xmlschema)
end

helpers do
  def article_path(article)
    "/articles/#{article.slug}"
  end
  def next_article(article)
    next_index = @articles.index(article) - 1
    @articles[next_index] unless next_index < 0
  end
  def previous_article(article)
    prev_index = @articles.index(article) + 1
    @articles[prev_index] unless prev_index > @articles.length + 1
  end
  def versioned_stylesheet(stylesheet)
    "/stylesheets/#{stylesheet}.css?" + File.mtime(File.join(Sinatra.application.options.views, "stylesheets", "#{stylesheet}.sass")).to_i.to_s
  end
  def versioned_js(js)
    "/javascripts/#{js}.js?" + File.mtime(File.join(Sinatra.application.options.public, "javascripts", "#{js}.js")).to_i.to_s
  end
  def partial(name)
    haml(:"_#{name}", :layout => false)
  end
  def article_html(article)
    haml(article.template, :layout => false)
  end
  def article_image_path(article, image)
    "/images/articles/#{article.slug}/#{image}"
  end
  def absoluteify_links(html)
    html.
      gsub(/href=(["'])(\/.*?)(["'])/, 'href=\1http://toolmantim.com\2\3').
      gsub(/src=(["'])(\/.*?)(["'])/, 'src=\1http://toolmantim.com\2\3')
  end
end

before do
  @articles = Article.all.sort
end

get '/' do
  haml :home
end

%w( screen ie7 ie6 ).each do |stylesheet|
  get "/stylesheets/#{stylesheet}.css" do
    content_type 'text/css'
    headers "Expires" => (Time.now + 60*60*24*356*3).httpdate # Cache for 3 years
    sass :"stylesheets/#{stylesheet}"
  end
end

get '/articles/:id' do
  @article = Article[params[:id]] || raise(Sinatra::NotFound)
  haml :article
end

# Legacy URLs for articles
get '/article/:year/:month/:day/:id' do
  redirect "/articles/#{params[:id]}", 301
end

get '/articles' do
  @articles_by_year_then_month = @articles.inject({}) do |acc, article|
    acc[article.published.year] ||= {}
    acc[article.published.year][article.published.month] ||= []
    acc[article.published.year][article.published.month] << article
    acc
  end
  haml :archive
end

get '/articles.atom' do
  content_type 'application/atom+xml'
  haml :feed, :layout => false
end

get '/projects' do
  haml :projects
end

get '/sitemap.xml' do
  content_type 'application/xml'
  haml :sitemap, :layout => false
end

not_found do
  haml :not_found
end

error do
  @exception = request.env['sinatra.error']
  haml :error
end