require 'nokogiri'
require 'fileutils'
require_relative 'underscore.rb'

class BatchProcessor

  attr_accessor :taxonomy_document, :content_document, :output_dir

  def initialize(params)
    @taxonomy_document = open_xml_document(params[:taxonomy])
    @content_document = open_xml_document(params[:content])
    @output_dir = params[:output_dir]
  end

  def generate_destination_files
    create_output_dir
    copy_static_files
    move_in_directory

    @taxonomy_document.xpath("/taxonomies/taxonomy/descendant::node").each do |node_element|
      node_text = get_node_text(node_element)

      destination_file_doc = open_template

      replace_destination_name(destination_file_doc, node_text)

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

      destination_file_doc.css("#nav").first.inner_html = lis

      tabs_lis = ""
      %w{history introductory practical_information transport weather work_live_study}.each do |tab|
        tabs_contents = ""
        @content_document.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]/#{tab}").each do |tag| 
          tabs_lis += "<li><a href=\"##{tab}_tab\">#{tab.gsub('_', ' ').upcase}</a></li>"
          tag.children.each { |el| tabs_contents += "<p>#{el.text}</p>" }
        end

        destination_file_doc.css("#content-tabs").first.inner_html = tabs_lis
        destination_file_doc.css("##{tab}_tab").first.inner_html = tabs_contents
      end

      create_destination_file(destination_file_doc, node_text)

      create_file(@children_nodes.first, node_element) if @children_nodes.any?
    end
  end

  def create_file(node_element, parent) 
    node_text = get_node_text(node_element)  
    
    destination_file_doc = open_template

    replace_destination_name(destination_file_doc, node_text)
    
    create_destination_file(destination_file_doc, node_text)

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

  private

    def open_xml_document(file)
      Nokogiri::XML(File.open(file)) do |config|
        config.strict.nonet
        config.strict.noblanks
      end
    end

    def open_html_document(file)
      Nokogiri::HTML(File.open(file)) do |config|
        config.strict.nonet
        config.strict.noblanks
      end
    end

    def open_template
      open_html_document(File.open("../output-template/template.html"))
    end

    def create_output_dir
      unless File.exists?(@output_dir)
        Dir.mkdir(@output_dir)
      else
        Dir.open(@output_dir)
      end
    end

    def copy_static_files
      FileUtils.cp_r "output-template/static", @output_dir
    end

    def move_in_directory
      Dir.chdir(@output_dir)
    end

    def get_node_text(node_element)
      node_element.children.first.text if node_element.children && node_element.children.first # eventually case node_text is blank?
    end

    def replace_destination_name(destination_file_doc, node_text)
      destination_file_doc.xpath("//*[contains(text(),'{{{destination_name}}}')]").each do |el|
        el.content = el.content.gsub!(/{{{destination_name}}}/, node_text.to_s)
      end 
    end

    def create_destination_file(destination_file_doc, node_text)
      File.open("#{node_text.to_s.underscore}.html", "w+") do |f|
        f.write(destination_file_doc)
      end
    end
end
