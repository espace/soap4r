# XSD4R - Generating module definition code
# Copyright (C) 2004  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'xsd/codegen/gensupport'
require 'xsd/codegen/methoddef'


module XSD
module CodeGen


class ModuleDef
  include GenSupport

  attr_accessor :comment

  def initialize(name)
    @name = name
    @comment = nil
    @const = []
    @requirepath = []
    @methoddef = []
  end

  def defrequire(path)
    @requirepath << path
  end

  def defconst(const, value)
    raise ArgumentError, const unless safeconstname?(const)
    @const << [const, value]
  end

  def defmethod(name, *params)
    @methoddef << MethodDef.new(name, *params) { yield if block_given? }
  end

  def dump
    buf = ""
    unless @requirepath.empty?
      buf << dump_requirepath 
    end
    buf << dump_emptyline unless buf.empty?
    buf << dump_package_def
    buf << dump_comment if @comment
    buf << dump_module_def
    spacer = false
    if @const
      buf << dump_emptyline if spacer
      spacer = true
      buf << dump_const
    end
    unless @methoddef.empty?
      buf << dump_emptyline if spacer
      spacer = true
      buf << dump_methods
    end
    buf << dump_module_def_end
    buf << dump_package_def_end
    buf
  end

private

  def dump_emptyline
    "\n"
  end

  def dump_requirepath
    format(
      @requirepath.sort.collect { |path|
        %Q(require "#{path}")
      }.join("\n")
    )
  end

  def dump_comment
    format(@comment).gsub(/^/, "# ")
  end

  def dump_package_def
    name = @name.to_s.split(/::/)
    if name.size > 1
      format(name[0..-2].collect { |ele| "module #{ele}" }.join("; ")) + "\n\n"
    else
      ""
    end
  end

  def dump_package_def_end
    name = @name.to_s.split(/::/)
    if name.size > 1
      "\n\n" + format(name[0..-2].collect { |ele| "end" }.join("; "))
    else
      ""
    end
  end

  def dump_const
    dump_static(
      @const.sort.collect { |var, value|
        %Q(#{var} = #{dump_value(value)})
      }.join("\n")
    )
  end

  def dump_static(str)
    format(str, 2)
  end

  def dump_module_def
    name = @name.to_s.split(/::/)
    format("module #{name.last}")
  end

  def dump_module_def_end
    format("end")
  end

  def dump_methods
    @methoddef.collect { |m|
      format(m.dump, 2)
    }.join("\n")
  end

  def dump_value(value)
    if value.respond_to?(:to_src)
      value.to_src
    elsif value.is_a?(::String)
      value.dump
    else
      value
    end
  end
end


end
end


if __FILE__ == $0
  require 'xsd/codegen/moduledef'
  include XSD::CodeGen
  m = ModuleDef.new("Foo::Bar::HobbitName")
  m.defrequire("foo/bar")
  m.defrequire("baz")
  m.comment = <<-EOD
    foo
    bar
    baz
  EOD
  m.defmethod("foo") do
    <<-EOD
      foo.bar = 1
      baz.each do |ele|
        ele + 1
      end
    EOD
  end
  m.defmethod("baz", "qux")
  puts m.dump
end
