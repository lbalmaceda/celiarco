require 'tabula' 		#https://github.com/tabulapdf/tabula 
						#https://github.com/tabulapdf/tabula-extractor
require 'pdf-reader'	#https://github.com/yob/pdf-reader/
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
end


class CeliarcoExtractor

	pdfFile = 'listado.pdf'
	csvFile = 'resultado.csv'

	HEADER_NEW_PRODUCTS = 'NUEVAS INCORPORACIONES'
	HEADER_NEW_DROPPED_PRODUCTS = 'NUEVAS BAJAS'
	HEADER_DROPPED_PRODUCTS = 'BAJAS PERMANENTES'
	HEADER_EVERY_TABLE = 'NPA' ## and row array size == 3 || size == 5
	HEADER_EVERY_SUBTABLE = 'volve'	## and row array size == 2
	CELL_NO_DATA = '--'

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

	##Remove empty cells like ("")
	def cleanCSV
		cleanedArray = Array.new
		CSV.foreach("pruebas.csv") do |row_array|
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

		CSV.foreach("cleaned.csv") do |row_array|
			row_string = row_array.join('')
			if (row_string.include? HEADER_NEW_PRODUCTS)
				#Reading new products
				currentTableType = TYPE_NAME_DESC_RNPA
				currentArray = arrayNewProducts
			elsif (row_string.include? HEADER_NEW_DROPPED_PRODUCTS)
				#Reading new dropped products
				currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
				currentArray = arrayNewDropped
			elsif (row_string.include? HEADER_DROPPED_PRODUCTS)
				#Reading perma dropped products
				currentTableType = TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE
				currentArray = arrayPermaDropped
			elsif ((row_string.include? CELL_NO_DATA) || (row_string.include? HEADER_EVERY_SUBTABLE) || (row_string.empty?))
				currentArray = nil 	#skip empty row
			elsif ((row_string.include? HEADER_EVERY_SUBTABLE) && (row_array.size == 2))
				currentArray = nil	#skip empty row
			elsif ((row_string.include? HEADER_EVERY_TABLE) && (row_array.size == 3 || row_array.size == 5))
				currentArray = nil	#skip empty row
			else
				#Reading a product row
				currentTableType = TYPE_NAME_DESC_RNPA
				currentArray = arrayProducts
			end

			if currentArray
				parseProduct(row_array, currentTableType, currentArray)
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
			desc = row[1].to_s.capitalize
			rnpa = validateRNPA(row[2].to_s)
			if (rnpa)
				array << Product.new(name, desc, rnpa)
			end
		elsif (type == TYPE_NAME_DESC_RNPA_DOWNDATE_CAUSE)
			name = row[0].to_s.capitalize
			desc = row[1].to_s.capitalize
			rnpa = validateRNPA(row[2].to_s)
			downdate = row[3].to_s
			cause = row[4].to_s.capitalize
			if (rnpa)
				array << DroppedProduct.new(name, desc, rnpa, downdate, cause)
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
			left = rnpa[0..2]
			right = rnpa [2..7]
			rnpa = left + "-" + right
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
				line = p.name + "," + p.description + "," + p.rnpa
				csv << line
				csv << "\n"
			end
		end
	end

end

celiarco = CeliarcoExtractor.new
p 'Empezando'
#celiarco.transformPDF
celiarco.cleanCSV
celiarco.parseCSV
p 'Finalizando'

#tabula --pages -3 listado.pdf -r -o output.csv
