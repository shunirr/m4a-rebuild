#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'taglib'
require 'open3'
require 'fileutils'

mp4box = nil
%W{mp4box MP4Box}.each{|command|
  if Open3.capture2('which', command)[1].exitstatus == 0
    mp4box = command
    break
  end
}
unless mp4box
  puts "Please Install MP4Box"
  exit 
end

filenames = ARGV
if filenames.empty?
  puts "usage: #{$PROGRAM_NAME} m4afiles ..."
  exit 1
end

filenames.each do |filename|
  unless File.exists? filename
    puts "#{filename} is not found."
    next
  end

  tmp_filename = "#{filename}.tmp"
  system(mp4box, '-add', filename, tmp_filename, '-new')

  TagLib::MP4::File.open filename do |from|
    TagLib::MP4::File.open tmp_filename do |to|
      from_tags = from.tag.item_list_map
      to_tags = to.tag.item_list_map

      from_tags.to_a.each do |k, v|
        next if k.include? 'com.apple.iTunes'
        next if k.include? 'purd'
        next if k.include? 'apID'

        to_tags.insert k, v
      end

      to.save
    end
  end

  FileUtils.rm filename
  FileUtils.mv tmp_filename, filename
end

