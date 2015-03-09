require_relative '../verify_base.rb'

class ProductionVocsbVerify < VerifyBase
  def verify_no_auto_words
    assert_equal 0, TechnicalWord.where(word: 'rightli').count
  end
end