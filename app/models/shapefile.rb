class Shapefile < ActiveRecord::Base
  has_many :regions, :inverse_of => :shapefile, :dependent => :destroy
  
  has_attached_file :data # zip file
  
  validates :kind, :presence => true, :uniqueness => true
  validates :name_field, :presence => true
  
  validates_attachment_presence :data
  validates_attachment_content_type :data, :content_type => "application/zip", :if => :attachment_present?
  validates_with ShapefileContentValidator, :if => :attachment_present?
  
  before_save  :set_default_update_flag
  after_create :enqueue_importer
  after_save   :update_other_region_defauls
    
  include Workflow
  workflow do
    state :unprocessed do
      event :import, :transitions_to => :importing
    end
    state :importing do
      event :complete, :transitions_to => :complete
      event :error, :transitions_to => :import_error
    end
    state :complete
    state :import_error
  end
  
  def error(message)
    update_attribute :job_error, message
  end
  
  def attachment
    data
  end
  
  private
  
  def attachment_present?
    data.present?
  end
  
  def enqueue_importer
    Delayed::Job.enqueue ShapefileJob.new(data.path, id)
  end
  
  private
  
  def set_default_update_flag
    @update_other_regions_default = true if changes[:default] && changes[:default].last
  end
  
  def update_other_region_defauls
    Shapefile.update_all( "\"default\" = false", "id <> #{id} AND \"default\" = true" ) if @update_other_regions_default
  end
end
