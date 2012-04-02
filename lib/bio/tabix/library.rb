module Bio
  module Tabix
    class Library
      def self.filename
        lib_os = case RUBY_PLATFORM
        when /linux/
          'so.1'
        when /darwin/
          '1.dylib'
        else
          case RUBY_DESCRIPTION
          when /darwin.*java/
            '1.dylib'
          when /linux.*java/
          'so.1'
          else raise NotImplementedError, "Tabix not supported on your platform"
          end
        end

        File.join(File.expand_path(File.dirname(__FILE__)),"libtabix.#{lib_os}")
      end
      #module_function :filename
    end
  end
end