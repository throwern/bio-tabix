require 'bio/tabix/library'
module Bio
  module Tabix
    module Binding
      extend FFI::Library
      ffi_lib Bio::Tabix::Library.filename
        
      # CLASSES
      class KString < FFI::Struct
        layout(
        :l,:size_t,
        :m,:size_t,
        :s,:string)
      end
      
      class TabixT < FFI::Struct
        layout(
        :fp,:pointer,
        :idx,:pointer,
        :fn,:string,
        :fnidx,:string
        )
      end
      
      class IterT < FFI::Struct
        layout(
        :from_first,:int,
        :tid,:int,
        :beg,:int,
        :end,:int,
        :n_off,:int,
        :i,:int,
        :finished,:int,
        :curr_off,:uint64,
        :str,KString,
        :idx,:pointer,
        :off,:pointer)
      end
      
      # FUNCTIONS
      attach_function :ti_open, [:string, :string], :pointer                        # filename, idxname (or 0)    : TabixT*
      attach_function :ti_read, [:pointer, :pointer, :pointer], :string             # TabixT*, ti_iter_t, len     : string
      attach_function :ti_query, [:pointer,:string,:int,:int], IterT                # TabixT*, name, beg, end     : IterT
      attach_function :ti_close, [:pointer], :void                                  # TabixT*
      attach_function :ti_iter_destroy, [IterT], :void                              # ti_iter_t
      
    end
  end
end