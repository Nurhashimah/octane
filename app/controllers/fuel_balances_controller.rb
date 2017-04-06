class FuelBalancesController < ApplicationController
  filter_resource_access
  before_action :set_fuel_balance, only: [:show, :edit, :update, :destroy]
  
  #caches_action :index, :show    #step 1 : https://www.sitepoint.com/caching-cache-digest/
  #use below (replacing step 1, 2a, 2b, 2bii & 2c) - for auto expiry caches & ransack search to works - http://hawkins.io/2011/05/advanced_caching_in_rails/
  caches_action :index, :cache_path => proc {|c|
      timestamp = FuelBalance.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect+"_#{FuelBalance.count}"+chkeys([Unit, FuelTank, DepotFuel])
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  
  caches_action :show, :cache_path => proc {|c|
      timestamp = FuelBalance.maximum(:updated_at).to_i
      string = timestamp.to_s + c.params.inspect+"_#{FuelBalance.count}"+chkeys([Unit, FuelTank, DepotFuel])
      {:tag => Digest::SHA1.hexdigest(string)}
  }
  
  # GET /fuel_balances
  # GET /fuel_balances.json
  def index
     @search = FuelBalance.order(:depot_fuel_id).search(params[:q])
     @fuel_balances = @search.result
  end

  # GET /fuel_balances/1
  # GET /fuel_balances/1.json
  def show
  end

  # GET /fuel_balances/new
  def new
    @depot_fuel = DepotFuel.find(params[:depot_fuel_id])
    @fuel_balance = @depot_fuel.fuel_balances.new(params[:fuel_balance])
  end

  # GET /fuel_balances/1/edit
  def edit
  end

  # POST /fuel_balances
  # POST /fuel_balances.json
  def create
    @fuel_balance = FuelBalance.new(fuel_balance_params)
    #expire_action :action => :index     #step 2a : https://www.sitepoint.com/caching-cache-digest/
    respond_to do |format|
      if @fuel_balance.save
        format.html { redirect_to @fuel_balance, notice: (t 'fuel_balances.title')+(t 'actions.created') }
        format.json { render action: 'show', status: :created, location: @fuel_balance }
      else
        format.html { render action: 'new' }
        format.json { render json: @fuel_balance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fuel_balances/1
  # PATCH/PUT /fuel_balances/1.json
  def update
    #expire_action :action => :index     #step 2b : https://www.sitepoint.com/caching-cache-digest/
    #expire_action :action => :show     #step 2bii : https://www.sitepoint.com/caching-cache-digest/
    respond_to do |format|
      if @fuel_balance.update(fuel_balance_params)
        format.html { redirect_to @fuel_balance, notice: (t 'fuel_balances.title')+(t 'actions.updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @fuel_balance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fuel_balances/1
  # DELETE /fuel_balances/1.json
  def destroy
    @fuel_balance.destroy
    #expire_action :action => :index     #step 2c : https://www.sitepoint.com/caching-cache-digest/
    respond_to do |format|
      format.html { redirect_to fuel_balances_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fuel_balance
      @fuel_balance = FuelBalance.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fuel_balance_params
      params.require(:fuel_balance).permit(:depot_fuel_id, :fuel_tank_id, :current, :unit_type_id)
    end
end
