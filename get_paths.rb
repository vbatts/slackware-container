require 'open-uri'

@base_mirror = "http://mirrors1.kernel.org/slackware"

fl = open(@base_mirror + "/slackware64-current/slackware64/FILE_LIST")
re = Regexp.new(".*/a/\(.*\.t.z\)\n")
pkgs = { :a => [] }
fl.each_line do |line|
  if line =~ re 
    pkgs[:a] << $1
  end
end

puts pkgs
