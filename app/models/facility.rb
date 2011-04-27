class Facility < ActiveRecord::Base
  acts_as_mappable :default_units => :miles, :default_formula => :flat

  include ParserUtils

  MAX_GROUP_MEMBERSHIPS = 20 # Number of groups a Facility can be a member of

  has_many :normal_openings,  :dependent => :delete_all
  has_many :holiday_openings,  :dependent => :delete_all
  has_many :facility_revisions
  belongs_to :user
  belongs_to :holiday_set

  has_many :group_memberships, :dependent => :destroy
  has_many :groups, :through => :group_memberships
  attr_accessible :name, :location, :description, :lat, :lng, :address, :postcode, :phone, :url, :holiday_set_id, :normal_openings_attributes, :holiday_openings_attributes, :comment, :retired, :groups_list

  named_scope :active, :conditions => { :retired_at => nil }

  accepts_nested_attributes_for :normal_openings, :allow_destroy => true, :reject_if => proc { |attrs| attrs['opens_at'].blank? && attrs['closes_at'].blank? && attrs['comment'].blank? }
  accepts_nested_attributes_for :holiday_openings, :allow_destroy => true, :reject_if => proc { |attrs| (attrs['closed'] == "0" || attrs['closed'].blank?) && attrs['opens_at'].blank? && attrs['closes_at'].blank? && attrs['comment'].blank? }

  def before_validation
    self.slug = full_name.slugify

    need_tidy = %w(name location description address phone url)
    need_tidy.each do |x|
      self.attributes[x] = self.attributes[x].tidy_text if attributes[x]
    end
    self.postcode.upcase! if postcode
    self.address.gsub!(/\s*,?\s*[\n\r]{1,2}/,", ") if address # turn line breaks in to comma separated address
  end

  validates_presence_of :name, :location, :slug, :address, :revision, :updated_from_ip, :holiday_set_id
  validates_format_of :postcode, :with => POSTCODE_REGX

  validates_presence_of :comment, :if => :retired?, :message => "must be provided if facility is marked for removal"

  validates_numericality_of :lat, :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90
  validates_numericality_of :lng, :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180

  def validate
    dupe = Facility.find_by_slug(slug)
    errors.add(:location, " - a business with this name and location already exists") if dupe && dupe != self

    errors.add_to_base("One or more normal opening times overlap") if overlapping_normal_opening_for_same_facility?
    errors.add_to_base("One or more bank holiday opening times overlap or you have a closed and non closed bank holiday opening") if overlapping_or_closed_holiday_opening_for_same_facility?
  end

  def before_save
    self.postcode = extract_postcode(postcode) # Uppercase, tidy spaces etc
    update_summary_normal_openings
    self.url = "http://" + url unless url.blank? || url =~ /\Ahttps?:\/\//
  end

  def before_create
    self.revision = 1
  end

  def before_update
    self.revision += 1
  end

  def overlapping_normal_opening_for_same_facility?
    normal_openings.each do |normal_opening|
      normal_openings.each do |c|
        next if normal_opening.object_id == c.object_id || normal_opening.marked_for_destruction? || c.marked_for_destruction?
        if normal_opening.same_wday?(c.wday) &&
          (normal_opening.within_mins?(c.opens_mins) || normal_opening.within_mins?(c.closes_mins))
          normal_opening.errors.add(:week_day, " - this opening overlaps with another on for the same day")
          return true
        end
      end
    end
    false
  end

  def overlapping_or_closed_holiday_opening_for_same_facility?
    holiday_openings.each do |holiday_opening|
      holiday_openings.each do |c|
        next if holiday_opening.object_id == c.object_id || holiday_opening.marked_for_destruction? || c.marked_for_destruction? || c.blank?
        if holiday_opening.closed? || holiday_opening.within_mins?(c.opens_mins) || holiday_opening.within_mins?(c.opens_mins)
          holiday_opening.errors.add(:opens_at, " - overlaps with another bank holiday opening")
          return true
        end
      end
    end
    false
  end

  def self.find_by_slug(slug)
    find(:first, :conditions => ["slug=?",slug.slugify])
  end

  def retired?
    !retired_at.nil?
  end

  def retired=(value)
    self.retired_at = (value.to_i == 1) ? Time.now : nil
  end

  def back_for_another_mission(reason)
    if retired?
      self.comment = reason
      self.retired_at = nil
    end
  end

  # Virtual attributes

  def full_name
    "#{name} - #{location}"
  end

  def full_address
    "#{address}, #{postcode}"
  end

  def updated_by
    user_id || updated_from_ip
  end

  def group_set_summary(group_set)
    tmp = group_set.first.week_day
    tmp += (group_set.size == 1 ? ': ' : "-#{group_set.last.week_day}: ")
    tmp += group_set.first.summary.gsub(' ','')
  end

  # Creates something like Mon-Sat: 9am-5pm, Sun: 10am-4pm
  def update_summary_normal_openings
    out = []
    group_set = []
    prev = nil
    normal_openings.each do |opening|
      if group_set.empty?
        group_set << opening
      else
        if prev.equal_mins?(opening)
          group_set << opening
        else
          out << group_set_summary(group_set)
          group_set = [opening]
        end
      end
      prev = opening
    end
    out << group_set_summary(group_set) unless group_set.empty?
    self.summary_normal_openings = out.join(', ')
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    unless options[:skip_instruct]
      xml.instruct!
      xml.comment!("Generated by http://opening-times.co.uk/")
    end
    xml.facility do
      xml.tag!(:id, id)
      xml.tag!(:slug, slug)
      xml.tag!(:name, name)
      xml.tag!(:location, location)
      xml.tag!(:address, address)
      xml.tag!(:postcode, postcode)
      xml.tag!(:phone, phone) unless phone.blank?
      xml.tag!(:url, url) unless url.blank?
      xml.tag!(:latitude, lat)
      xml.tag!(:longitude, lng)

      xml.tag!(:bank_holiday_set, holiday_set.name)

      xml.tag!(:created_at, created_at)
      xml.tag!(:updated_at, updated_at)

      normal_openings.to_xml(:builder=>xml,:skip_instruct=>true) unless normal_openings.empty?
      holiday_openings.to_xml(:builder=>xml,:skip_instruct=>true) unless holiday_openings.empty?
