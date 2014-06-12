class ParticipantAnalysis 

  # At a given code review, each participant may have had prior experience with the code
  # review's owner. Count those prior experiences and update reviews_with_owner 
  def populate_reviews_with_owner
    Participant.find_each do |participant|
      c = participant.code_review

      #find all the code reviews where the owner is owner and one of the reviewers is participant
      #and only include reviews that were done before this one
      reviews = CodeReview.joins(:participants)\
        .where("owner_id = ? AND created < ? AND dev_id = ? AND dev_id<>owner_id ", \
               c.owner_id, c.created, participant.dev_id)

      participant.update(reviews_with_owner: reviews.count)
    end
  end#method

  # At the given code review, each participant may or may not have had experience 
  def populate_security_experienced
    Participant.find_each do |participant|
      c = participant.code_review
      vuln_reviews = participant.developer.participants.joins(code_review: :cvenums)\
        .where('code_reviews.created < ?', c.created)  

      participant.update(security_experienced: vuln_reviews.any?)
    end
    
  end
end#class