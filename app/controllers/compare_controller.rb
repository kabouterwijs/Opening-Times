require 'diff-display'

class CompareController < ApplicationController

  COMPARE_TMP_DIR = "/tmp/opening-times/facility-revisions"

  def index
    v1_id = params[:a].to_i
    v2_id = params[:b].to_i

    # v1 = older version, v2 = newer version
    v1_id, v2_id = v2_id, v1_id if v1_id > v2_id && v2_id > 0

    @v1 = FacilityRevision.find(v1_id)
    if v2_id == 0
      v2_id = FacilityRevision.find(:first, :conditions => ["facility_id = ? AND id < ?", @v1.facility_id, @v1.id], :order => 'id DESC')
    end

    @v2 = FacilityRevision.find(v2_id)

    `mkdir -p #{COMPARE_TMP_DIR}`

    f1 = "#{COMPARE_TMP_DIR}/#{@v1.id}.xml"
    File.open(f1,"w") do |f|
      f << @v1.xml
    end

    f2 = "#{COMPARE_TMP_DIR}/#{@v2.id}.xml"
    File.open(f2,"w") do |f|
      f << @v2.xml
    end

    @diff = `git diff #{f1} #{f2}`
  end

end

