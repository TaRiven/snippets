#!/usr/bin/env ruby -w

require 'thread'
require 'yaml'

require 'rrd_schema'
require 'memcache_rrd'

QUEUE=Queue.new

module RRDSchema
  alias send_rrd_cmd_stupid send_rrd_cmd
  def send_rrd_cmd(s)
    QUEUE << s
  end
end

class MonitorDaemon

  def initialize
    @threads = []
  end

  def add_task(freq, name)
    # I'm going to punt and just make threads that loop and stuff.
    @threads << Thread.new do
      # Allow some kind of delay up to the frequency before the first poll
      sleep([15, rand * freq].min)
      while true
        begin
          yield
        rescue => e
          $stderr.puts "Error processing #{name}:  #{e}"
        end
        sleep freq
      end
    end
  end

  def for_responses
    while true
      yield QUEUE.pop
    end
  end

  def add_proc_task(freq, url, user, pass)
    lh=LinuxHostInfo.new(url, user, pass)
    h=LinuxHostRRD.new(lh)
    add_task(freq, "proc #{url}") { h.rrd_inserts }
  end

  def add_memcached_task(freq, servers)
    m=MemCacheRRD.new(servers)
    add_task(freq, "memcached") { m.rrd_inserts }
  end

  def add_rails_poll(freq, c)
    add_task(freq, "rails poll") do
      h=c['host']
      u=c['user']
      p=c['pass'] || ''
      d=c['database']
      RailsLogRRD.new(RailsLog.new(h, u, p, d)).rrd_inserts
    end
  end

end

if $0 == __FILE__
  raise "Need config file" if $*.empty?
  conf=YAML.load_file($*[0])

  md=MonitorDaemon.new

  if conf['linux']
    require 'sysinfo_rrd'
    conf['linux'].each do |h|
      md.add_proc_task 60, h['url'], h['user'], h['pass']
    end
  end

  md.add_memcached_task 60, conf['memcached']

  if conf['db']
    require 'rails_log'
    md.add_rails_poll 300, conf['db']
  end

  md.for_responses do |response|
    puts response
    $stdout.flush
  end
end
