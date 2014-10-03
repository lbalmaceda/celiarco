require 'tabula'        #https://github.com/tabulapdf/tabula 
                        #https://github.com/tabulapdf/tabula-extractor
require 'pdf-reader'    #https://github.com/yob/pdf-reader/
require 'csv'


class Product
    attr_accessor :name
    attr_accessor :description
    attr_accessor :rnpa
    attr_accessor :upc

    def initialize(name, description, rnpa)
        @name=name
        @description=description
        @rnpa=rnpa
    end

    def toArray()
        arr = Array.new
        arr << @name
        arr << @description
        arr << @rnpa
        return arr
    end
end

class DroppedProduct < Product
    attr_accessor :downdate
    attr_accessor :cause

    def initialize(name, description, rnpa, downdate, cause)
        @name=name
        @description=description
        @rnpa=rnpa
        @downdate=downdate
        @cause=cause
    end

    def toArray()
        arr = Array.new
        arr << @name
        arr << @description
        arr << @rnpa
        arr << @downdate
        arr << @cause
        return arr
    end
end


class CeliarcoExtractor

    pdfFile = 'listado.pdf'
    csvFile = 'resultado.csv'

    HEADER_NEW_PRODUCTS = /(NUEVAS INCORPORACIONES)/i
    HEADER_NEW_DROPPED_PRODUCTS = /(NUEVAS BAJAS)/i
    HEADER_DROPPED_PRODUCTS = /(BAJAS PERMANENTES)/i
    HEADER_PRODUCT_TABLE = /(NPA)/i ## and row array size == 3 || size == 5
    HEADER_RETURN = /(volve)/i ## and row array size == 2
    CELL_NO_DATA = /(--)/

    TYPE_NAME_DESC_RNPA = 0
    TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE = 1


    def transformPDF
        #Get pdf size
        reader = PDF::Reader.new(pdfFile)
        lastPage = reader.page_count - 1

        out = open(csvFile, 'w')

        extractor = Tabula::Extraction::ObjectExtractor.new(pdfFile, 3..lastPage)
        extractor.extract.each do |pdf_page|
          pdf_page.spreadsheets.each do |spreadsheet|
            out << spreadsheet.to_csv
            out << "\n\n"
          end
        end
        out.close
    end

    ##Remove empty cells like ("") - UNUSED
    def cleanCSV
        cleanedArray = Array.new
        CSV.foreach(csvFile) do |row_array|
            cleanRowArray = Array.new
            row_array.each do |cell|
                if (!cell.empty?)
                    cleanRowArray << cell
                end
            end
            cleanedArray << cleanRowArray
        end

        CSV.open("cleaned.csv", "w") do |csv|
            cleanedArray.each do |array|
                csv << array
            end
        end
    end


    def parseCSV
        currentTableType = 0
        arrayNewDropped = Array.new
        arrayPermaDropped = Array.new
        arrayNewProducts = Array.new
        arrayProducts = Array.new
        currentArray = nil

        CSV.foreach(csvFile) do |row_array|
            skipRow = false
            row_string = row_array.join('')
            if (row_string =~ HEADER_NEW_PRODUCTS)
                #Reading new products
                puts "Header NUEVOS PRODUCTOS detected"
                currentTableType = TYPE_NAME_DESC_RNPA
                currentArray = arrayNewProducts
            elsif (row_string =~ HEADER_NEW_DROPPED_PRODUCTS)
                #Reading new dropped products
                puts "Header NUEVAS BAJAS detected"
                currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
                currentArray = arrayNewDropped
            elsif (row_string =~ HEADER_DROPPED_PRODUCTS)
                #Reading perma dropped products
                puts "Header BAJAS PERMANENTES detected"
                currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
                currentArray = arrayPermaDropped
            elsif ((row_string =~ HEADER_RETURN) && (row_array.size >= 12)) #2
                puts "Header PRODUCTOS detected"
                currentTableType = TYPE_NAME_DESC_RNPA
                currentArray = arrayProducts
            elsif ((row_string =~ CELL_NO_DATA) || (row_string.empty?))
                #skip empty row
                skipRow = true
            elsif ((row_string =~ HEADER_PRODUCT_TABLE) && (row_array.size >= 12)) #3-5
                #skip empty row
                skipRow = true
            end

            if currentArray
                if (skipRow)
                    skipRow = false
                else
                    parseProduct(row_array, currentTableType, currentArray)
                end
            end

          # do something with the parse result...
        end

        #Persist the arrays in files
        csvFromArray(arrayNewDropped, "final_new_dropped.csv") unless arrayNewDropped.empty?
        csvFromArray(arrayPermaDropped, "final_perma_dropped.csv") unless arrayPermaDropped.empty?
        csvFromArray(arrayNewProducts, "final_new_products.csv") unless arrayNewProducts.empty?
        csvFromArray(arrayProducts, "final_products.csv") unless arrayProducts.empty?

    end


    def parseProduct(row, type, array)
        if (type == TYPE_NAME_DESC_RNPA)
            name = row[0].to_s.capitalize
            desc = row[3].to_s #1
            desc.capitalize unless desc.upcase #1
            rnpa = validateRNPA(row[10].to_s) #2
            if (!rnpa || rnpa.empty?)
                rnpa = validateRNPA(row[9].to_s)
            end
            if (rnpa)
                if ((name.empty? || desc.empty? || rnpa.empty?) && !array.empty?)
                    #Continue previous product data
                    lastProduct = array.last
                    lastProduct.name = joinWithSpace(lastProduct.name, name) unless name.empty?
                    lastProduct.description = joinWithSpace(lastProduct.description, desc) unless desc.empty?
                    lastProduct.rnpa = joinWithSpace(lastProduct.rnpa, rnpa) unless rnpa.empty?
                    array[array.size-1] = lastProduct
                elsif (!rnpa.empty?)
                    array << Product.new(name, desc, rnpa)
                end
            end
        elsif (type == TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE)
            name = row[0].to_s.capitalize #0
            desc = row[3].to_s #1
            desc.capitalize unless desc.upcase 
            rnpa = validateRNPA(row[6].to_s) #2
            downdate = row[9].to_s #3
            cause = row[13].to_s.capitalize #4
            if (rnpa || rnpa.empty?)
                if ((name.empty? || desc.empty? || rnpa.empty? || downdate.empty? || cause.empty?) && !array.empty?)
                    #Continue previous product data
                    lastProduct = array.last
                    lastProduct.name = joinWithSpace(lastProduct.name, name) unless name.empty?
                    lastProduct.description = joinWithSpace(lastProduct.description, desc) unless desc.empty?
                    lastProduct.rnpa = joinWithSpace(lastProduct.rnpa, rnpa) unless rnpa.empty?
                    lastProduct.downdate = joinWithSpace(lastProduct.downdate, downdate) unless downdate.empty?
                    lastProduct.cause = joinWithSpace(lastProduct.cause, cause.downcase) unless cause.empty?
                    array[array.size-1] = lastProduct
                elsif (!rnpa.empty?)
                    array << DroppedProduct.new(name, desc, rnpa, downdate, cause)
                end
            end
        end
    end

    def validateRNPA(rnpa)
        return nil unless rnpa
        rnpa.lstrip!
        if (rnpa.size == 9 && rnpa.match(/[0-9]{2}[^0-9\\n][0-9]{6}/))
            #replace 3er char with '-'
            rnpa[2] = "-"
        elsif (rnpa.size == 8 && rnpa.match(/[0-9]{8}/))
            left = rnpa[0..1]
            right = rnpa [2..7]
            rnpa = left + "-" + right
        elsif (rnpa.empty?)
            # empty rnpa means product continues from the previous page
        else
            #not valid rnpa
            out = open('invalid_rnpa.csv', 'a')
                out << rnpa
                out << "\n"
            out.close

            rnpa = nil
        end
        return rnpa
    end

    def csvFromArray(array, fileName)
        #puts array.to_s
        CSV.open(fileName, 'w') do |csv|
            array.each do |p|
                csv << p.toArray
            end
        end
    end

    def joinWithSpace(left, right)
        right[0] = right[0].downcase
        if (left[left.size-1] == ' ' && right[right.size-1] == ' ')
            left.shift
            return left.concat(right)
        elsif (left[left.size-1] == ' ' && right[right.size-1] != ' ')
            return left.concat(right)
        elsif (left[left.size-1] != ' ' && right[right.size-1] == ' ')
            return left.concat(right)
        elsif (left[left.size-1] != ' ' && right[right.size-1] != ' ') 
            return left.concat(' ').concat(right)
        end
    end

end

celiarco = CeliarcoExtractor.new
p 'Empezando'
celiarco.transformPDF
celiarco.parseCSV
p 'Finalizando'

#tabula --pages -3 listado.pdf -r -o output.csv
