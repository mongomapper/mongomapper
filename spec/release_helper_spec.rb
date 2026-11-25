# Runs without MongoDB: only exercises the release helper used by the Rakefile.
require File.expand_path('../../rakelib/release_helper', __FILE__)

describe ReleaseHelper do
  let(:changelog) do
    <<-MD
<!-- ## Unreleased -->

## 1.2.3 - 2030-01-02

### Enhancements:

- PR-1 Jane Doe <jane@example.com> Add a feature
- PR-2 John Roe <john@example.com> Reduce allocations in Foo#bar.

### Bug Fixes:

- PR-3 Jane Doe <jane@example.com> Fix a crash

## 1.2.2 - 2029-12-01

- PR-0 Old Entry <old@example.com> Should not appear
    MD
  end

  let(:section) { ReleaseHelper.changelog_section(changelog, '1.2.3') }

  it 'parses the dated heading and bullet descriptions for the version only' do
    section[:heading].should eq('1.2.3 - 2030-01-02')
    section[:date].should eq('2030-01-02')
    section[:descriptions].should eq(['Add a feature', 'Reduce allocations in Foo#bar', 'Fix a crash'])
  end

  it 'returns nil without a dated heading for the version' do
    ReleaseHelper.changelog_section(changelog, '1.2.4').should be_nil
    ReleaseHelper.changelog_section("## 1.2.3\n", '1.2.3').should be_nil
  end

  it 'builds the GitHub changelog anchor' do
    ReleaseHelper.changelog_anchor('0.18.1 - 2026-11-24').should eq('0181---2026-11-24')
  end

  it 'builds the post filename' do
    ReleaseHelper.post_filename('1.2.3', '2030-01-02').should eq('_posts/2030-01-02-release-1-2-3.md')
  end

  it 'conjugates leading verbs' do
    ReleaseHelper.third_person('Fix bug').should eq('fixes bug')
    ReleaseHelper.third_person('Add x').should eq('adds x')
    ReleaseHelper.third_person('Apply y').should eq('applies y')
    ReleaseHelper.third_person('MongoDB 9.0 support').should eq('MongoDB 9.0 support')
  end

  it 'renders the post' do
    ReleaseHelper.render_post('1.2.3', section).should eq(<<-MD.gsub(/^ {6}/, ''))
      ---
      title: MongoMapper 1.2.3 Release
      layout: post
      author: Scott Taylor
      ---

      MongoMapper 1.2.3 has been released.

      This release adds a feature, reduces allocations in Foo#bar, and fixes a crash.

      Thanks to the many contributors!

      See the [changelog](https://github.com/mongomapper/mongomapper/blob/master/CHANGELOG.md#123---2030-01-02) for full details.
    MD
  end
end