#      special_openings.to_xml(:builder=>xml,:skip_instruct=>true) unless special_openings.empty?

      groups.to_xml(:builder=>xml,:skip_instruct=>true, :only => 'name') unless groups.empty?
    end
  end


  def from_xml(xml)
    Facility.transaction do
      unless new_record?
        self.normal_openings.each do |o|
          o.mark_for_destruction
        end
        self.holiday_openings.each do |o|
          o.mark_for_destruction
        end
      end

      doc = Hpricot.XML(xml)

      s = (doc/"facility")
      s = (doc/"service") if s.empty?

      self.name = (s/"/name").text
      self.location = (s/"/location").text
      self.description = (s/"/description").text
      self.address = (s/"/address").text
      self.postcode = (s/"/postcode").text
      self.phone = extract_phone((s/"/phone").text)

      self.url = (s/"/url").text #TODO there needs to be a url extractor
      self.lat = (s/"/latitude").text.to_f #TODO this should do a geocode if they aren't specified
      self.lng = (s/"/longitude").text.to_f

      holiday_set = HolidaySet.find_by_name((s/"holiday_set").text)
      self.holiday_set = holiday_set || HolidaySet.find_by_postcode(postcode)

      (s/"normal-openings/opening").each do |opn|
        o = self.normal_openings.build
        o.from_xml(opn)
      end
      (s/"holiday-openings/opening").each do |opn|
        o = self.holiday_openings.build
        o.from_xml(opn)
      end

      self.group_memberships.delete_all
      (s/"groups/group").each do |group|
        group = Group.find_or_create_by_name(group['name'])
        self.group_memberships.build(:group => group)
      end
      self
    end
  end

  def groups_list
    groups.map(&:name).sort.join(", ")
  end

  def groups_list=(s)
    # see bug report - http://github.com/aubergene/Opening-Times/issues#issue/5
    self.group_memberships.each { |gm| gm.destroy }

    groups = s.split(",")
    groups.reject!(&:blank?)
    groups.map!(&:strip)
    groups.uniq!
    groups = groups[0,MAX_GROUP_MEMBERSHIPS]
    groups.each do |group|
      group = Group.find_or_create_by_name(group)
      self.group_memberships.build(:group => group)
    end
  end


end

