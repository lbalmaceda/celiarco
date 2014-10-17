class ProductsController < ApplicationController

  # GET /products
  # GET /products.json
  def index
    @products_valid_count = Product.where(:gluten_free => true).count
    @products_dropped_count = Product.where(:gluten_free => false).count
    last_product = Product.order("created_at").last;
    @products_last_update = last_product.created_at if last_product

    if (params[:search_rnpa])
      result = Product.search_by_rnpa(params[:search_rnpa])
      if result.count == 0
        @products = Product.paginate(:page => params[:page], :per_page => 25)
        flash.now[:error] = 'No products found with that RNPA'
        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: Array.new }
        end
      elsif result.count == 1
        @product = result.first
        respond_to do |format|
          format.html { redirect_to action: 'show', :token => params[:token], :rnpa => @product.rnpa } # show.html.erb
          format.json { render json:  Array.new.push(@product) }
        end
      else
        @products = result.paginate(:page => params[:page], :per_page => 25)
        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @products }
        end
      end
    else
      @products = Product.paginate(:page => params[:page], :per_page => 25)

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @products }
      end
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
    if (params[:rnpa])
      @product = Product.find_by_rnpa(params[:rnpa])
    elsif (params[:barcode])
      @product = Product.find_by_barcode(params[:barcode])
    end
    raise ActiveRecord::RecordNotFound if not @product

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @product }
    end
  end

  def create_or_update
    success = Product.create_or_update(params[:product])

    respond_to do |format|
      if success
        format.json { render :nothing => true, status: :created}
      else
        format.json { render :nothing => true, status: :unprocessable_entity }
      end
    end
  end


  # PUT /products/1
  # PUT /products/1.json
  def update_barcode
    @product = Product.find_by_rnpa(params[:rnpa])
    invalid_barcode = Product.find_by_barcode(params[:barcode])

    respond_to do |format|
      if !invalid_barcode && @product.update_attribute(:barcode, params[:barcode])
        flash.now[:notice] = 'Product was successfully updated.'
        format.html { render action: "show" }
        format.json { head :no_content }
      else
        format.html { render action: "show" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(params[:product])

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render json: @product, status: :created, location: @product }
      else
        format.html { render action: "new" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  

end
