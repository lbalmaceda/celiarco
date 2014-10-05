CeliARco
====================================

This project consist of several modules
* Ruby-Rails Heroku hosted service for updating every 2 month the valid gluten-free products from the ANMAT official PDF list file.
* Android application for consuming the Rails API and making request with UPC/EAN or RNPA codes to see if the current product is gluten-free.

Some facts about Gluteen Free food
------------------------------------
### RNPA 
Means "Registro Nacional de Producto Alimenticio". All food products in Argentina should have one printed in their package.

A valid code consist of:
* 7 Number Digits if the product comes from/goes to another country. Example code: '0580078' 
* 8 Number Digits if the product is from national source. Example code: '13040669'
* Exceptions: The RNPA can have 9 Number Digits if the 3rd one is a separator. Example code: '21-095949'

Invalid codes (Still working on how to parse them):
* Example code: 025/080000019-3-7/111
* Example code: 1734/87410/2
* Example code: 1734/8104300/1
* Example code: 19003153-4
* Example code: 55-21-095359
* Example code: 2200196913

All RNPA codes are cleaned before they are persisted to the DB. The current valid format is 8 Number Digits, which means that 7 digits codes are filled with a '0' on the left, and 9 digits codes have their separator removed. This is important to understand how the RNPA query for products works:
The numbers are compared from the left to the right, and the results are given in list of coincidences.


### UPC
Means "Universal Product Code". This is the classic barcode included in the product package. I've found that not all products have one, so the unique ID for now on is the RNPA.

In the near future, I plan to make the Android App find products by UPC first, and if the product isn't found on the DB ask the user to enter the RNPA. If now there is a result, and the user confirm it's actually the product he is asking for, post to the server the UPC code so in the end, every product has it UPC and RNPA.



#### Useful links
* Sqlite3 and JRuby are not compatible (JRuby can't run native extensions). For this to work, we need a custom adapter.
http://jrubyist.wordpress.com/2009/07/15/jruby-and-sqlite3-living-together/
