# Checks a built site against the live URL inventory.
#
# Usage, from the repo root, after a build into "$out":
#   ruby _scripts/check-urls.rb _scripts/live-url-inventory.tsv "$out"
#
# Every 200 and 403 row must exist as a file in the build. A 302 row only
# needs its trailing-slash target. Paths in the inventory are percent-encoded
# the way the live HTML links them, so each is decoded to the file name
# Jekyll writes. Then lists the files in the build that the inventory doesn't
# have, with the font files counted rather than listed. Exits 1 when anything
# is missing, after a line for Bruin on what to do and, in GitHub Actions, an
# ::error annotation for each missing path. Extra files don't change the exit
# status.
#
# Paths are matched against the build's exact file names, not File.exist?,
# because macOS's file system ignores case and S3 doesn't. A page whose name
# changed case would pass File.exist? on a Mac and return 403 on the live site.
require "set"
require "uri"

inventory, dir = ARGV
abort "usage: check-urls.rb <inventory.tsv> <build dir>" unless inventory && dir && File.directory?(dir)
dir = dir.chomp("/")

built = Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }.map { |f| f.delete_prefix(dir + "/") }
built_set = built.to_set
expected = []
missing = []
File.foreach(inventory) do |line|
  next if line.start_with?("#", "status")
  status, kind, path = line.chomp.split("\t")
  next unless %w[200 302 403].include?(status)
  path += "/" if status == "302"
  file = URI.decode_www_form_component(path.gsub("+", "%2B")).delete_prefix("/")
  file += "index.html" if file.empty? || file.end_with?("/")
  expected << file
  missing << [status, kind, path] unless built_set.include?(file)
end

extra = (built - expected).sort
fonts = extra.count { |f| f.start_with?("assets/fonts/") }

puts "present: #{expected.size - missing.size}"
puts "missing: #{missing.size}"
puts missing.map { |row| row.join("\t") }
unless missing.empty?
  if ENV["GITHUB_ACTIONS"] == "true"
    # GitHub decodes %25 in a workflow command's message, so an encoded path
    # such as pragmatism%E2%80%99s needs its % written as %25.
    missing.each { |_, _, path| puts "::error::#{path.gsub("%", "%25")} is missing from the build" }
  end
  puts 'A page or file that was online before is missing from the site. ' \
       'If you renamed a file or changed its date: line, change it back (see "Where files go" in README.md).'
end
puts "not in the inventory: #{extra.size}"
puts extra.reject { |f| f.start_with?("assets/fonts/") }.map { |f| "  #{f}" }
puts "  assets/fonts/: #{fonts} files" if fonts.positive?
exit(missing.empty? ? 0 : 1)
