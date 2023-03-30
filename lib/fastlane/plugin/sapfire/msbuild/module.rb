require "fastlane/boolean"

module Msbuild
  class BuildType
    NONE = 0
    GENERIC = 1
    UWP = 2
  end

  class Config
    attr_accessor :params
    attr_accessor :msbuild_path
    attr_accessor :overwritten_props
    attr_accessor :certificate
    attr_accessor :certificate_password
    attr_accessor :certificate_thumbprint
    attr_accessor :build_type
  end

  class << self
    attr_accessor :config
  end

  UI = FastlaneCore::UI
  self.config = Config.new
  self.config.build_type = BuildType::NONE
end
