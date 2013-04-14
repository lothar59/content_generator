require 'nokogiri'
require 'fileutils'
require_relative 'underscore'

class BatchProcessor

  attr_accessor :taxonomy_document, :content_document, :output_dir, 
                :destination_file_document, :node_text, :children_nodes

  def initialize(params)
    @taxonomy_document          = open_xml_document(params[:taxonomy])
    @content_document           = open_xml_document(params[:content])
    @output_dir                 = params[:output_dir]
    @destination_file_document  = nil
    @node_text                  = nil
    @children_nodes             = nil
  end

  def generate_destination_files
    # Prepare for parsing
    create_output_dir
    copy_static_files
    move_in_directory

    get_root_nodes.each do |node_element|
      # Replace the {{{destination_name}}} tag with the actual destination name
      set_destination_name(node_element)

      # Create navigation links
      create_navigation_links(node_element)

      # Set the content data from destination.xml
      set_content_data(node_element)

      # Create the html destination file
      create_destination_file

      # Create next file if it exists
      create_file(@children_nodes.first, node_element) if @children_nodes.any?
    end
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

    def open_html_template
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

    def replace_destination_name(node_text)
      @destination_file_document.xpath("//*[contains(text(),'{{{destination_name}}}')]").each do |el|
        el.content = el.content.gsub!(/{{{destination_name}}}/, node_text.to_s)
      end 
    end

    def create_destination_file
      File.open("#{@node_text.to_s.underscore}.html", "w+") do |f|
        f.write(@destination_file_document)
      end
    end

    def set_destination_name(node_element)
      @node_text = get_node_text(node_element)  
      @destination_file_document = open_html_template
      replace_destination_name(node_text)
    end

    def create_navigation_links(node_element)
      parent_li = parent_link(node_element)
      set_children_nodes(node_element)
      children_lis = children_links(node_element)
      set_navigation_links(parent_li, children_lis)
    end

    def create_file(node_element, parent) 
      set_destination_name(node_element)
      
      create_destination_file

      set_children_nodes(node_element)
      if @children_nodes.any? 
        next_node = @children_nodes.first
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

    def parent_link(node_element)
      text = node_element.parent.xpath("node_name").text
      unless text == ""
        file_name = text.underscore
        parent_li = "<li class='parent_li'><a href=\"#{file_name}.html\">#{text}</a></li>"
      end
      parent_li.to_s 
    end

    def set_children_nodes(node_element)
      @children_nodes = node_element.xpath("node")
    end

    def children_links(node_element)
      children_lis = ""
      @children_nodes.each do |element|
        text = element.xpath("node_name").text
        file_name = text.underscore
        children_lis += "<li><a href=\"#{file_name}.html\">#{text}</a></li>"
      end
      children_lis
    end

    def set_navigation_links(parent_li, children_lis)
      @destination_file_document.css("#nav").first.inner_html = parent_li + children_lis
    end

    def get_root_nodes
      @taxonomy_document.xpath("/taxonomies/taxonomy/descendant::node")
    end

    def set_content_data(node_element)
      tabs_lis = ""
      %w{history introductory practical_information transport weather work_live_study}.each do |tab|
        tabs_contents = ""
        @content_document.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]/#{tab}").each do |tag| 
          tabs_lis += "<li><a href=\"##{tab}_tab\">#{tab.gsub('_', ' ').upcase}</a></li>"
          tag.children.each { |el| tabs_contents += "<p>#{el.text}</p>" }
        end

        @destination_file_document.css("#content-tabs").first.inner_html = tabs_lis
        @destination_file_document.css("##{tab}_tab").first.inner_html = tabs_contents
      end
    end
end
