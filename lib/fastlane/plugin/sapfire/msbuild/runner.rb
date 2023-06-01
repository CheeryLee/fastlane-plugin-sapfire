require "open3"
require "fastlane_core/print_table"
require_relative "module"
require_relative "options"
require_relative "../sln_project/module"
require_relative "../helper/sapfire_helper"

module Msbuild
  class Runner
    def run
      params = Msbuild.config.params

      FastlaneCore::PrintTable.print_values(config: params, title: "Summary for msbuild")
      UI.user_error!("Can't find MSBuild") unless Fastlane::Helper::SapfireHelper.msbuild_specified?
      UI.user_error!("Can't find dotnet. You selected MSBuild as a library, so dotnet is required to work with it. ") if
        Msbuild.config.msbuild_type == Msbuild::MsbuildType::LIBRARY && !Fastlane::Helper::SapfireHelper.dotnet_specified?

      prev_cwd = Dir.pwd
      working_directory = File.dirname(File.expand_path(params[:project]))
      UI.message("Change working directory to #{working_directory}")
      Dir.chdir(working_directory)

      params[:jobs] = 1 if params[:jobs].zero?
      msbuild_path = Msbuild.config.msbuild_path
      msbuild_args = get_msbuild_args(params, Msbuild.config.overwritten_props)
      cmd = "#{msbuild_path} #{msbuild_args.join(" ")}"

      check_configuration_platform(params)
      UI.command(cmd)

      Open3.popen2(cmd) do |_, stdout, wait_thr|
        until stdout.eof?
          stdout.each do |l|
            line = l.force_encoding("utf-8").chomp
            puts line
          end
        end

        UI.user_error!("MSBuild execution failed. See the log above.") unless wait_thr.value.success?
        UI.success("MSBuild has ended successfully") if wait_thr.value.success?
      end

      rename_package(params)

      UI.message("Change working directory back to #{prev_cwd}")
      Dir.chdir(prev_cwd)
    end

    def get_project_property_string(key, value)
      "-p:#{key}=#{value}"
    end

    def get_msbuild_args(params, overwritten_props)
      args = []

      if params.values.include?(:properties)
        params[:properties].each do |key, value|
          unless overwritten_props.include?(key)
            args.append(get_project_property_string(key, value))
            next
          end

          # Remove properties that would be overwritten by this action
          UI.important("Property #{key} will be ignored. Use `#{overwritten_props[key]}` option instead.")
        end
      end

      configuration = params[:configuration] if
        params.values.include?(:configuration) && !params[:configuration].empty?

      platform = params[:platform] if
        params.values.include?(:platform) && !params[:platform].empty?

      need_restore = ([true].include?(params[:restore]) if params.values.include?(:restore)) || false

      need_clean = ([true].include?(params[:clean]) if params.values.include?(:clean)) || false

      appx_output_path = File.expand_path(params[:appx_output_path]) if
        params.values.include?(:appx_output_path) && !params[:appx_output_path].empty?

      appx_bundle_platforms = params[:appx_bundle_platforms] if
        params.values.include?(:appx_bundle_platforms) && !params[:appx_bundle_platforms].empty?

      build_mode = params[:build_mode] if
        params.values.include?(:build_mode) && !params[:build_mode].empty?

      certificate = Msbuild.config.certificate unless
        Msbuild.config.certificate.nil? || Msbuild.config.certificate.empty?

      certificate_password = Msbuild.config.certificate_password unless
        Msbuild.config.certificate_password.nil? || Msbuild.config.certificate_password.empty?

      certificate_thumbprint = Msbuild.config.certificate_thumbprint unless
        Msbuild.config.certificate_thumbprint.nil? || Msbuild.config.certificate_thumbprint.empty?

      signing_enabled = !params[:skip_codesigning] if params.values.include?(:skip_codesigning)

      args.append("-p:Configuration=\"#{configuration}\"") unless configuration.nil?
      args.append("-p:Platform=\"#{platform}\"") unless platform.nil?
      args.append("-p:AppxPackageDir=\"#{appx_output_path}\"") unless appx_output_path.nil?
      args.append("-p:AppxBundlePlatforms=\"#{appx_bundle_platforms}\"") unless appx_bundle_platforms.nil?
      args.append("-p:AppxBundle=Always") if Msbuild.config.build_type == Msbuild::BuildType::UWP
      args.append("-p:UapAppxPackageBuildMode=#{build_mode}") unless build_mode.nil?
      args.append("-p:AppxPackageSigningEnabled=#{signing_enabled}") unless signing_enabled.nil?
      args.append("-p:PackageCertificateKeyFile=\"#{certificate}\"") unless certificate.nil?
      args.append("-p:PackageCertificatePassword=#{certificate_password}") unless certificate_password.nil?
      args.append("-p:PackageCertificateThumbprint=#{certificate_thumbprint}") unless certificate_thumbprint.nil?
      args.append("-m#{params[:jobs].positive? ? ":#{params[:jobs]}" : ""}")
      args.append("-r") if need_restore || Msbuild.config.build_type == Msbuild::BuildType::NUGET

      args.append("-t:Clean;Build") if need_clean
      args.append("-t:Pack") if Msbuild.config.build_type == Msbuild::BuildType::NUGET

      args
    end

    def check_configuration_platform(params)
      configuration = params[:configuration] if
        params.values.include?(:configuration) && !params[:configuration].empty?

      platform = params[:platform] if
        params.values.include?(:platform) && !params[:platform].empty?

      root_block = SlnProject.open(params[:project])
      platforms = root_block.global.solution_configuration_platforms.platforms

      UI.user_error!("Configuration #{configuration} was not found in the solution") if
        configuration.nil? || !platforms.key?(configuration)
      UI.user_error!("Platform #{platform} for configuration #{configuration} was not found in the solution") if
        platform.nil? || !platforms[configuration].include?(platform)

      appx_bundle_platforms = params[:appx_bundle_platforms] if
        params.values.include?(:appx_bundle_platforms) && !params[:appx_bundle_platforms].empty?
      return if appx_bundle_platforms.nil?

      appx_bundle_platforms.split("|").each do |x|
        UI.user_error!("Platform #{x} for APPX bundle was not found in the solution") if
          x.nil? || !platforms[configuration].include?(x)
      end
    end

    def rename_package(params)
      appx_output_name = params[:appx_output_name] if
        params.values.include?(:appx_output_name) && !params[:appx_output_name].empty?

      return if appx_output_name.nil? || appx_output_name.empty?

      appx_output_path = File.expand_path(params[:appx_output_path]) if
        params.values.include?(:appx_output_path) && !params[:appx_output_path].empty?
      appx_output_path = "./" if appx_output_path.nil? || appx_output_path.empty?

      Msbuild::Options::PACKAGE_FORMATS.each do |extension|
        entries = Dir.glob("#{appx_output_path}/**/*").find_all { |x| x.end_with?(extension) }
        next if entries.nil? || entries.empty?

        entries.each do |entry|
          new_name = File.join(File.dirname(entry), "#{appx_output_name}#{extension}")
          UI.message("Rename #{entry} to #{new_name}")
          File.rename(entry, new_name)
        end
      end
    end

    public(:run)
    private(:get_project_property_string)
    private(:get_msbuild_args)
    private(:check_configuration_platform)
    private(:rename_package)
  end
end
