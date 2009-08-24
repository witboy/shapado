class Question
  include MongoMapper::Document
  include MongoMapper::Search

  ensure_index :slug
  ensure_index :tags
  ensure_index :language

  key :title, String, :required => true
  key :body, String, :required => true
  key :slug, String, :required => true
  key :answers_count, Integer, :default => 0, :required => true
  key :views_count, Integer, :default => 0

  key :answered, Boolean, :default => false
  key :language, String, :default => "en"

  key :tags, Array, :default => []
  key :category, String

  key :user_id, String
  belongs_to :user
  has_many :answers, :dependent => :destroy

  validates_presence_of :user_id

  searchable_keys :title, :body

  before_validation_on_create :sluggize, :update_language
  before_validation_on_update :update_answer_count

  timestamps!

  def to_param
    self.slug || self.id
  end

  def self.find_by_slug_or_id(id)
    self.find_by_slug(id) || self.find_by_id(id)
  end

  def tags=(t)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self[:tags] = t
  end

  def self.tag_cloud
    @tag_cloud ||= begin
      path = RAILS_ROOT + "/app/javascripts/tag_cloud.js"
      self.database.eval(File.read(path))
    end
  end

  def viewed!
    self.collection.repsert({:_id => self.id}, {:$inc => {:views_count => 1}})
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  protected
  def sluggize
    if self.slug.blank?
      self.slug = self.title.gsub(/[^A-Za-z0-9\s\-]/, "")[0,40].strip.gsub(/\s+/, "-")
    end
  end

  def update_answer_count
    self.answers_count = self.answers.count
  end

  def update_language
    self.language = self.language.split("-").first
  end
end

