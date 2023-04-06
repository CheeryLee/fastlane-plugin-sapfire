require "open3"
require "fastlane_core/print_table"
require_relative "module"
require_relative "../sln_project/module"

module Msbuild
  class Runner
    def run
      params = Msbuild.config.params

      FastlaneCore::PrintTable.print_values(config: params, title: "Summary for msbuild")

      params[:jobs] = 1 if params[:jobs].zero?
      prev_cwd = Dir.pwd
      working_directory = File.dirname(File.expand_path(params[:project]))
      msbuild_path = Msbuild.config.msbuild_path
      msbuild_args = get_msbuild_args(params, Msbuild.config.overwritten_props)
      cmd = "\"#{msbuild_path}\" #{msbuild_args.join(" ")}"

      check_configuration_platform(params)

      UI.message("Change working directory to #{working_directory}")
      Dir.chdir(working_directory)

      UI.command(cmd)
      Open3.pipeline(cmd)

      UI.user_error!("MSBuild execution failed. See the log above.") unless $?.success?
      UI.success("MSBuild has ended successfully") if $?.success?

      UI.message("Change working directory back to #{prev_cwd}")
      Dir.chdir(prev_cwd)
    end

    def get_project_property_string(key, value)
      "-p:#{key}=#{value}"
    end

    def get_msbuild_args(params, overwritten_props)
      args = []

      params[:properties].each do |key, value|
        unless overwritten_props.include?(key)
          args.append(get_project_property_string(key, value))
          next
        end

        # Remove properties that would be overwritten by this action
        UI.important("Property #{key} will be ignored. Use `#{overwritten_props[key]}` option instead.")
      end

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

      args.append("-p:Configuration=#{params[:configuration]}")
      args.append("-p:Platform=#{params[:platform]}")
      args.append("-p:AppxPackageDir=\"#{appx_output_path}\"") unless appx_output_path.nil?
      args.append("-p:AppxBundlePlatforms=\"#{appx_bundle_platforms}\"") unless appx_bundle_platforms.nil?
      args.append("-p:AppxBundle=Always") if Msbuild.config.build_type == Msbuild::BuildType::UWP
      args.append("-p:UapAppxPackageBuildMode=#{build_mode}") unless build_mode.nil?
      args.append("-p:AppxPackageSigningEnabled=#{signing_enabled}") unless signing_enabled.nil?
      args.append("-p:PackageCertificateKeyFile=\"#{certificate}\"") unless certificate.nil?
      args.append("-p:PackageCertificatePassword=#{certificate_password}") unless certificate_password.nil?
      args.append("-p:PackageCertificateThumbprint=#{certificate_thumbprint}") unless certificate_thumbprint.nil?
      args.append("-m#{params[:jobs].positive? ? ":#{params[:jobs]}" : ""}")
      args.append("-r") if [true].include?(params[:restore])
      args.append("-t:Clean;Build") if [true].include?(params[:clean])

      args
    end

    def check_configuration_platform(params)
      configuration = params[:configuration]
      platform = params[:platform]
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

    public(:run)
    private(:get_project_property_string)
    private(:get_msbuild_args)
    private(:check_configuration_platform)
  end
end
