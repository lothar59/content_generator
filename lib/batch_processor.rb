require 'nokogiri'
require 'fileutils'
require_relative 'underscore.rb'

class BatchProcessor

  def self.generate_files(params)
    taxonomy_file = File.open(params[:taxonomy])
    @taxonomy_doc = 
      Nokogiri::XML(taxonomy_file) do |config|
        config.strict.nonet
        config.strict.noblanks
      end

    content_file = File.open(params[:content])
    @content_doc = 
      Nokogiri::XML(content_file) do |config|
        config.strict.nonet
        config.strict.noblanks
      end

    output_dir = params[:output_dir]
    unless File.exists?(output_dir)
      Dir.mkdir(output_dir)
    else
      Dir.open(output_dir)
    end

    FileUtils.cp_r "output-template/static", output_dir

    Dir.chdir(output_dir)

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

      destination_file_doc.xpath("//ul[@id='nav'][1]").each do |el|
        el.inner_html = lis
      end

      tabs_lis = ""
      tabs_contents = ""
      %w{history introductory practical_information transport weather work_live_study}.each do |tab|
        @content_doc.xpath("//destination[@atlas_id=\"#{node_element.first.last}\"]").xpath("#{tab}").each do |tag| 
          tabs_lis += "<li><a href=\"##{tab}_tab\">#{tab.gsub('_', ' ').upcase}</a></li>"
          tabs_contents += "<div id=\"#{tab}_tab\">#{tag.text}</div>"
        end
        destination_file_doc.xpath("//div[@id='content']/ul[1]").each do |el|
          el.inner_html = tabs_lis
        end
        destination_file_doc.xpath("//div[@id='content']/div[1]").each do |el|
          el.inner_html = tabs_contents
        end
      end

      File.open("#{content.to_s.underscore}.html", "w+") do |f|
        f.write(destination_file_doc)
      end

      create_file(@children_nodes.first, node_element) if @children_nodes.any?
    end
    taxonomy_file.close
    content_file.close
  end

  def self.create_file(node_element, parent) 
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

  def self.get_next_node(node_element, parent)
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

end
