#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "xcodeproj"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "SuperClose.xcodeproj")
FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)

project_config_ref = project.main_group.new_file("Config/Project.xcconfig")

app_group = project.main_group.new_group("SuperClose", "SuperClose")
tests_group = project.main_group.new_group("SuperCloseTests", "SuperCloseTests")
packaging_group = project.main_group.new_group("packaging", "packaging")
packaging_group.new_group("homebrew", "packaging/homebrew")
project.main_group.new_group("scripts", "scripts")
config_group = project.main_group["Config"] || project.main_group.new_group("Config", "Config")
config_group.new_file("Signing.local.xcconfig.example")

%w[App Models Rules Inspection Actions Permissions UI Resources].each do |name|
  app_group.new_group(name, "SuperClose/#{name}")
end

app_target = project.new_target(:application, "SuperClose", :osx, "14.0")
test_target = project.new_target(:unit_test_bundle, "SuperCloseTests", :osx, "14.0")
test_target.add_dependency(app_target)

app_sources = Dir.glob(File.join(root, "SuperClose", "**", "*.swift")).sort
test_sources = Dir.glob(File.join(root, "SuperCloseTests", "*.swift")).sort

def ensure_group_path(root_group, components)
  current = root_group
  components.each do |component|
    current = current[component] || current.new_group(component)
  end
  current
end

app_sources.each do |path|
  relative = path.delete_prefix("#{root}/")
  components = relative.split("/")
  group = ensure_group_path(project.main_group, components[0..-2])
  ref = group.new_file(relative)
  app_target.add_file_references([ref])
end

test_sources.each do |path|
  relative = path.delete_prefix("#{root}/")
  ref = tests_group.new_file(relative)
  test_target.add_file_references([ref])
end

resources_group = ensure_group_path(project.main_group, ["SuperClose", "Resources"])
resources_ref = resources_group.new_file("SuperClose/Resources/Assets.xcassets")
app_target.add_resources([resources_ref])

app_target.build_configurations.each do |config|
  config.base_configuration_reference = project_config_ref
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "io.github.kevin.superclose"
  config.build_settings["INFOPLIST_FILE"] = "SuperClose/Resources/Info.plist"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
  config.build_settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = ["$(inherited)", "@executable_path/../Frameworks"]
end

test_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "io.github.kevin.superclose.tests"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["INFOPLIST_FILE"] = ""
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["TEST_HOST"] = ""
  config.build_settings["BUNDLE_LOADER"] = ""
end

project.build_configurations.each do |config|
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.set_launch_target(app_target)
scheme.add_test_target(test_target)
scheme.save_as(project_path, "SuperClose", true)

project.save

puts "Generated #{project_path}"

