class DataIntegrityTest
  def run_all
    puts "\nRunning data integrity tests.\n\n"
    @pass = 0
    @fail = 0
    DataIntegrityTest.public_instance_methods(false).each do |test|
      send(test) unless (test == :run_all)
    end
    puts "\nData integrity tests completed. #{@pass} test passed. #{@fail} tests failed.\n"
  end
  
  def test_code_reviews_and_cves_relationship
    error_count = CodeReview.where.not(cve: Cve.select("cve")).count
    print_results(__method__, error_count, "code_reviews", "cve")
  end
  
  def test_comments_and_patch_set_files_relationship
    error_count = Comment.where.not(patch_set_file_id: PatchSetFile.select("id")).count
    print_results(__method__, error_count, "comments", "patch_set_file_id")
  end
  
  def test_messages_and_code_reviews_relationship
    error_count = Message.where.not(code_review_id: CodeReview.select("id")).count
    print_results(__method__, error_count, "messages", "code_review_id")
  end
  
  def test_patch_set_files_and_patch_sets_relationship
    error_count = PatchSetFile.where.not(patch_set_id: PatchSet.select("id")).count
    print_results(__method__, error_count, "patch_set_files", "patch_set_id")
  end
  
  def test_patch_sets_and_code_reviews_relationship
    error_count = PatchSet.where.not(code_review_id: CodeReview.select("id")).count
    print_results(__method__, error_count, "patch_sets", "code_review_id")
  end
  
  private
  def print_results(test_name, error_count, table, foreign_column)
    if error_count == 0
      result = "PASS"
      @pass += 1
    else
      result = "FAIL: #{error_count.to_s} inconsistent #{foreign_column} in the #{table} table"
      @fail += 1
    end
    printf "  %-60s %s\n", test_name, result
  end
end