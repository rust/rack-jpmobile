$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.push(File.join(File.expand_path(File.dirname(__FILE__)), "lib"))

require 'rack'
require 'rack/jpmobile'
require 'rubygems'
require 'jpmobile'
require 'scanf'
require 'pp'

module MobileRack
  class Emoticon
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request::Jpmobile.new(env)
      if request.mobile?
        status, headers, body = @app.call(env)

        table = nil
        to_sjis = false
        case request.mobile
        when Jpmobile::Mobile::Docomo
          table = Jpmobile::Emoticon::CONVERSION_TABLE_TO_DOCOMO
          to_sjis = true
        when Jpmobile::Mobile::Au
          table = Jpmobile::Emoticon::CONVERSION_TABLE_TO_AU
          to_sjis = true
        when Jpmobile::Mobile::Jphone
          table = Jpmobile::Emoticon::CONVERSION_TABLE_TO_SOFTBANK
          to_sjis = true
        when Jpmobile::Mobile::Softbank
          table = Jpmobile::Emoticon::CONVERSION_TABLE_TO_SOFTBANK
        end

        body = Jpmobile::Emoticon::unicodecr_to_external(body.first, table, to_sjis)

        [status, headers, [body]]
      else
        @app.call(env)
      end
    end
  end
end

module TestRack
  class HelloWorld
    def call(env)
      emoji = sprintf("&#x%x;", 0xe6f0)
      message =<<HTML
<html>
<body>
<form method="POST">
#{emoji}<br />
<input type="submit" name="submit" value="submit" />
</form>
</body>
</html>
HTML
# <input type="text" name="emoji" value="#{emoji}" />

      [200, {"Content-type" => "text/html; charset=Shift_JIS;"}, [message]]
    end
  end
end

run Rack::ContentLength.new(MobileRack::Emoticon.new(TestRack::HelloWorld.new))
