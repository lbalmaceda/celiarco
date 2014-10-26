class Product < ActiveRecord::Base
    validates :name, :description, :rnpa, presence: true
    validates :rnpa, uniqueness: true
    attr_accessible :cause, :description, :down_date, :name, :rnpa, :gluten_free
    has_many :barcodes, :dependent => :destroy

    def toArray()
    	arr = Array.new
    	if (self.gluten_free)
	        arr << @name
	        arr << @description
	        arr << @rnpa
    	else
    		arr << @name
	        arr << @description
	        arr << @rnpa
	        arr << @downdate
	        arr << @cause
	    end
        return arr
    end

    def self.create_or_update(args)
        #parse date before use
        args[:down_date] = Date.strptime(args[:down_date], "%d/%m/%y") if args[:down_date]

        if (Product.exists?(:rnpa => args[:rnpa]))
            p = Product.find_by_rnpa(args[:rnpa])
            p.update_attributes(args)
            print "."
            return true;
        else
            return Product.create(args)
        end
    end

    def self.search_by_rnpa(search)
        if search
          if Rails.env == 'production'
            where('rnpa ILIKE ?', "%#{search}").order('created_at ASC')
          else
            where('rnpa LIKE ?', "%#{search}").order('created_at ASC')
          end
        end
    end

    def self.search_by_barcode(search)
        if search
            joins(:barcodes).where('barcodes.barcode == ?', search).order('barcodes.times DESC').first(10)
        end
    end

    def add_barcode(barcode)
        code = barcodes.where(:barcode => barcode).first
        if (code)
            code.times = code.times + 1
            code.save
            p 'barcode exists! add 1 time'
        else
            barcodes.create!(:barcode => barcode, :times => 1)
            p 'new barcode added!'
        end
    end

end
