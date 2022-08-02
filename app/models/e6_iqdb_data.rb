# frozen_string_literal: true

class E6IqdbData < ApplicationRecord
  belongs_to :submission_file

  def direct_url
    post_json["file"]["url"]
  end

  def score
    post_json["score"]["total"]
  end

  def deleted?
    post_json["flags"]["deleted"]
  end
end
