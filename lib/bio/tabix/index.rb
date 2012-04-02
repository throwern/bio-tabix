require 'bio/tabix/binding'

module Bio
  module Tabix
    class Index
      include Bio::Tabix::Binding
      attr_accessor :file,:index,:t_file,:t_file_p
      
      def self.build(f,opts={})        
      end
      
      def self.open(*args)
        self.new(*args).open
      end
      
      def initialize(f,opts={})
        @file = f
        @index = opts[:i]||file+".tbi"
        return self
      end
      
      def open
        if(@t_file)
          self.close
        end
        raise "FileNotFound #{file}" unless(File.exist?(file)) or file =~ /http:\/\/|ftp:\/\//
        raise "FileNotFound #{index} -- use -i to supply custom index" unless(File.exist?(index)) or index =~ /http:\/\/|ftp:\/\//
        @t_file_p = ti_open(file,index)
        raise "FileAcessError #{file}" if @t_file_p.null?
        @t_file = TabixT.new(@t_file_p)
        return self
      end
      
      def close
        if(@t_file_p)
          begin
            ti_close(@t_file_p)
          rescue
            puts "Error closing file"
          end
        end
      end
      
      def process_region(group,pos1,pos2,user_proc)
        iter = IterT.new(ti_query(t_file_p,group,pos1,pos2))
        len = FFI::MemoryPointer.new(:int)
        while( (s = ti_read(t_file_p, iter, len)) )
          user_proc.call(s,len)
        end
        ti_iter_destroy(iter)
      end
    end
  end
end