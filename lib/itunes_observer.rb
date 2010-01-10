require 'osx/cocoa'

class ITunesObserver
  VERSION = '0.0.2'

  def initialize(&callback)
    observer = Observer.alloc.init
    observer.observe(&callback)
  end

  def run(stop_after = nil)
    if stop_after
      OSX::NSRunLoop.currentRunLoop.runUntilDate(Time.now + stop_after)
    else
      OSX::NSRunLoop.currentRunLoop.run
    end
  end

  # based on http://blog.8-p.info/articles/2006/12/24/rubycocoa-skype-itunes
  class Observer < OSX::NSObject
    def onPlayerInfo(info)
      if info.userInfo['Player State'] == 'Playing'
        result = Result.new(info.userInfo)
        @callback.call(result)
      end
    end

    def observe(&callback)
      @callback = callback
      center = OSX::NSDistributedNotificationCenter.defaultCenter
      center.addObserver_selector_name_object_(self,
        'onPlayerInfo:',
        'com.apple.iTunes.playerInfo',
        'com.apple.iTunes.player')
    end
  end

  class Result
    def initialize(attributes)
      @attributes = attributes
    end

    def [](key)
      case value = @attributes[key]
      when OSX::NSCFString
        value.to_s
      else
        value
      end
    end
  end
end
