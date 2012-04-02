#(c) Copyright 2012 Nicholas A Thrower. All Rights Reserved.
# Derivative of https://github.com/helios/bioruby-samtools/blob/master/ext/mkrf_conf.rb
# create Rakefile for shared library compilation

path = File.expand_path(File.dirname(__FILE__))

path_external = File.join(path, "../../lib/bio/tabix/")

version = File.open(File.join(path_external,"Version"),'r')
Version = version.read
version.close

url = "http://samtools.svn.sourceforge.net/viewvc/samtools/trunk/tabix/?view=tar"
TabixFile = "tabix-trunk.tar"

File.open(File.join(path,"Rakefile"),"w") do |rakefile|
rakefile.write <<-RAKE
require 'rbconfig'
require 'open-uri'
require 'fileutils'
include FileUtils::Verbose
require 'rake/clean'

URL = "#{url}"

task :download do
  open(URL) do |uri|
    File.open("#{TabixFile}",'wb') do |fout|
      fout.write(uri.read)
    end #fout 
  end #uri
end
    
task :compile do
  sh "tar xvf #{TabixFile}"
  cd("tabix") do
    #sh "patch < ../Makefile-bioruby.patch"
    sh "make"
    cp("libtabix.a","#{path_external}")
    case Config::CONFIG['host_os']
      when /linux/
        sh "make libtabix.so.1"
        cp("libtabix.so.1","#{path_external}")
      when /darwin/
        sh "make libtabix.1.dylib"
        cp("libtabix.1.dylib","#{path_external}")
      else raise NotImplementedError, "Tabix not supported on your platform"
    end #case
    cp("tabix", "#{path}/../../bin/")
    chmod 0755, "#{path}/../../bin/tabix"
    cp("bgzip", "#{path}/../../bin/")
    chmod 0755, "#{path}/../../bin/bgzip"
  end #cd
end
  
task :clean do
  # cd("tabix-#{Version}") do
  #   sh "make clean"
  # end
  # rm("#{TabixFile}")
  # rm_rf("tabix-#{Version}")
  cd("tabix") do
    sh "make clean"
  end
  rm("#{TabixFile}")
  rm_rf("tabix")
end

task :default => [:download, :compile, :clean]
  
RAKE
  
end
