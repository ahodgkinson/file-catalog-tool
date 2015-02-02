##!/Users/alan/.rvm/rubies/ruby-1.9.3-p392/bin/ruby

require 'json'
require 'digest/md5'

@@VERBOSE=false

@@MEGABYTE=1024*1024

class File
  def each_chunk(size=@@MEGABYTE)
    yield read(size) until eof?
  end
end


class Md5Catalog

  # Data structures
  #
  # @hosts[host] --> rootpaths[rootpath] --> relpaths[relpath] --> filenames[filename] = md5sum
  #                                                a
  #                                                a/b
  #                                                a/b/c
  #                                                b
  #                                                b/c
  #                                                b/c/d
  #
  # @hash[ md5 ] --> [ (host,rootpath,relpath,filename), ... ]
  #

  def initialize
    @CATALOG_FILE_NAME='.catalog'
    @hosts = {}
    @hash = {}
  end

  def add(c2) # TODO
  end

  def add_json(s) # TODO
  end

  def contains?(c2) # TODO
  end

  def duplicates
  end

  def from_json(s)
  end

  def is_loaded?
    @hosts.size > 0 
  end

  def is_remote? # true if contains at least one root from a non-local server
  end

  def load(host,path)

    rec = {}

    # check host
    # check if path exists

    iname = File.join path, @CATALOG_FILE_NAME

    rec = {}
    try
      f = File.open iname, "r"
      json = f.gets
      rec = JSON.paser(json)
      f.close
      puts "load: loading: #{dname}, #{rec.size} files"
    catch
      puts "WARNING: unable to open file: #{iname}"
    end 


    Dir.foreach(dname) do |filename|
      path  = File.join dname, filename

      if File.directory?(path) && ( filename != '.' ) && ( filename != '..' )
        puts "refresh: recurse: #{path}" if @@VERBOSE
        load host, path
      end

      next if ! File.file? path   # Skip dot files, symlinks, devices, directories, etc.

    end


  end

  def refresh(host,dname) # Only works on local roots
    # TODO handle host, probably only check if local host
    # TODO check if path already loaded

    rec = {}
    Dir.foreach(dname) do |filename|
      path  = File.join dname, filename

      if File.directory?(path) && ( filename != '.' ) && ( filename != '..' )
        puts "refresh: recurse: #{path}" if @@VERBOSE
        refresh host, path
      end
  
      next if ! File.file? path   # Skip dot files, symlinks, devices, directories, etc.
      item  = File.new path
      size  = item.stat.size
      mtime = item.mtime.tv_sec
      sum   = md5 path
      key   = File.basename(filename)
      rec[key] = { :md5 => sum, :mtime => mtime, :size => size }
      puts "#{sum}\t#{item.mtime}\t#{size}\t#{key}" if @@VERBOSE
    end

    iname = File.join dname, @CATALOG_FILE_NAME

    puts "\n\nJSON: file: #{iname}, host: #{host}, root: #{dname}:  #{rec.to_json}" if @@VERBOSE
    puts "refresh: directory: #{dname}, #{rec.size} files"

    f = File.open iname, "w"
    f.write rec.to_json
    f.close

    rec
  end

  def to_json 
    # self.to_json
  end

  def dump # print the contents
    @md5.each do |key,val| 
      puts 
    end
  end

  private

    def md5(path)
      file = File.new path
      md5 = Digest::MD5.new
      file.each_chunk() {|buf| buf = md5.update(buf) }
      file.close
      md5.hexdigest
    end
end


# ------------- MAIN

if ARGV[0] === '-v'
  @@VERBOSE = true
  ARGV.shift
end

ARGV.each do |fname|
  c = Md5Catalog.new
  c.refresh('localhost',fname)
  #puts "MD5 (#{fname}) = #{md5(fname)}"
end

# -- end --


