# == binding.rb
# This file contains the ffi binding declarations for the tabix api
# See https://github.com/ffi/ffi and http://samtools.sourceforge.net/tabix.shtml for details
#
# == Contact
#
# Author::    Nicholas A. Thrower
# Copyright:: Copyright (c) 2012 Nicholas A Thrower
# License::   See LICENSE.txt for more details
#

# -
module Bio
  # -
  module Tabix
    # Ruby binding for the tabix file indexing routines within the samtools package http://samtools.sourceforge.net/
    module Binding
      require 'bio/tabix/library'
      extend FFI::Library
      ffi_lib Bio::Tabix::Library.filename
        
      # CLASSES
      
      # Custom string storage
      # member of the IterT class
      class KString < FFI::Struct
        layout(
        :l,:size_t,
        :m,:size_t,
        :s,:string
        )
      end
      
      # File pointers to text and index data
      # created by ti_open
      # used by ti_read, ti_query, ti_close
      class TabixT < FFI::Struct
        layout(
        :fp,    :pointer,
        :idx,   :pointer,
        :fn,    :string,
        :fnidx, :string
        )
      end
      
      # Iteratator for monitoring the query progress
      # created by the ti_query method
      # used by ti_read
      class IterT < FFI::Struct
        layout(
        :from_first,:int,
        :tid,       :int,
        :beg,       :int,
        :end,       :int,
        :n_off,     :int,
        :i,         :int,
        :finished,  :int,
        :curr_off,  :uint64,
        :str,       KString,
        :idx,       :pointer,
        :off,       :pointer
        )
      end
      # Index configuration
      # used by ti_index_build2
      class ConfT < FFI::Struct
        layout(
        :preset,    :int32,
        :sc,        :int32,
        :bc,        :int32,
        :ec,        :int32,
        :meta_char, :int32,
        :line_skip, :int32
        )
        # convenience method to access attributes
        def get_hash
          {
            :preset => self[:preset],
            :sc => self[:sc],
            :bc => self[:bc],
            :ec => self[:ec],
            :meta_char => self[:meta_char],
            :line_skip => self[:line_skip]
          }
        end
      end
      # FUNCTIONS                                                                   # PARAMETER(S)                          : RETURN
      attach_function :ti_open, [:string, :string], :pointer                        # filename, idxname (or 0)              : TabixT*
      attach_function :ti_read, [:pointer, :pointer, :pointer], :string             # TabixT*, ti_iter_t, len               : string
      attach_function :ti_query, [:pointer,:string,:int,:int], IterT                # TabixT*, name, beg, end               : IterT
      attach_function :ti_close, [:pointer], :void                                  # TabixT*
      attach_function :ti_iter_destroy, [IterT], :void                              # ti_iter_t
      attach_function :ti_index_build2, [:string,:pointer,:string], :int            # filename, ti_conf_t, idxname (or 0)   : 0/-1
      attach_function :bgzf_is_bgzf, [:string], :int                                # filename,                             : 1/0
      attach_function :ti_seqname, [:pointer,:pointer],:pointer                     # ti_index_t*, int*(count)              : char**
      attach_function :ti_index_load,[:string],:pointer                             # filename(no idx suffix)               : ti_index_t*
      attach_function :ti_get_conf,[:pointer],:pointer                              # ti_index_t*                           : ti_conf_t*
    end
  end
end