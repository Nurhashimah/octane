class VesselsController < ApplicationController
  before_action :set_vessel, only: [:show, :edit, :update, :destroy]
  
  # NOTE use of auto expiry cache+works with ransack search - http://hawkins.io/2011/05/advanced_caching_in_rails/
  caches_action :index, :cache_path => proc {|c|
      timestamp = Vessel.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect+"_#{Vessel.count}"
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  caches_action :show, :cache_path => proc {|c|
      timestamp = Vessel.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect
      {:tag => Digest::SHA1.hexdigest(string)}
  }
    
  # GET /vessels
  # GET /vessels.json
  def index
    @search = Vessel.search(params[:q])
    @vessels = @search.result
  end

  # GET /vessels/1
  # GET /vessels/1.json
  def show
  end

  # GET /vessels/new
  def new
    @vessel = Vessel.new 
  end

  # GET /vessels/1/edit
  def edit
  end

  # POST /vessels
  # POST /vessels.json
  def create
    @vessel = Vessel.new(vessel_params)

    respond_to do |format|
      if @vessel.save
        format.html { redirect_to @vessel, notice: 'Vessel was successfully created.' }
        format.json { render action: 'show', status: :created, location: @vessel }
      else
        format.html { render action: 'new' }
        format.json { render json: @vessel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vessels/1
  # PATCH/PUT /vessels/1.json
  def update
    respond_to do |format|
      if @vessel.update(vessel_params)
        format.html { redirect_to @vessel, notice: 'Vessel was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @vessel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vessels/1
  # DELETE /vessels/1.json
  def destroy
    @vessel.destroy
    respond_to do |format|
      format.html { redirect_to vessels_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vessel
      @vessel = Vessel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vessel_params
      params.require(:vessel).permit(:pennent_no, :vessel_category_id, :unit_id)
    end
end
