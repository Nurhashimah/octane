class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy]
 
  # NOTE use of auto expiry cache+works with ransack search - http://hawkins.io/2011/05/advanced_caching_in_rails/
  caches_action :index, :cache_path => proc {|c|
      timestamp = Unit.maximum(:updated_at).to_i
      total_recs = Unit.count  #TO CATER - when record is destroyed
      timestamp2 = FuelTank.maximum(:updated_at).to_i
      total_recs2 = FuelTank.count
      string = timestamp.to_s + c.params.inspect+"_#{total_recs}/tank-#{timestamp2}_#{total_recs2}"
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  caches_action :show, :cache_path => proc {|c|
      timestamp = Unit.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  
  # GET /units
  # GET /units.json
  def index
    #depot vs unit
    @depot = params[:id]
    if @depot == 1 || @depot == '1'
      @search = Unit.search(params[:q])
      @units = @search.result.where("id IN(?)",FuelTank.pluck(:unit_id))
    else 
      @search = Unit.search(params[:q])
      @units = @search.result
    end 
  end

  # GET /units/1
  # GET /units/1.json
  def show
  end

  # GET /units/new
  def new
    @unit = Unit.new(:parent_id => params[:parent_id])
  end

  # GET /units/1/edit
  def edit
  end

  # POST /units
  # POST /units.json
  def create
    @unit = Unit.new(unit_params)

    respond_to do |format|
      if @unit.save
        format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
        format.json { render action: 'show', status: :created, location: @unit }
      else
        format.html { render action: 'new' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    respond_to do |format|
      if @unit.update(unit_params)
        if Unit.is_depot.pluck(:id).include?(@unit.id)
          unitkind=(t 'units.title2')
        else
          unitkind=(t 'units.title3')
        end
        format.html { redirect_to @unit, notice: unitkind+' was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    if Unit.is_depot.pluck(:id).include?(@unit.id)
      depot=1
    else
      depot=0
    end
    @unit.destroy
    respond_to do |format|
      if depot==1
        format.html { redirect_to units_url(:id => 1)}
      else
        format.html { redirect_to units_url }
      end
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = Unit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(:shortname, :name, :ancestry, :ancestry_depth, :parent_id, :code, :combo_code, :vessel_id)
    end
end
