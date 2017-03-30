class FuelSuppliedsController < ApplicationController
  filter_resource_access
  before_action :set_fuel_supplied, only: [:show, :edit, :update, :destroy]

  # NOTE use of auto expiry cache+works with ransack search - http://hawkins.io/2011/05/advanced_caching_in_rails/
  caches_action :index, :cache_path => proc {|c|
      timestamp = FuelSupplied.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect+"_#{FuelSupplied.count}"
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  caches_action :show, :cache_path => proc {|c|
      timestamp = FuelSupplied.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  
  # GET /fuel_supplieds
  # GET /fuel_supplieds.json
  def index
    # HACK - refer header - avoid Unit user, using direct url
    is_admin=current_user.roles[:user_roles][:administration]
    if is_admin=="1" || (current_user.staff.unit_id && Unit.is_depot.pluck(:id).include?(current_user.staff.unit_id))
      @search = FuelSupplied.search_by_role(is_admin, current_user.staff_id).search(params[:q])
      @fuel_supplieds = @search.result
    end
    respond_to do |format|
      if is_admin=="1" || (current_user.staff.unit_id && Unit.is_depot.pluck(:id).include?(current_user.staff.unit_id))
        format.html
      else
        format.html {redirect_to root_path, notice: (t 'fuel_supplieds.title3')+(t 'users.depot_staff_required')}
      end
    end
  end

  # GET /fuel_supplieds/1
  # GET /fuel_supplieds/1.json
  def show
  end

  # GET /fuel_supplieds/new
  def new
    @depot_fuel = DepotFuel.find(params[:depot_fuel_id])
    @fuel_supplied = @depot_fuel.fuel_supplieds.new(params[:fuel_supplied])
  end

  # GET /fuel_supplieds/1/edit
  def edit
  end

  # POST /fuel_supplieds
  # POST /fuel_supplieds.json
  def create
    @fuel_supplied = FuelSupplied.new(fuel_supplied_params)
    respond_to do |format|
      if @fuel_supplied.save
        format.html { redirect_to @fuel_supplied, notice: (t 'fuel_supplieds.title')+(t 'actions.created') }
        format.json { render action: 'show', status: :created, location: @fuel_supplied }
      else
        format.html { render action: 'new' }
        format.json { render json: @fuel_supplied.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fuel_supplieds/1
  # PATCH/PUT /fuel_supplieds/1.json
  def update
    respond_to do |format|
      if @fuel_supplied.update(fuel_supplied_params)
        format.html { redirect_to @fuel_supplied, notice: (t 'fuel_supplieds.title')+(t 'actions.updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @fuel_supplied.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fuel_supplieds/1
  # DELETE /fuel_supplieds/1.json
  def destroy
    @fuel_supplied.destroy
    respond_to do |format|
      format.html { redirect_to fuel_supplieds_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fuel_supplied
      @fuel_supplied = FuelSupplied.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fuel_supplied_params
      params.require(:fuel_supplied).permit(:depot_fuel_id, :fuel_type_id, :quantity, :unit_type_id)
    end
end
