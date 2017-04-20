#!/usr/bin/env ruby

require 'open-uri'

module Slackware
  class Repo
    DEFAULT_MIRROR = "http://mirrors.kernel.org/slackware"
    DEFAULT_RELEASE = "slackware64-current"
    RE_FILELIST = /.*(\d{4}-\d{2}-\d{2} \d{2}:\d{2})\s\.\/(\w*)\/(.*\.t.z)\n?/

    def initialize(release = nil, mirror = nil)
      @mirror = mirror || DEFAULT_MIRROR
      @release = release || DEFAULT_RELEASE
      @tag_done = false
      @pkgs = []
    end

    def pkgs
      return @pkgs unless @pkgs.empty?
      fl = open("#{@mirror}/#{@release}/#{_base_rel}/FILE_LIST")
      fl.each_line do |line|
        line.strip!
        puts line
        if line =~ RE_FILELIST 
          @pkgs << Slackware::Package.parse($2 + "/" + $3)
        end
      end
      fl.close
      return @pkgs
    end

    def sections
      return pkgs.map {|p| p.section }.uniq
    end

    def tagfiles
      return pkgs.map {|p| p.tag }.uniq if @tag_done
      sections.each do |section|
        fl = open("#{@mirror}/#{@release}/#{_base_rel}/#{section}/tagfile")
        fl.each_line do |line|
          p_name, tag = line.strip.split(":",2)
          pkg = pkgs.detect {|p| p.name == p_name }
          if pkg
            pkg.tag = tag 
          else
            $stderr.puts("#{p_name} not in pkgs")
          end
        end
        fl.close
      end
      @tag_done = true
      return @pkgs.map {|p| p.tag }.uniq
    end

    private
    def _base_rel
      @release.split("-").first
    end
  end

  class Package
    attr_accessor :section, :name, :version, :arch, :build, :ext, :tag
    def self.parse(str)
      pkg = self.new
      paths = str.split('/')
      pkg_str = paths.pop
      if paths.length > 0
        pkg.section = paths.join('/')
      end
      pkg.ext = File.extname(pkg_str)
      chunks = File.basename(pkg_str, pkg.ext).split('-')
      pkg.build = chunks.pop
      pkg.arch = chunks.pop
      pkg.version = chunks.pop
      pkg.name = chunks.join('-')
      return pkg
    end
    def to_s
      "#{@section.nil? ? '' : @section + '/'}#{@name}-#{@version}-#{@arch}-#{@build}#{@ext}"
    end
  end
end

def main(args)
  # build out the tag files
  r = Slackware::Repo.new(args.first)
  r.tagfiles
  r.pkgs.each do |pkg|
    puts "#{pkg}:#{pkg.tag}" unless pkg.tag.nil?
  end
end

main(ARGV)
