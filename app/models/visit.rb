class Visit < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:url, :created_at]
    validates_format /\Ahttps?:\/\//, :url, message: 'is not a valid URL'
    validates_format /\Ahttps?:\/\//, :referer, message: 'is not a valid URL' if referer.present?
  end
end
