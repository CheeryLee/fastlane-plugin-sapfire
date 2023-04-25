module Fastlane
  module Helper
    class SapfireHelper
      def self.dotnet_specified?
        path = Actions.lane_context[Fastlane::Actions::SharedValues::SF_DOTNET_PATH] || ""
        path = File.expand_path(path) unless path.empty?

        if path.empty?
          UI.error("The path to dotnet executable is not specified")
          return false
        elsif !File.exist?(path)
          UI.error("File '#{path}' doesn't exist")
          return false
        elsif !path.end_with?("dotnet") && !path.end_with?("dotnet.exe")
          UI.error("The path to dotnet doesn't point to executable file: #{path}")
          return false
        end

        true
      end

      def self.msbuild_specified?
        path = Actions.lane_context[Fastlane::Actions::SharedValues::SF_MSBUILD_PATH] || ""
        path = File.expand_path(path) unless path.empty?

        if path.empty?
          UI.error("The path to MSBuild executable is not specified")
          return false
        elsif !File.exist?(path)
          UI.error("File '#{path}' doesn't exist")
          return false
        elsif !path.end_with?("MSBuild.dll") && !path.end_with?("MSBuild.exe")
          UI.error("The path to MSBuild doesn't point to executable or DLL file: #{path}")
          return false
        end

        true
      end

      def self.kits_10_location
        require "win32/registry"

        Win32::Registry::HKEY_LOCAL_MACHINE.open("SOFTWARE\\Wow6432Node\\Microsoft\\Windows Kits\\Installed Roots") do |reg|
          value = reg["KitsRoot10"]
          return value.strip
        end
      end
    end
  end
end
