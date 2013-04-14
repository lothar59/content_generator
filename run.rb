#!/usr/bin/env ruby
require 'optparse'
require_relative 'lib/batch_processor.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: run.rb [options]"

  [
    ["-t", "--taxonomy", "Taxonomy xml file path", :taxonomy], 
    ["-c", "--content", "Content xml file path", :content], 
    ["-o", "--output-dir", "Output directory", :output_dir]
  ].each_with_index do |opt, index|
    opts.on(opt[0], opt[1], opt[2]) do |v|
      options[opt[3]] = v
    end
  end
end.parse!

unless options[:taxonomy] && options[:content] && options[:output_dir] && ARGV[0] && ARGV[1] && ARGV[2]
  abort("Please provide the right options to the processor\n batch_processor.rb --help for more help")
end

BatchProcessor.new(taxonomy: ARGV[0], content: ARGV[1], output_dir: ARGV[2]).generate_destination_files