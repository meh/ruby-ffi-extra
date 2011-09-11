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
		def read (type)
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
		end; alias typecast read

		def write (what, type=nil)
			if type
				if respond_to? "write_#{type.downcase}"
					send "write_#{type.downcase}", what
				else
					write_bytes what, what.size
				end
			else
				case what
					when FFI::Struct then write_bytes what.pointer.read_bytes(what.size)
					when String      then write_bytes what
					else raise ArgumentError, 'I do not know how to deal with this variable'
				end
			end
		end

		def read_array_of (number, type)
			if type.is_a?(Symbol)
				if respond_to? "read_array_of_#{type.downcase}"
					return send "read_array_of_#{type.downcase}", number
				else
					type = FFI.find_type(type)
				end
			end

			type = type.native_type if type.respond_to? :native_type

			if type.is_a?(Class) && type.ancestors.member?(FFI::Struct)
				read_array_of_pointer(number).map {|pointer|
					type.new(pointer)
				}
			else
				begin
					send "read_array_of_#{type.name.downcase}", number
				rescue NameError
					raise ArgumentError, "#{type.name} is not supported"
				end
			end
		end

		def write_array_of (data, type)
			if type.is_a?(Symbol)
				if respond_to? "write_array_of_#{type}"
					return send "write_array_of_#{type}", data
				else
					type = FFI.find_type(type)
				end
			end

			type = type.native_type if type.respond_to? :native_type

			if type.is_a?(Class) && type.ancestors.member?(FFI::Struct)
				write_array_of_pointer(data)
			else
				begin
					send "write_array_of_#{type.name.downcase}", data
				rescue NameError
					raise ArgumentError, "#{type.name} is not supported"
				end
			end
		end
	end

	find_type(:size_t) rescue  typedef(:ulong, :size_t)
	find_type(:ssize_t) rescue typedef(:long,  :ssize_t)
end
