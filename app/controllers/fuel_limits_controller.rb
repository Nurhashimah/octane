class FuelLimitsController < ApplicationController
  before_action :set_fuel_limit, only: [:show, :edit, :update, :destroy]

  # GET /fuel_limits
  # GET /fuel_limits.json
  def index
    @fuel_limits = FuelLimit.all
  end

  # GET /fuel_limits/1
  # GET /fuel_limits/1.json
  def show
  end

  # GET /fuel_limits/new
  def new
    @fuel_limit = FuelLimit.new
  end

  # GET /fuel_limits/1/edit
  def edit
  end

  # POST /fuel_limits
  # POST /fuel_limits.json
  def create
    @fuel_limit = FuelLimit.new(fuel_limit_params)

    respond_to do |format|
      if @fuel_limit.save
        format.html { redirect_to @fuel_limit, notice: 'Fuel limit was successfully created.' }
        format.json { render :show, status: :created, location: @fuel_limit }
      else
        format.html { render :new }
        format.json { render json: @fuel_limit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fuel_limits/1
  # PATCH/PUT /fuel_limits/1.json
  def update
    respond_to do |format|
      if @fuel_limit.update(fuel_limit_params)
        format.html { redirect_to @fuel_limit, notice: 'Fuel limit was successfully updated.' }
        format.json { render :show, status: :ok, location: @fuel_limit }
      else
        format.html { render :edit }
        format.json { render json: @fuel_limit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fuel_limits/1
  # DELETE /fuel_limits/1.json
  def destroy
    @fuel_limit.destroy
    respond_to do |format|
      format.html { redirect_to fuel_limits_url, notice: 'Fuel limit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fuel_limit
      @fuel_limit = FuelLimit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fuel_limit_params
      params.require(:fuel_limit).permit(:code, :unit_id, :limit_amount, :limit_unit_type_id, :duration, :fuel_type_id, :fuel_unit_type_id, :emails, :data)
    end
end