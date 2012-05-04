# == library.rb
# This file contains the Library Class for retrieving platform specific library names
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
    # Cross-platform library naming
    class Library
      # return the platform specific library name
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
    end
  end
end