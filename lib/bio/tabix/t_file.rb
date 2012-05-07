# == t_file.rb
# This file contains the TFile class used to interact with the tabix api
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
    # The TFile class manages compressing, indexing, opening and parsing tab delimited files.
    # The file must be position sorted prior to indexing.
    class TFile
      require 'bio/tabix/binding'
      include Bio::Tabix::Binding
      # ascii or compressed file name
      attr_accessor :file
      # index name
      attr_accessor :index
      # TabixT created from open index
      attr_accessor :t_file
      # pointer to TabixT
      attr_accessor :t_file_p
      # index build options
      attr_accessor :options
      # compresses the fi into fo using bgzip
      def self.compress(fi, fo)
        `#{File.join(File.expand_path(File.dirname(__FILE__)),'bgzip')} -c #{fi} > #{fo}`
      end
      # Builds an index from the supplied filename and options
      # - :s => sequence/group column [1]
      # - :b => beginning range column [2]
      # - :e => ending range column. Can equal :b. [3]
      # - :meta_char => comment character [#]
      # - :line_skip => number of initial lines to ignore [0]
      def self.build_index(f, opts={})
        conf = ConfT.new
        conf[:preset]=0
        conf[:sc]=opts[:s] || 1
        conf[:bc]=opts[:b] || 2
        conf[:ec]=opts[:e] || 3
        conf[:meta_char]=('#'||opts[:c][0]).ord
        conf[:line_skip]=(0||opts[:S]).to_i
        unless(Bio::Tabix::Binding.bgzf_is_bgzf(f)==1)
          puts "Compressing..."
          self.class.compress(f,f+".bgzf")
          f=f+".bgzf"
        end
        puts "Indexing with #{conf.get_hash}..."
        Bio::Tabix::Binding.ti_index_build2(f,conf,f+".tbi")
      end
      # convenience method to create a new Tabix instance and open it.
      def self.open(*args)
        self.new(*args).open
      end
      # Returns a new TFile. If the file is not compressed, a new compressed 
      # file will be created with compress[compress]. If the index is not present 
      # a new index will be created with build_index[build_index].
      def initialize(f, opts={})
        @file = f
        @options = opts
        @index = file+".tbi"
        return self
      end      
      # opens the file checking for compression and corresponding index.
      def open
        # check existing
        if(@t_file)
          puts "Already open, closing and re-opening"
          self.close
        end
        # check datafile
        if file =~ /http:\/\/|ftp:\/\//
          puts "Expecting remote file: #{file}"
        else
          raise "FileNotFound #{file}" unless(File.exist?(file))
          unless(bgzf_is_bgzf(file)==1)
            unless(bgzf_is_bgzf(file+".bgzf")==1)
              puts "Input does not look like a bgzip compressed file. Attempting compression..."
              self.class.compress(file,file+".bgzf")
            end
            @file = file+".bgzf"
          end
        end
        # check index
        if index =~ /http:\/\/|ftp:\/\//
          puts "Expecting remote index: #{index}"
        elsif !File.exist?(index)
          puts "Index #{index} not found. Building..."
          self.class.build_index(file,options)
        end
        # open
        @t_file_p = ti_open(file,index)
        raise "FileAcessError #{file}" if @t_file_p.null?
        @t_file = TabixT.new(@t_file_p)
        return self
      end
      # closes the TabixT file
      def close
        if(@t_file_p)
          begin
            ti_close(@t_file_p)
            @t_file_p = nil
          rescue
            puts "Error closing file"
          end
        end
      end
      # returns an array of the group names found in the index
      def groups
        load_index
        g_num = FFI::MemoryPointer.new(:int)
        g_ptr = ti_seqname(t_file[:idx],g_num)
        return [] if g_ptr.null? || g_num.null?
        g_ptr.get_array_of_string(0, g_num.read_int).compact
      end
      # returns the header (skipped lines + comments)
      def header
        load_index
        conf = ConfT.new(ti_get_conf(t_file[:idx]))
        iter = IterT.new(ti_query(t_file_p,nil,0,1))
        len = FFI::MemoryPointer.new(:int)
        str = ""
        while( (s = ti_read(t_file_p, iter, len)) )
          break if(s[0].ord != conf[:meta_char]) 
          str << s
          str << "\n"
        end
        ti_iter_destroy(iter)
        @header = str        
      end
      # Iterates over the supplied region calling user_proc on each item
      # a region is defined by a group name and range(pos1 - pos2)
      # all overlapping intervals within the group will be processed in order
      def process_region(group, pos1, pos2, user_proc)
        iter = IterT.new(ti_query(t_file_p,group,pos1,pos2))
        return if iter.null?
        len = FFI::MemoryPointer.new(:int)
        while( (s = ti_read(t_file_p, iter, len)) )
          user_proc.call(s,len)
        end
        ti_iter_destroy(iter)
      end
      
      private
      def load_index
        if t_file[:idx].null?
          t_file[:idx] = ti_index_load(t_file[:fn])
        end
        raise "Index Load Error" if t_file[:idx].null?
      end
      
    end#Index class
  end#Tabix module
end#Bio module