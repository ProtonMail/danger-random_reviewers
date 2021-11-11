# frozen_string_literal: true

module Danger
  # Assign MR to random reviewers until we it meets the approvals needed count.
  #
  # @example Assign the MR to either the user 'jmartin' or 'vbrison'.
  #       random_reviewers.assign(['jmartin', 'vbrison'])
  #
  # @see  ProtonMail/danger-random_reviewers
  # @tags merge_request, reviewer
  #
  class DangerRandomReviewers < Plugin
    # Auto assign reviewer(s) to the current merge request based on:
    # - Match assigned reviewers number to and required approvals number
    # - Filter out non active eligible reviewers (based on their GitLab status)
    # - Filter out from eligible reviewers reviewers provided in parameter reviewer_username_filter
    #
    # @param reviewer_username_filter Additional reviewer(s) to filter out from eligible reviewer.
    def assign(reviewer_username_filter = [])
      current_reviewers = gitlab.mr_json["reviewers"]
      project_id = gitlab.mr_json["project_id"]
      mr_id = gitlab.mr_json["iid"]
      merge_request_approvals = gitlab.api.merge_request_approvals(project_id, mr_id)
      approvals_required = merge_request_approvals["approvals_required"]
      reviewers_to_add_count = approvals_required - current_reviewers.length

      if reviewers_to_add_count <= 0
        p "No need to assign additional reviewer"
        return
      end

      # Get all eligible reviewers
      eligible_reviewers = merge_request_approvals["approvers"].map { |approver| approver["user"] }

      # Filter out MR author
      eligible_reviewers = eligible_reviewers.reject { |eligible_reviewer| eligible_reviewer["id"] == gitlab.mr_json["author"]["id"] }

      # Filter out non active user
      eligible_reviewers = eligible_reviewers.reject { |eligible_reviewer| eligible_reviewer["state"] != "active" }

      # Filter out current reviewers
      eligible_reviewers = eligible_reviewers.reject { |eligible_reviewer|
        current_reviewers.any? { |current_reviewer|
          current_reviewer["id"] == eligible_reviewer["id"]
        }
      }

      # Filter reviewer by username if filter non empty
      if !reviewer_username_filter.empty?
        p "reviewer filter not empty, filtering eligible reviewers"
        eligible_reviewers = eligible_reviewers.reject { |eligible_reviewer|
          reviewer_username_filter.none? { |reviewer_username_to_keep|
            eligible_reviewer["username"] == reviewer_username_to_keep
          }
        }
      end

      # Random pick reviewers to add
      if reviewers_to_add_count > eligible_reviewers.count
        warn("Not enough eligible reviewers (#{eligible_reviewers.count}) to add (#{reviewers_to_add_count}) to match required approvals (#{approvals_required})")
      end
      reviewers_to_add = eligible_reviewers.sample(reviewers_to_add_count)
      target_reviewer_ids = current_reviewers.map { |reviewer| reviewer["id"] } + reviewers_to_add.map { |reviewer| reviewer["id"] }

      # Updating MR reviewers
      gitlab.api.update_merge_request(project_id, mr_id, { reviewer_ids: target_reviewer_ids })

      # Posting on MR
      if !reviewers_to_add.empty?
        reviewers_to_add_link = reviewers_to_add.map { |reviewer| "@#{reviewer.to_hash["username"]}"  }
        message("Assigned randomly for review #{reviewers_to_add_link.join(", ")}")
      end
    end
  end

end
