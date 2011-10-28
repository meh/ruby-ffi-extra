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

require 'ffi/extra'

module FFI

class ExecutableMemoryPointer < Pointer
	module C
		extend  FFI::Library

		ffi_lib FFI::Library::LIBC

		attach_function :mmap, [:pointer, :size_t, :int, :int, :int, :off_t], :pointer
		attach_function :munmap, [:pointer, :size_t], :int
		attach_function :getpagesize, [], :int
	end

	def self.round_up (base)
		page_size = C.getpagesize
		over      = base % page_size

		base + (over > 0 ? page_size - over : 0)
	end

	def self.alloc (size)
		size = round_up(size)
		base = C.mmap(nil, size, 0x01 | 0x02 | 0x04, 0x02 | 0x20, -1, 0)
		# PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS

		return nil if base.address == -1

		return base, size
	end

	def self.free (pointer, size)
		C.munmap(address, size)
	end

	def self.from_string (string)
		new(string.size).tap {|p|
			p.write_string(string)
		}
	end

	attr_reader :size

	def initialize (size)
		address, size = self.class.alloc(size)

		ObjectSpace.define_finalizer self, self.class.finalizer(address, size)

		super(address)

		@size = size
	end

	def self.finalizer (address, size)
		proc {
			self.free(address, size)
		}
	end

	def inspect
		"#<FFI::ExecutableMemoryPointer address=0x#{'%x' % address} size=#{size}>"
	end
end

end
