#!/usr/bin/env ruby
require 'optparse'
require 'nokogiri'
require 'fileutils'

class String
  def underscore
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr(" ", "_").
    downcase
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: batch_processor.rb [options]"

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

taxonomy_file = File.open(ARGV[0])
@taxonomy_doc = 
  Nokogiri::XML(taxonomy_file) do |config|
    config.strict.nonet
    config.strict.noblanks
  end

content_file = File.open(ARGV[1])
@content_doc = 
  Nokogiri::XML(content_file) do |config|
    config.strict.nonet
    config.strict.noblanks
  end


unless File.exists?(ARGV[2])
  Dir.mkdir(ARGV[2])
else
  Dir.open(ARGV[2])
end

FileUtils.cp_r "output-template/static", ARGV[2]

Dir.chdir(ARGV[2])

def get_next_node(node_element, parent)
  if node = node_element.next
    next_node = node
    new_parent = parent
  else
    next_node = parent.next
    new_parent = parent.parent
    get_next_node(next_node, new_parent) if next_node 
  end 
  [next_node, new_parent]
end

def create_file(node_element, parent) 
  content = node_element.children.first.text if node_element.children && node_element.children.first # eventually case content is blank?  
  
  template_file = File.open("../output-template/template.html")  
  destination_file_doc = 
    Nokogiri::HTML(template_file)  do |config|
      config.strict.nonet
      config.strict.noblanks
    end

  destination_file_doc.xpath("//*[contains(text(),'{{{destination_name}}}')]").each do |el|
    el.content = el.content.gsub!(/{{{destination_name}}}/, content.to_s)
  end

  File.open("#{content.to_s.underscore}.html", "w+") do |f|
    f.write(destination_file_doc)
  end

  template_file.close
  
  children_nodes = node_element.xpath("node")
  if children_nodes.any? 
    next_node = children_nodes.first
    new_parent = node_element
    create_file(next_node, new_parent)
  else
    next_node, new_parent = get_next_node(node_element, parent)
    create_file(next_node, new_parent) if next_node
  end
end

@taxonomy_doc.xpath("/taxonomies/taxonomy/descendant::node").each do |node_element|
  content = node_element.children.first.text if node_element.children && node_element.children.first # eventually case content is blank?

  template_file = File.open("../output-template/template.html")  
  destination_file_doc = 
    Nokogiri::HTML(template_file) do |config|
      config.strict.nonet
      config.strict.noblanks
    end

  destination_file_doc.xpath("//*[contains(text(),'{{{destination_name}}}')]").each do |el|
    el.content = el.content.gsub!(/{{{destination_name}}}/, content.to_s)
  end

  template_file.close

  @children_nodes = node_element.xpath("node")

  lis = ""

  text = node_element.parent.xpath("node_name").text
  unless text == ""
    file_name = text.underscore
    path = File.absolute_path(file_name)
    lis+= "<li><a href=\"#{file_name}.html\">#{text}</a></li>"
  end

  @children_nodes.each do |element|
    text = element.xpath("node_name").text
    file_name = text.underscore
    path = File.absolute_path(file_name)
    lis += "<li><a href=\"#{file_name}.html\">#{text}</a></li>"
  end

  destination_file_doc.xpath("//ul[@id='nav']").each do |el|
    el.inner_html = lis
  end

  # destination_file_doc.xpath("//div[@id='content']").each do |el|
  #   text = ""
  #   @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").children.each do |el|
  #     text+= "<p>#{el.text}</p>"
  #   end
  #   el.inner_html = text
  # end

  destination_file_doc.xpath("//div[@id='history-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("history").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  destination_file_doc.xpath("//div[@id='introductory-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("introductory").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  destination_file_doc.xpath("//div[@id='practical-information-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("practical_information
").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  destination_file_doc.xpath("//div[@id='transport-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("transport").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  destination_file_doc.xpath("//div[@id='weather-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("weather
").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  destination_file_doc.xpath("//div[@id='work-live-study-tab']/div").each do |el|
    text = ""
    @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("work_live_study
").children.each do |el|
      text+= "<p>#{el.text}</p>"
    end
    el.inner_html = text
  end

  File.open("#{content.to_s.underscore}.html", "w+") do |f|
    f.write(destination_file_doc)
  end

  create_file(@children_nodes.first, node_element) if @children_nodes.any?
end
taxonomy_file.close
content_file.close
