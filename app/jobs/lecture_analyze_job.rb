class LectureAnalyzeJob < ApplicationJob
  queue_as :default

  def perform(lecture)
    LectureAnalyzerService.new(lecture).call
    lecture.reload

    Turbo::StreamsChannel.broadcast_replace_to(
      lecture,
      target: "lecture-resume-section",
      partial: "lectures/resume_section",
      locals: { lecture: lecture }
    )
  end
end
