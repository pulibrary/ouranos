# frozen_string_literal: true
require "rails_helper"
require "ouranos/comparison/linked"
require "support/helpers/comparison_helper"

describe "Ouranos::Comparison::Linked" do
  include ComparisonHelper

  let(:comparison) do
    {
      html_url: "https://github.com/org/repo/compare/sha...sha",
      total_commits: 1,
      commits: [
        build_commit_hash("Commit message #123"),
        build_commit_hash("Another commit")
      ],
      files: [{
        additions: 1,
        deletions: 2,
        changes: 3
      }, {
        additions: 1,
        deletions: 2,
        changes: 3
      }]
    }
  end

  describe "#changes" do
    it "prints out a formatted and linked list of commit changes" do
      formatter = Ouranos::Comparison::Linked.new(comparison, "org/repo")

      expect(formatter.changes).to eq(
        <<-CHANGES.strip_heredoc.strip
          Total Commits: 1
          2 Additions, 4 Deletions, 6 Changes

          [sha](https://github.com/org/repo/commit/sha) by [login](https://github.com/login): Commit message [#123](https://github.com/org/repo/issues/123)
          [sha](https://github.com/org/repo/commit/sha) by [login](https://github.com/login): Another commit
        CHANGES
      )
    end

    it "accepts a commit list limit" do
      formatter = Ouranos::Comparison::Linked.new(comparison, "org/repo")

      expect(formatter.changes(1)).to eq(
        <<-CHANGES.strip_heredoc.strip
          Total Commits: 1
          2 Additions, 4 Deletions, 6 Changes

          [sha](https://github.com/org/repo/commit/sha) by [login](https://github.com/login): Another commit
          [And 1 more commit...](https://github.com/org/repo/compare/sha...sha)
        CHANGES
      )
    end
  end
end
