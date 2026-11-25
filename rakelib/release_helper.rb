# Small, dependency-free helpers used by the release tasks in the Rakefile.
# Kept Ruby 2.4 compatible and free of git/network access so they can be unit
# tested (see spec/release_helper_spec.rb).
module ReleaseHelper
  CHANGELOG_URL = 'https://github.com/mongomapper/mongomapper/blob/master/CHANGELOG.md'.freeze

  module_function

  # Returns { heading:, date:, descriptions: [...] } for `## VERSION - YYYY-MM-DD`,
  # or nil if CHANGELOG has no dated heading for that version.
  def changelog_section(changelog, version)
    lines = changelog.lines.map(&:chomp)
    start = lines.index { |l| l =~ /\A## #{Regexp.escape(version)} - \d{4}-\d{2}-\d{2}\s*\z/ }
    return nil unless start

    heading = lines[start].sub(/\A## /, '').strip
    body = lines[(start + 1)..-1].take_while { |l| l !~ /\A## / }
    descriptions = body.grep(/\A- /).map do |l|
      l.sub(/\A- /, '').sub(/\APR-\d+ .*?<[^>]*>\s*/, '').strip.sub(/\.\z/, '')
    end

    { heading: heading, date: heading[/\d{4}-\d{2}-\d{2}\z/], descriptions: descriptions }
  end

  # GitHub-style anchor: "0.18.1 - 2026-11-24" => "0181---2026-11-24"
  def changelog_anchor(heading)
    heading.downcase.gsub(/[^a-z0-9 _-]/, '').tr(' ', '-')
  end

  # "Fix memory leak" => "fixes memory leak". Only touches a leading
  # capitalized imperative verb; anything else is left as written.
  def third_person(description)
    verb, rest = description.split(' ', 2)
    return description unless verb =~ /\A[A-Z][a-z]+\z/

    verb = verb.downcase
    verb = if verb =~ /[^aeiou]y\z/ then verb.sub(/y\z/, 'ies')
           elsif verb =~ /(ss|sh|ch|x|z)\z/ then verb + 'es'
           elsif verb =~ /s\z/ then verb
           else verb + 's'
           end
    [verb, rest].compact.join(' ')
  end

  def highlight(descriptions)
    items = descriptions.map { |d| third_person(d) }
    return nil if items.empty?

    list = items.size < 3 ? items.join(' and ') : "#{items[0..-2].join(', ')}, and #{items[-1]}"
    "This release #{list}."
  end

  def post_filename(version, date)
    "_posts/#{date}-release-#{version.tr('.', '-')}.md"
  end

  def render_post(version, section)
    paragraphs = [
      "MongoMapper #{version} has been released.",
      highlight(section[:descriptions]),
      'Thanks to the many contributors!',
      "See the [changelog](#{CHANGELOG_URL}##{changelog_anchor(section[:heading])}) for full details."
    ].compact

    "---\ntitle: MongoMapper #{version} Release\nlayout: post\nauthor: Scott Taylor\n---\n\n" +
      paragraphs.join("\n\n") + "\n"
  end
end
