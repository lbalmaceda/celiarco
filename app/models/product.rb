class Product < ActiveRecord::Base
    validates :name, :description, :rnpa, presence: true
    validates :rnpa, uniqueness: true
    attr_accessible :barcode, :cause, :description, :down_date, :name, :rnpa, :gluten_free

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
            p.update_attribute(:name, args[:name]) if args[:name] 
            p.update_attribute(:description, args[:description]) if args[:description] 
            p.update_attribute(:barcode, args[:barcode]) if args[:barcode] 
            p.update_attribute(:cause, args[:cause]) if args[:cause] 
            p.update_attribute(:down_date, args[:down_date]) if args[:down_date] 
            p.update_attribute(:gluten_free, args[:gluten_free])
            print "."
            return true;
        else
            return Product.create(args)
        end
    end

end
