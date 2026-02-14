class LectureAnalyzeJob < ApplicationJob
  queue_as :default

  def perform(lecture)
    LectureAnalyzerService.new(lecture).call
  end
end
