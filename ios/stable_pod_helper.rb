# This is a stable bridge to ensure CocoaPods can always find the Flutter SDK.
# It is checked into the repository to avoid dependency on ephemeral generated files.

def find_flutter_root
  # 1. Check environment variable
  return ENV['FLUTTER_ROOT'] if ENV['FLUTTER_ROOT'] && Dir.exist?(ENV['FLUTTER_ROOT'])

  # 2. Check Generated.xcconfig (local and server paths)
  xcconfig_path = File.expand_path(File.join('Flutter', 'Generated.xcconfig'), __dir__)
  if File.exist?(xcconfig_path)
    File.foreach(xcconfig_path) do |line|
      matches = line.match(/\AFLUTTER_ROOT=(.*)\z/)
      if matches
        root = matches[1].strip
        return root if Dir.exist?(root)
      end
    end
  end

  # 3. Dedicated Mac builder paths
  ['/Users/builder/programs/flutter', '/opt/flutter', '/usr/local/share/flutter'].each do |path|
    return path if Dir.exist?(path)
  end

  nil
end

flutter_root = find_flutter_root

if flutter_root
  podhelper_path = File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper.rb')
  if File.exist?(podhelper_path)
    puts "[FUELDIRECT] Loading official podhelper from: #{podhelper_path}"
    # Use load to ensure it's evaluated in the top-level scope of the Podfile
    load podhelper_path
  else
    puts "[FUELDIRECT] Warning: podhelper.rb not found at #{podhelper_path}"
  end
else
  puts "[FUELDIRECT] Error: Could not locate Flutter SDK."
end
