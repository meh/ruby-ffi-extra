#--
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
#  Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

class Integer
  def to_ffi
    self
  end
end

class String
  def to_ffi
    self
  end
end

class NilClass
  def to_ffi
    self
  end
end

module FFI
  def self.type_size (type)
    type = FFI.find_type(type) if type.is_a?(Symbol)

    if type.is_a?(Type::Builtin) || type.is_a?(Class) && type.ancestors.member?(FFI::Struct) || type.ancestors.member?(FFI::ManagedStruct)
      type.size
    elsif type.respond_to? :from_native
      type.native_type.size
    else
      raise ArgumentError, 'you have to pass a Struct, a Builtin type or a Symbol'
    end
  end

  module Library
    def ffi_lib_add (*names)
      ffi_lib *((begin
        ffi_libraries
      rescue Exception
        []
      end).map {|lib|
        lib.name
      } + names).compact.uniq.reject {|lib|
        lib == '[current process]'
      }
    end

    def has_function? (sym, libraries=nil)
      libraries ||= ffi_libraries

      libraries.any? {|lib|
        if lib.is_a?(DynamicLibrary)
          lib
        else
          DynamicLibrary.new(lib, 0)
        end.find_function(sym.to_s) rescue nil
      }
    end

    def attach_function! (*args, &block)
      begin
        attach_function(*args, &block)
      rescue Exception => e
        false
      end
    end
  end

  class Type::Builtin
    def name
      inspect[/:(\w+) /][1 .. -2]
    end
  end

  class Pointer
    def typecast (type)
      if type.is_a?(Symbol)
        if respond_to? "read_#{type}"
          return send "read_#{type}"
        else
          type = FFI.find_type(type)
        end
      end

      if type.is_a?(Type::Builtin)
        send "read_#{type.name.downcase}"
      elsif type.is_a?(Class) && type.ancestors.member?(FFI::Struct) && !type.ancestors.member?(FFI::ManagedStruct)
        type.new(self)
      elsif type.respond_to? :from_native
        type.from_native(typecast(type.native_type), nil)
      else
        raise ArgumentError, 'you have to pass a Struct, a Builtin type or a Symbol'
      end
    end

    def read_array_of (type, number)
      if type.is_a?(Symbol)
        if respond_to? "read_array_of_#{type}"
          return send "read_array_of_#{type}"
        else
          type = FFI.find_type(type)
        end
      end

      type = type.native_type if type.respond_to? :native_type

      if type.is_a?(Class) && type.ancestors.member?(FFI::Struct) || type.is_a?(FFI::ManagedStruct)
        read_array_of_pointer(number).map {|pointer|
          type.new(pointer)
        }
      else
        begin
          send "read_array_of_#{type.name.downcase}", number
        rescue
          raise ArgumentError, "#{type.name} is not supported"
        end
      end
    end
  end

  find_type(:size_t) rescue typedef(:ulong, :size_t)
end
