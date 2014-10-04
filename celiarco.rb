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

    PDF_FILE = 'listado.pdf'
    CSV_FILE = 'listado.csv'

    HEADER_NEW_PRODUCTS = /(NUEVAS INCORPORACIONES)/i
    HEADER_NEW_DROPPED_PRODUCTS = /(NUEVAS BAJAS)/i
    HEADER_DROPPED_PRODUCTS = /(BAJAS PERMANENTES)/i
    HEADER_PRODUCT_TABLE = /(NPA)/i ## and row array size == 3 || size == 5
    HEADER_RETURN = /(volve)/i ## and row array size == 2
    CELL_NO_DATA = /(--)/

    TYPE_NAME_DESC_RNPA = 0
    TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE = 1

    @countInvalidRNPA
    @countMergedProducts

    def initialize
        @countInvalidRNPA = 0
        @countMergedProducts = 0
    end

    #Shell command method. Currently working as expected
    def transformPDFShell
        #Get pdf size
        reader = PDF::Reader.new(PDF_FILE)
        lastPage = reader.page_count - 1
        #Call shell command and hold until completes
        `tabula -p 3-#{lastPage} #{PDF_FILE} -r -o #{CSV_FILE}`
    end

    #Gem method. Results are not the same that the shell method # UNUSED
    def transformPDFGem
        #Get pdf size
        reader = PDF::Reader.new(PDF_FILE)
        lastPage = reader.page_count - 1

        out = open("output.csv", 'w')

        extractor = Tabula::Extraction::ObjectExtractor.new(PDF_FILE, [3]) #3..lastPage)
        extractor.extract.each do |pdf_page|
          pdf_page.spreadsheets.each do |spreadsheet|
            row_text = Array.new
            spreadsheet.cells.each do |cell|
                cell.text_elements = pdf_page.get_cell_text(cell)
                cell.options = ({:use_line_returns => false, :cell_debug => 0})
                row_text.push(cell.text.chomp)
            end
            out << row_text.to_csv
            out << "\n"
          end
        end
        extractor.close!
        out.close
    end

    ##Remove empty cells like ("") - UNUSED
    def cleanCSV
        cleanedArray = Array.new
        CSV.foreach(CSV_FILE) do |row_array|
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

        isValidMerge = false
        countHeaderRows = 0
        
        currentRowIndex = 0

        CSV.foreach(CSV_FILE) do |row_array|
            skipRow = true
            row_string = row_array.join(' ')     #This changes the result in a small amount. wwwwwhat?
            if (row_string =~ HEADER_NEW_PRODUCTS)
                #Reading new products
                #puts "Header NUEVOS PRODUCTOS detected"
                currentTableType = TYPE_NAME_DESC_RNPA
                currentArray = arrayNewProducts
            elsif (row_string =~ HEADER_NEW_DROPPED_PRODUCTS)
                #Reading new dropped products
                #puts "Header NUEVAS BAJAS detected"
                currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
                currentArray = arrayNewDropped
            elsif (row_string =~ HEADER_DROPPED_PRODUCTS)
                #Reading perma dropped products
                #puts "Header BAJAS PERMANENTES detected"
                currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
                currentArray = arrayPermaDropped
            elsif ((row_string =~ HEADER_RETURN) && (row_array.size >= 8)) #2 array size limitation, is needed?
                #puts "Header PRODUCTOS detected"
                currentTableType = TYPE_NAME_DESC_RNPA
                currentArray = arrayProducts
            elsif ((row_string =~ CELL_NO_DATA) || (row_string.empty?))
                #skip empty row
            elsif ((row_string =~ HEADER_PRODUCT_TABLE) && (row_array.size >= 8)) #3-5  array size limitation, is needed?
                #skip empty row
            else
                skipRow = false
            end

            if currentArray
                if (skipRow)
                    countHeaderRows += 1
                    skipRow = false
                else
                    isValidMerge = parseProduct(row_array, currentTableType, currentArray, isValidMerge)
                end
            end

            currentRowIndex += 1
          # do something with the parse result...
        end

        #Persist the arrays in files
        csvFromArray(arrayNewDropped, "final_new_dropped.csv") unless arrayNewDropped.empty?
        csvFromArray(arrayPermaDropped, "final_perma_dropped.csv") unless arrayPermaDropped.empty?
        csvFromArray(arrayNewProducts, "final_new_products.csv") unless arrayNewProducts.empty?
        csvFromArray(arrayProducts, "final_products.csv") unless arrayProducts.empty?

        puts "============================================================"
        puts "Filas ignoradas (Encabezados, Espacios en blanco): #{countHeaderRows}"
        puts "Productos aptos nuevos: #{arrayNewProducts.size}"
        puts "Productos aptos totales (anteriores + nuevos): #{arrayProducts.size}"
        puts "Bajas nuevas: #{arrayNewDropped.size}"
        puts "Bajas permanentes: #{arrayPermaDropped.size}"
        puts "Productos que se unieron: #{@countMergedProducts}"
        puts "Codigos RNPA invalidos: #{@countInvalidRNPA}"
        puts "============================================================"
        puts "Total de filas analizadas: #{countHeaderRows + arrayNewProducts.size + arrayProducts.size + arrayNewDropped.size + arrayPermaDropped.size + @countInvalidRNPA + @countMergedProducts}"
        puts "============================================================"
    end


    #Returns whether the next call to this method can be considered a merge of the product
    def parseProduct(row, type, array, isValidMerge)
        if (type == TYPE_NAME_DESC_RNPA)
            name = row[0].to_s.split.map(&:capitalize).join(' ')
            if (name.empty?)
                name = row[1].to_s.split.map(&:capitalize).join(' ')
            end
            desc = row[2].to_s #1
            if (desc.empty?)
                desc = row[3].to_s
            end
            if (desc.empty?)
                desc = row[4].to_s
            end
            desc.capitalize unless desc.upcase #1
            rnpa = validateRNPA(row[6].to_s)
            if (!rnpa || rnpa.empty?)
                rnpa = validateRNPA(row[9].to_s) #2
            end
            if (!rnpa || rnpa.empty?)
                rnpa = validateRNPA(row[10].to_s)
            end
            if (rnpa)
                #Listado.csv linea 443 > producto correcto agregado al array y puesto como "ultimo producto" 
                #Listado.csv lineas 444-451 productos con datos faltantes. Se deberia poner un flag para no considerar
                #a la linea 452 como la continuacion del producto 443
                if ((name.empty? || desc.empty? || rnpa.empty?) && isValidMerge && !array.empty?)
                    @countMergedProducts += 1
                    #puts "Continue previous product on row #{rowIndex}"
                    #Count+1 product merging for line counting purposes
                    #Continue previous product data
                    lastProduct = array.last
                    lastProduct.name = joinWithSpace(lastProduct.name, name) unless name.empty?
                    lastProduct.description = joinWithSpace(lastProduct.description, desc) unless desc.empty?
                    lastProduct.rnpa = joinWithSpace(lastProduct.rnpa, rnpa) unless rnpa.empty?
                    array[array.size-1] = lastProduct
                    return false
                elsif (!rnpa.empty?)
                    array << Product.new(name, desc, rnpa)
                    return true
                end
            else
                return false
            end
        elsif (type == TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE)
            name = row[0].to_s.split.map(&:capitalize).join(' ')
            desc = row[3].to_s #1
            desc.capitalize unless desc.upcase 
            rnpa = validateRNPA(row[6].to_s) #2
            downdate = row[9].to_s #3
            cause = row[13].to_s.capitalize #4
            if (cause.empty?)
                cause = row[15].to_s.capitalize
            end
            if (rnpa)
                if ((name.empty? || desc.empty? || rnpa.empty? || downdate.empty? || cause.empty?) && isValidMerge && !array.empty?)
                    @countMergedProducts += 1
                    #Continue previous product data
                    #puts "Continue previous product on row #{rowIndex}"
                    #Count+1 product merging for line counting purposes
                    lastProduct = array.last
                    lastProduct.name = joinWithSpace(lastProduct.name, name) unless name.empty?
                    lastProduct.description = joinWithSpace(lastProduct.description, desc) unless desc.empty?
                    lastProduct.rnpa = joinWithSpace(lastProduct.rnpa, rnpa) unless rnpa.empty?
                    lastProduct.downdate = joinWithSpace(lastProduct.downdate, downdate) unless downdate.empty?
                    lastProduct.cause = joinWithSpace(lastProduct.cause, cause.downcase) unless cause.empty?
                    array[array.size-1] = lastProduct
                    return false
                elsif (!rnpa.empty?)
                    array << DroppedProduct.new(name, desc, rnpa, downdate, cause)
                    return true
                end
            else
                return false
            end
        end
    end

    def validateRNPA(rnpa)
        return nil unless rnpa
        rnpa.lstrip!
        if (rnpa.size == 9 && rnpa.match(/[0-9]{2}[^0-9\\n][0-9]{6}/))
            #Remove separator: Ex Code >> 32-238593 
            left = rnpa[0..1]
            right = rnpa[3..8]
            rnpa = left + right
        elsif (rnpa.size == 10 && rnpa.match(/[0-9]{2}[^0-9\\n][0-9]{3}[^0-9\\n][0-9]{3}/))
            #Remove separator: Ex Code >> 32.238.593
            left = rnpa[0..1]
            middle = rnpa[3..5]
            right = rnpa[7..9]
            rnpa = left + middle + right
        elsif (rnpa.size == 8 && rnpa.match(/[0-9]{8}/))
            #valid!
        elsif (rnpa.size == 7 && rnpa.match(/[0-9]{7}/))
            #If RNPA has 7 chars, means is from other country import: Ex Code >> 0343235
            old = rnpa[0..6]
            rnpa = "0" + old
        elsif (rnpa.empty?)
            # empty rnpa can mean product continues from the previous page
        else
            #not valid rnpa
            @countInvalidRNPA += 1
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
#celiarco.transformPDFShell
celiarco.parseCSV
p 'Finalizando'

#tabula --pages -3 listado.pdf -r -o output.csv