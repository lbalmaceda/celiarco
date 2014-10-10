class ProductsController < ApplicationController

  # GET /products
  # GET /products.json
  def index
    @products = Product.paginate(:page => params[:page], :per_page => 25)
    #@products = Product.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @products }
    end
  end
  
  # GET /products/1
  # GET /products/1.json
  def show
    @product = Product.find_by_rnpa(params[:rnpa])
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

  # PUT /products/1
  # PUT /products/1.json
  def update
    @product = Product.find(params[:id])

    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

end
