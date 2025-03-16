#!/usr/bin/env ruby

require 'xcodeproj'

# Path to your .xcodeproj file
project_path = 'DocScannerTest.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
main_target = project.targets.find { |target| target.name == 'DocScannerTest' }

if main_target
  # Get the build configurations
  main_target.build_configurations.each do |config|
    # Enable generated Info.plist
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    
    # Remove reference to the custom Info.plist file
    config.build_settings.delete('INFOPLIST_FILE')
    
    # Set the base configuration to use our xcconfig file
    config.base_configuration_reference = project.new_file('xcconfig/GeneratedInfoPlist.xcconfig')
  end
  
  # Save the project
  project.save
  puts "Project updated successfully!"
else
  puts "Error: Could not find the main target 'DocScannerTest'"
end
