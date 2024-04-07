# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["MT_NO_EXPECTATIONS"] ||= "1"

require "simplecov"
module SimpleCov
  class SourceFile
    def coverage_exceeding_source_warn
      # no-op, https://github.com/simplecov-ruby/simplecov/issues/1057
    end
  end
end

SimpleCov.start "rails" do
  enable_coverage :branch
  enable_coverage_for_eval

  groups.delete "Channels"
  groups.delete "Mailers"
  groups.delete "Libraries"

  add_group "Sites", "app/logical/sites"
  add_group "Scraper", "app/logical/scraper"
  add_group "Views", "app/views"
  add_group "Logical" do |src_file|
    not_filtered_further = ["logical/sites", "logical/scraper"].none? { |e| src_file.filename.include? e }
    not_filtered_further && src_file.filename.include?("app/logical")
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "minitest-spec-rails"

require "factory_bot"
require "mocha/minitest"
require "webmock/minitest"
require "httpx/adapters/webmock"

$VERBOSE = true

FactoryBot.find_definitions
FactoryBot::SyntaxRunner.class_eval do
  include ActiveSupport::Testing::FileFixtures
  self.file_fixture_path = ActiveSupport::TestCase.file_fixture_path
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    setup do
      WebMock.enable!
      WebMock.disable_net_connect!
      Config.stubs(:custom_config).returns({})
      Config.stubs(:time_zone).returns("UTC")
      Rails.cache.clear
    end

    def stub_e6(post_id:, iqdb_matches: [], md5: "abc", &)
      iqdb_stub = stub_e6_iqdb_request([post_id] + iqdb_matches)
      post_stub = stub_e6_post_request(post_id, md5)
      yield
    ensure
      remove_request_stub(iqdb_stub) if iqdb_stub
      remove_request_stub(post_stub) if post_stub
    end

    def stub_iqdb(result)
      response = result.map { |sm, score| { post_id: sm.id, score: score } }.to_json
      stub = stub_request_once(:post, "#{DockerEnv.iqdb_url}/query", body: response, headers: { content_type: "application/json" })
      yield
    ensure
      remove_request_stub(stub) if stub
    end

    def stub_scraper_enabled(*site_types, &)
      sites = site_types.map { |site_type| Sites.from_enum(site_type.to_s) }
      sites.each.with_index do |site, index|
        raise ArgumentError, "#{site_types[index]} is not a valid scraper" unless site.scraper?

        site.stubs(:scraper_enabled?).returns(true)
      end
      yield
    ensure
      sites.each { |site| site.unstub(:scraper_enabled?) }
    end

    def stub_request_once(method, url_matcher, **)
      stub_request(method, url_matcher).to_return(**)
        .then.to_raise(ArgumentError.new("can only be stubbed once"))
    end

    private

    def stub_e6_iqdb_request(response_post_ids)
      response = build(:e6_iqdb_response, post_ids: response_post_ids).to_json
      stub_request_once(:post, "https://e621.net/iqdb_queries.json", body: response, headers: { content_type: "application/json" })
    end

    def stub_e6_post_request(post_id, md5)
      response = build(:e6_post_response, post_id: post_id, md5: md5).to_json
      stub_request_once(:get, "https://e621.net/posts/#{post_id}.json", body: response, headers: { content_type: "application/json" })
    end
  end
end
