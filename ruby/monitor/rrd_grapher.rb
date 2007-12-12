#!/usr/bin/env ruby

require 'yaml'
require 'net/http'

# A list of distinct colors.
COLORS=%w(007700 770000 000077 770077 777777 000000)

class RrdGrapher

  def initialize(files, width=640, height=400, prefix=nil)
    @files=files
    @width=width
    @height=height
    @prefix=prefix
  end

  # Make a variable by adding up all of values for the given rname accross the
  # given files.
  def mk_var(name, rname, type, transform="", files=@files)
    f_hash=Hash[*files.zip((1..files.length).to_a).flatten]
    defs=files.map do |file|
      "DEF:#{name}#{f_hash[file]}=#{file}:#{rname}:#{type.to_s.upcase}"
    end
    cdef="CDEF:#{name}=0"
    f_hash.values.each {|x| cdef += ",#{name}#{x},+"}
    defs + [cdef + transform]
  end

  def common_args(fn, title, range)
    args=['rrdtool', 'graph', '-z', prefix(fn), "-v", title, '-s', range]
    args += %W(-w #{@width} -h #{@height} -a PNG -t) + [title]
  end

  # XXX:  Make a better color algorithm
  def mk_color(offset)
    COLORS[offset]
  end

  protected

  def prefix(s)
    @prefix == nil ? s : @prefix + s
  end

end

class MemcacheGrapher < RrdGrapher
  def do_hit_misses(fn, range)
    args = common_args fn, 'Cache Requests/m', range
    args += mk_var 'hit', 'get_hits', :max, ',60,*'
    args += mk_var 'miss', 'get_misses', :max, ',-60,*'
    args += ["AREA:hit#00ee00:Hits", "AREA:miss#ee0000:Misses"]
    args += ['HRULE:0#000000']
    system(*args)
  end

  def do_hit_misses_per_server(fn, range)
    args = common_args fn, 'Cache Requests/m per Server', range
    f_hash=Hash[*@files.zip((1..@files.length).to_a).flatten]
    @files.each do |f|
      h=f_hash[f]
      c=mk_color h
      sn=File.basename(f, ".rrd")
      args += %W(DEF:getraw#{h}=#{f}:cmd_get:MAX
                DEF:setraw#{h}=#{f}:cmd_set:MAX
                CDEF:get#{h}=getraw#{h},60,*
                CDEF:set#{h}=setraw#{h},-60,*
                LINE:get#{h}##{c}:#{sn}\ Hits
                LINE:set#{h}##{c}:#{sn}\ Misses\\n)
    end
    system(*args)
  end

  def do_miss_rate(fn, range)
    args = common_args fn, 'Cache Miss Rate', range
    args += %w(-o -l .05 -u 50 --units=si)
    args += mk_var 'total', 'cmd_get', :max
    args += mk_var 'misses', 'get_misses', :max
    args += ["CDEF:rate=misses,total,/,100,*"]
    args += ["VDEF:vrate=rate,AVERAGE"]
    args += ["AREA:rate#000000:Miss Rate"]
    args += ['GPRINT:vrate:Average\: %0.2lf%%\n']
    args += ['HRULE:3#009900:Target']
    system(*args)
  end

  def do_bytes(fn, range)
    args = common_args fn, 'Bytes in Cache', range
    f_hash=Hash[*@files.zip((1..@files.length).to_a).flatten]
    type="AREA"
    @files.each do |f|
      h=f_hash[f]
      c=mk_color h
      sn=File.basename(f, ".rrd")
      args += %W(DEF:bytes#{h}=#{f}:bytes:MAX
                #{type}:bytes#{h}##{c}:#{sn}\ Bytes\\n)
      type="STACK"
    end
    system(*args)
  end

  def do_items(fn, range)
    args = common_args fn, 'Items in Cache', range
    f_hash=Hash[*@files.zip((1..@files.length).to_a).flatten]
    type="AREA"
    @files.each do |f|
      h=f_hash[f]
      c=mk_color h
      sn=File.basename(f, ".rrd")
      args += %W(DEF:curr_items#{h}=#{f}:curr_items:MAX
                #{type}:curr_items#{h}##{c}:#{sn}\ Items\\n)
      type="STACK"
    end
    system(*args)
  end

  def draw_all(suffix, range)
    do_hit_misses "mc_hitsmisses_#{suffix}.png", range
    do_hit_misses_per_server "mc_hitsmisses-s_#{suffix}.png", range
    do_miss_rate "mc_missrate_#{suffix}.png", range
    do_bytes "mc_bytes_#{suffix}.png", range
    do_items "mc_items_#{suffix}.png", range
  end

end

class LinuxGrapher < RrdGrapher

  def do_cpu(fn, range)
    args = common_args fn, 'CPU Utilization', range
    args += mk_var 'user_raw', 'cpu_user', :max
    args += mk_var 'nice_raw', 'cpu_nice', :max
    args += mk_var 'sys_raw', 'cpu_sys', :max
    args += mk_var 'idle_raw', 'cpu_idle', :max
    args << "CDEF:total=user_raw,nice_raw,sys_raw,idle_raw,+,+,+"
    args << "CDEF:user=user_raw,total,/,100,*"
    args << "CDEF:nice=nice_raw,total,/,100,*"
    args << "CDEF:sys=sys_raw,total,/,100,*"
    args << "CDEF:idle=idle_raw,total,/,100,*"
    args << "AREA:user#000077:User"
    args << "STACK:nice#0000ff:Nice"
    args << "STACK:sys#770000:System"
    args << "STACK:idle#00ee00:Idle"
    system(*args)
  end

  def do_paging(fn, range)
    args = common_args fn, 'Paging Activity', range
    args += mk_var 'pgpgin', 'pgpgin', :max
    args += mk_var 'pgpgout', 'pgpgout', :max
    args << "CDEF:out=pgpgout,-1,*"
    args << "AREA:pgpgin#000077:Paging In"
    args << "AREA:out#770000:Paging Out"
    system(*args)
  end

  def do_swapping(fn, range)
    args = common_args fn, 'Swapping Activity', range
    args += mk_var 'pswpin', 'pswpin', :max
    args += mk_var 'pswpout', 'pswpout', :max
    args << "CDEF:out=pswpout,-1,*"
    args << "AREA:pswpin#000077:Swapping In"
    args << "AREA:out#770000:Swapping Out"
    system(*args)
  end

  def do_ctx(fn, range)
    args = common_args fn, 'Context Switches', range
    args += mk_var 'ctxt', 'ctxt', :max
    args << "AREA:ctxt#770000:Context Switches"
    system(*args)
  end

  def do_load(fn, range)
    args = common_args fn, 'Load Average', range
    args += %W(-X 0)
    args += mk_var 'load5', 'load5', :max
    args << "CDEF:l5=load5,100,/"
    args << "AREA:l5#770000:Load Average"
    system(*args)
  end

  def draw_all(suffix, range)
    do_cpu "sys_cpu_#{suffix}.png", range
    do_paging "sys_paging_#{suffix}.png", range
    do_swapping "sys_swapping_#{suffix}.png", range
    do_ctx "sys_ctx_#{suffix}.png", range
    do_load "sys_load_#{suffix}.png", range
  end

end

class RailsLogGrapher < RrdGrapher

  def do_count(fn, range)
    args = common_args fn, 'Number of Requests/m', range
    args += mk_var 'count', 'count', :max
    args << "CDEF:count_m=count,60,*"
    args << "AREA:count_m#000000:Request\ Count"
    system(*args)
  end

  def do_times(fn, range)
    args = common_args fn, 'Request Timing (ms)', range
    args += mk_var 'req_raw', 'req', :max
    args += mk_var 'ren_raw', 'ren', :max
    args += mk_var 'db_raw', 'db', :max
    args += mk_var 'count', 'count', :max
    args << "CDEF:req=req_raw,count,/"
    args << "CDEF:ren=ren_raw,count,/"
    args << "CDEF:db=db_raw,count,/"
    args << "AREA:db#770000:DB"
    args << "STACK:ren#007700:Render"
    args << "LINE:req#000000:Request"
    system(*args)
  end

  def draw_all(suffix, range)
    do_count "rl_count_#{suffix}.png", range
    do_times "rl_time_#{suffix}.png", range
  end

end

if $0 == __FILE__

  conf=YAML.load_file($*[0])

  width=400
  height=200

  img_path=conf['img_path'] || "imgs/"

  graphers = []

  graphers << MemcacheGrapher.new(conf['memcached'].map {|x| x + ".rrd"},
    width, height, img_path)

  if conf['linux']
    hostfiles=conf['linux'].map{|h| URI.parse(h['url']).host + ".rrd"}
    lg=LinuxGrapher.new(hostfiles, width, height, img_path)

    graphers << lg

    conf['linux'].each do |h|
      hn = URI.parse(h['url']).host
      graphers << LinuxGrapher.new([hn + ".rrd"], width, height,
        "#{img_path}hosts/sys_" + hn + "_")
    end
  end

  if conf['db']
    graphers << RailsLogGrapher.new(Dir.glob("rldb_*.rrd"), width, height,
      img_path)

    Dir.glob("rldb_*.rrd").each do |f|
      # Take the prefix and suffix off
      hn=f[5..-5]
      graphers << RailsLogGrapher.new([f], width, height,
        "#{img_path}hosts/rl_#{hn}_")
    end
  end

  # Draw all the graphs.
  graphers.each {|g| g.draw_all 'day', 'now - 24 hours' }
  graphers.each {|g| g.draw_all 'week', 'now - 7 days' }
  graphers.each {|g| g.draw_all 'month', 'now - 1 month' }
end
