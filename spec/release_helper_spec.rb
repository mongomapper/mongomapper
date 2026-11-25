# Runs without MongoDB: only exercises the release helpers used by `rake release`.
require File.expand_path('../../rakelib/release_runner', __FILE__)

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

  it 'keeps the raw section text for review' do
    section[:text].should start_with("## 1.2.3 - 2030-01-02\n\n### Enhancements:\n")
    section[:text].should end_with("- PR-3 Jane Doe <jane@example.com> Fix a crash\n")
  end

  it 'builds the post URL' do
    ReleaseHelper.post_url('0.18.1', '2026-11-24').should eq('https://mongomapper.com/blog/2026/11/24/release-0-18-1')
  end

  it 'sets the version' do
    ReleaseHelper.set_version("module MongoMapper\n  Version = '0.18.1'\nend\n", '0.19.0')
      .should eq("module MongoMapper\n  Version = '0.19.0'\nend\n")
  end

  describe 'changelog draft' do
    it 'groups PR titles' do
      ReleaseHelper.changelog_group('Fix memory leak').should eq('Bug Fixes')
      ReleaseHelper.changelog_group('Fixes #12: nil keys').should eq('Bug Fixes')
      ReleaseHelper.changelog_group('Fix typo in README').should eq('Doc Fixes')
      ReleaseHelper.changelog_group('Update docs for scopes').should eq('Doc Fixes')
      ReleaseHelper.changelog_group('Add MongoDB 9.0 to CI').should eq('Enhancements')
      ReleaseHelper.changelog_group('Prefix keys').should eq('Enhancements')
    end

    it 'skips release PRs' do
      ReleaseHelper.release_pr?('Prepare 0.18.1 release').should be(true)
      ReleaseHelper.release_pr?('Release 0.18.0').should be(true)
      ReleaseHelper.release_pr?('Release notes typo').should be(false)
    end

    it 'cleans up titles' do
      ReleaseHelper.changelog_description('reduce allocations (rebased).').should eq('Reduce allocations')
    end

    it 'credits the first human author' do
      authors = ['Cursor Agent <cursoragent@cursor.com>', 'Jane Doe <jane@example.com>', 'John Roe <john@example.com>']
      ReleaseHelper.pick_author(authors).should eq('Jane Doe <jane@example.com>')
      ReleaseHelper.pick_author(['dependabot[bot] <x@example.com>']).should be_nil
    end

    it 'formats grouped bullets sorted by PR, omitting empty groups' do
      prs = [
        { number: 9, title: 'Fix a crash', author: 'Jane Doe <jane@example.com>' },
        { number: 7, title: 'Add a feature', author: 'John Roe <john@example.com>' },
        { number: 8, title: 'Prepare 1.2.3 release', author: 'Jane Doe <jane@example.com>' },
        { number: 5, title: 'Add more', author: 'Jane Doe <jane@example.com>' }
      ]
      ReleaseHelper.draft_changelog_section('1.2.3', '2030-01-02', prs).should eq(<<-MD.gsub(/^ {8}/, ''))
        ## 1.2.3 - 2030-01-02

        ### Enhancements:

        - PR-5 Jane Doe <jane@example.com> Add more
        - PR-7 John Roe <john@example.com> Add a feature

        ### Bug Fixes:

        - PR-9 Jane Doe <jane@example.com> Fix a crash

      MD
    end

    it 'inserts the draft above the latest release and parses back' do
      draft = ReleaseHelper.draft_changelog_section('1.2.4', '2030-02-03',
                                                    [{ number: 10, title: 'Fix docs build', author: 'A <a@example.com>' }])
      updated = ReleaseHelper.insert_changelog_section(changelog, draft)
      updated.should start_with("<!-- ## Unreleased -->\n\n## 1.2.4 - 2030-02-03\n")
      updated.should include("Fix docs build\n\n## 1.2.3 - 2030-01-02\n")
      ReleaseHelper.changelog_section(updated, '1.2.4')[:descriptions].should eq(['Fix docs build'])
      ReleaseHelper.changelog_section(updated, '1.2.3').should eq(section)
    end
  end
end

describe ReleaseRunner do
  let(:runner) { ReleaseRunner.new('1.2.3', true) }
  let(:changelog) { "## 1.2.3 - 2030-01-02\n\n- PR-1 A <a@example.com> Add x\n" }

  def origin_master(version_rb, changelog_md)
    allow(runner).to receive(:file_at).with('origin/master', ReleaseRunner::VERSION_FILE).and_return(version_rb)
    allow(runner).to receive(:file_at).with('origin/master', 'CHANGELOG.md').and_return(changelog_md)
  end

  it 'names the prep branch and tag' do
    runner.branch.should eq('prepare-1.2.3-release')
    runner.tag.should eq('v1.2.3')
  end

  it 'treats the prep PR as merged once origin/master has the version and changelog' do
    origin_master("Version = '1.2.3'", changelog)
    runner.prep_merged?.should be(true)
  end

  it 'does not treat the prep PR as merged when either piece is missing' do
    origin_master("Version = '1.2.2'", changelog)
    runner.prep_merged?.should be(false)
    origin_master("Version = '1.2.3'", "## 1.2.2 - 2029-01-01\n")
    runner.prep_merged?.should be(false)
  end
end
