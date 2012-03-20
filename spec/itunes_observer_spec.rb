$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'spec_helper'
require 'osx/cocoa'
require 'eventmachine'

include OSX
OSX.require_framework 'ScriptingBridge'

describe ITunesObserver do
  before do
    @itunes = SBApplication.applicationWithBundleIdentifier_("com.apple.iTunes")
    raise 'iTunes must be running' unless @itunes.isRunning
    @itunes.stop
  end

  after do
    @itunes.stop
  end

  describe ".new" do
    it "should observe playing" do
      result = nil

      observer = ITunesObserver.new do |result|
        result = result
      end

      EM.run do
        @itunes.playpause

        EM::Timer.new(1) do
          EM.stop
        end
      end

      observer.run(1)

      result.should_not be_nil
      result['Name'].should_not be_nil
      result['Player State'].should eql('Playing')
      result['Total Time'].should be_kind_of(Fixnum)
    end
  end

  describe "#on_stop" do
    it "should observe stopping" do
      observer = ITunesObserver.new
      result = nil

      observer.on_stop do |result|
        result = result
      end

      EM.run do
        @itunes.playpause

        EM::Timer.new(1) do
          @itunes.stop
          EM.stop
        end
      end

      observer.run(0)

      result.should_not be_nil
      result['Name'].should_not be_nil
      result['Player State'].should eql('Stopped')
      result['Total Time'].should be_kind_of(Fixnum)
    end
  end

  describe "#on_play" do
    it "should observe playing" do
      observer = ITunesObserver.new
      result = nil

      observer.on_play do |result|
        result = result
      end

      EM.run do
        @itunes.playpause

        EM::Timer.new(1) do
          EM.stop
        end
      end

      observer.run(0)

      result.should_not be_nil
      result['Name'].should_not be_nil
      result['Player State'].should eql('Playing')
      result['Total Time'].should be_kind_of(Fixnum)
    end
  end

  describe "#on_pause" do
    it "should observe pausing" do
      observer = ITunesObserver.new
      result = nil

      observer.on_pause do |result|
        result = result
      end

      EM.run do
        @itunes.playpause

        EM::Timer.new(1) do
          @itunes.pause
          EM.stop
        end
      end

      observer.run(0)

      result.should_not be_nil
      result['Name'].should_not be_nil
      result['Player State'].should eql('Paused')
      result['Total Time'].should be_kind_of(Fixnum)
    end
  end
end
