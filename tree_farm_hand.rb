require_relative 'ext/nokogiri'
require_relative 'patterns/template'
require_relative 'ext/symja'
require_relative 'ext/macro'

module TreeFarmHand
  private
  def find_close_parens_index str
    levels = 0
    index = 0
    str.each_char do |char|
      case char
        when '(' then
          levels += 1
        when ')' then
          levels -= 1
        else
      end
      return index if levels == 0
      index += 1
    end
    raise Exception, "cannot find end of parameter expression!"
  end

  def resolve_str content_str, param_hash
    question = find_expr content_str
    return if question.nil?
    reply = Macro.new Symja.instance.evaluate(question, param_hash)
    replacement_str = reply.parameterized? ? reply : reply.demacro
    macro_string = Macro.new(question)
    content_str.gsub(macro_string, replacement_str)
  end

  def find_expr str
    expr_start_index = str.index('@(')
    return nil if expr_start_index.nil?
    expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
    str[expr_start_index+2, expr_end_index-1]
  end

  def wrap xml_node=nil
    xml_doc = Nokogiri::XML(%(
      <template id="temp_id">
        <name>temp_name</name>
        <version>1.0</version>
        <owners>
          <owner id="chef_id">
            <name>module: Chef</name>
          </owner>
        </owners>
        <description>created by Chef module to wrap around non-DesignOS XML design</description>
        <history>
          <insert id="change_0_id" owner="tree_farm">
              <description>created file</description>
              <date>#{Time.now.to_s}</date>
          </insert>
      </template>
                              ))
    xml_doc.root << xml_node if xml_node = xml_node.xml
    xml_doc
  end

  def validate xml
    xml.root.name == 'template'
  end

  def update before, after
    # record in history
  end

  def peek current_node
    if current_node[:if].nil? || current_node.simple_class.include?('parameter')
      true
    else
      r = resolve_parameterized!(current_node, :if)
      r.if?
    end
  end

  def resolve_ref ref
    ref = ref.respond_to?(:id) ? ref[:ref] : ref
    return nil if ref.nil?
    ref.match(Regexp.identifier) ? base_template.design.find_kansei(ref) : Patterns::Template.new(File.open(ref)).design
  end

  def get_inst_hierarchy node
    h = []
    node.parentage.each do |ancestor|
      h << ancestor if ancestor.respond_to?(:params)
    end
    h
  end

  def get_param_hash comp
    h = {}
    inst_hierarchy = get_inst_hierarchy comp
    inst_hierarchy.each do |inst|
      if inst.params && inst.params.any?
        inst.params.each do |param|
          next unless param[:name]
          h[param[:name].to_sym] = param[:value]
        end
      end
    end
    h
  end

  def add_kansei design
    @kansei_array << Template.new(wrap design.xml)
  end

  def dead_node? node
    cur = node
    until cur.simple_class == 'design'
      return true unless cur.if?
      cur = cur.parent
    end
    false
  end

  def reserved_node? node
    node.descended_from?('parameters') || node.simple_class == 'parameters' ||
        node.simple_class == 'design' || dead_node?(node) || node.respond_to?(:params)
  end

  def find_non_inst_ancestor node
    cur = node.parent
    return if cur.nil?
    if cur.respond_to?(:params) &&
        cur.simple_class != 'design'
      find_non_inst_ancestor cur
    else
      cur
    end
  end

  def previous
    kansei_array[-2]
  end
end
