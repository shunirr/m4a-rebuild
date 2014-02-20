#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'taglib'

files = []
if ARGV.size > 0
  files = ARGV
else
  puts "usage: #{$PROGRAM_NAME} m4afiles ..."
  exit 0
end

files.each do |file|
  unless File.exists? file
    puts "#{file} is not found."
    next
  end

  tags = []
  TagLib::MP4::File.open(file) do |mp4|
    mp4.tag.item_list_map.to_a.each do |t|
      k, v = t

      next if k.include? 'com.apple.iTunes'
      next if k.include? 'purd'

      if k == 'covr'
        type = :cover_art_list
        value = v.to_cover_art_list.first
      else
        type = :string_list
        value = v.to_string_list 
        unless value.size > 0
          type = :int
          value = v.to_int
        end
      end
      tags << {:name => k, :type => type, :value => value}
    end
  end

  system("mp4box -add \"#{file}\" \"#{file}.new\" -new")

  TagLib::MP4::File.open("#{file}.new") do |mp4|
    map = mp4.tag.item_list_map
    tags.each do |tag|
      case tag[:type]
      when :string_list
        map.insert tag[:name], TagLib::MP4::Item.from_string_list(tag[:value])
      when :int
        map.insert tag[:name], TagLib::MP4::Item.from_int(tag[:value])
      when :cover_art_list
        map.insert tag[:name], TagLib::MP4::Item.from_cover_art_list([tag[:value]])
      end
    end
    mp4.save
  end

  system("mv #{file}.new #{file}")
end

