# Small, dependency-free helpers used by the release tasks (see
# rakelib/release_runner.rb). Kept Ruby 2.4 compatible and free of git/network
# access so they can be unit tested (see spec/release_helper_spec.rb).
module ReleaseHelper
  CHANGELOG_URL = 'https://github.com/mongomapper/mongomapper/blob/master/CHANGELOG.md'.freeze
  CHANGELOG_GROUPS = ['Enhancements', 'Bug Fixes', 'Doc Fixes'].freeze
  # Commit authors that should not be credited in the changelog.
  BOT_AUTHOR = /cursor agent|cursoragent@|\[bot\]|copilot|noreply@anthropic\.com/i

  module_function

  # Returns { heading:, date:, descriptions: [...], text: } for `## VERSION - YYYY-MM-DD`,
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

    { heading: heading, date: heading[/\d{4}-\d{2}-\d{2}\z/], descriptions: descriptions,
      text: ([lines[start]] + body).join("\n").rstrip + "\n" }
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

  def post_url(version, date)
    "https://mongomapper.com/blog/#{date.tr('-', '/')}/release-#{version.tr('.', '-')}"
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

  # Sets `Version = '...'` in lib/mongo_mapper/version.rb source.
  def set_version(source, version)
    source.sub(/Version = '[^']*'/, "Version = '#{version}'")
  end

  # PRs like "Prepare 0.18.1 release" / "Release 0.18.0" are not changelog entries.
  def release_pr?(title)
    !!(title =~ /\A(prepare|release)\s+v?\d+\.\d+\.\d+/i)
  end

  def changelog_group(title)
    case title
    when /\b(docs?|documentation|readme|typos?)\b/i then 'Doc Fixes'
    when /\bfix(es|ed)?\b|\bbugs?\b/i then 'Bug Fixes'
    else 'Enhancements'
    end
  end

  # "reduce allocations (rebased)." => "Reduce allocations"
  def changelog_description(title)
    text = title.strip.sub(/\.\z/, '').sub(/\s*\(rebased\)\z/i, '')
    text.empty? ? text : text[0].upcase + text[1..-1]
  end

  # First human "Name <email>" from a PR's commit authors (oldest first), or nil.
  def pick_author(authors)
    authors.find { |a| a !~ BOT_AUTHOR }
  end

  # prs: [{ number: 1, title: 'Fix x', author: 'Name <email>' }, ...]
  def draft_changelog_section(version, date, prs)
    groups = {}
    prs.reject { |pr| release_pr?(pr[:title]) }.sort_by { |pr| pr[:number] }.each do |pr|
      (groups[changelog_group(pr[:title])] ||= []) <<
        "- PR-#{pr[:number]} #{pr[:author]} #{changelog_description(pr[:title])}"
    end

    text = "## #{version} - #{date}\n\n"
    CHANGELOG_GROUPS.each do |group|
      text << "### #{group}:\n\n#{groups[group].join("\n")}\n\n" if groups[group]
    end
    text
  end

  # Inserts a section above the first released version ("## 1.2.3 ...").
  def insert_changelog_section(changelog, section)
    lines = changelog.lines
    index = lines.index { |l| l =~ /\A## \d/ } || lines.size
    (lines[0...index] + [section] + lines[index..-1]).join
  end
end
