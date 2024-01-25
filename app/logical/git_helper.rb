# frozen_string_literal: true

module GitHelper
  CommitData = Struct.new(:timestamp, :commit_hash)
  COMMIT_ABREV_LENGTH = 7
  class << self
    delegate :timestamp, :commit_hash, to: :latest_commit
  end

  def self.enabled?
    latest_commit.present?
  end

  def self.latest_commit
    @latest_commit ||= begin
      data = JSON.parse(`git log -1 --format='{ "timestamp": %at, "commit_hash": "%h" }' --abbrev=#{COMMIT_ABREV_LENGTH}`)
      CommitData.new(**data)
    rescue JSON::ParserError
      {}
    end
  end

  def self.url
    return @url if instance_variable_defined? :@url

    regex = %r{git@(\S*):(\S*)/(\S*)\.git|://(\S*)(\.git)?}
    remote = `git config --get remote.origin.url`.strip
    match = remote.scan(regex).first
    @url = if match[0]
             "https://#{match[0]}/#{match[1]}/#{match[2]}"
           else
             "https://#{match[4]}"
           end
  end
end
