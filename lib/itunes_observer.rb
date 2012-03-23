require 'osx/cocoa'

class ITunesObserver
  VERSION = '0.1.1'

  STATES = {
    :playing => 'Playing',
    :paused  => 'Paused',
    :stopped => 'Stopped'
  }

  def initialize(&callback)
    @observer = Observer.alloc.init

    add_callback(STATES[:playing], &callback)
  end

  def on_play(&callback)
    add_callback(STATES[:playing], &callback)
  end

  def on_pause(&callback)
    add_callback(STATES[:paused], &callback)
  end

  def on_stop(&callback)
    add_callback(STATES[:stopped], &callback)
  end

  def run(stop_after = nil)
    if stop_after
      OSX::NSRunLoop.currentRunLoop.runUntilDate(Time.now + stop_after)
    else
      OSX::NSRunLoop.currentRunLoop.run
    end
  end

  def finish
    @observer.finish
  end

  private

  def add_callback(state, &callback)
    if callback
      @observer.add_callback(state, &callback)
    end
  end

  # based on http://blog.8-p.info/articles/2006/12/24/rubycocoa-skype-itunes
  class Observer < OSX::NSObject
    def initialize
      @callbacks = {}
      @name = 'com.apple.iTunes.playerInfo'
      @object = 'com.apple.iTunes.player'

      notification_centor.addObserver_selector_name_object_(self,
        'onPlayerInfo:',
        @name,
        @object)
    end

    def onPlayerInfo(info)
      result = Result.new(info.userInfo)

      STATES.each do |k, state|
        if info.userInfo['Player State'] == state
          (@callbacks[state] || []).each do |callback|
            callback.call(result)
          end
        end
      end
    end

    def add_callback(state, &callback)
      @callbacks[state] ||= []
      @callbacks[state] << callback
    end

    def finish
      notification_centor.removeObserver_name_object_(self,
        @name,
        @object)
    end

    def notification_centor
      OSX::NSDistributedNotificationCenter.defaultCenter
    end
  end

  class Result
    def initialize(attributes)
      @attributes = attributes
    end

    def [](key)
      case value = @attributes[key]
      when OSX::NSMutableString
        value.to_s
      when OSX::NSCFString
        value.to_s
      when OSX::NSNumber
        value.to_i
      else
        value
      end
    end
  end
end

class OSX::NSCFString
end
