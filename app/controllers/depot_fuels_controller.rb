class DepotFuelsController < ApplicationController
  #TODO - filter access to all actions - except 'depot_monthly_usage', [role-Admin & data entry(from Depot) can access everything in this module, while the rest (incl data entry(from Unit/dept-not depot tak boleh access apa2 pun EXCEPT repot page : 'depot_monthly_usage') 
  
  # 1) when use 'filter_resource_access' works well - tapi report 'depot_monthly_usage' keluar error :
  #-------
# ActiveRecord::RecordNotFound in DepotFuelsController#depot_monthly_usage
# Couldnt find DepotFuel with 'id'=
# Extracted source (around line #155):
# 
# record = s.execute([id], self, connection).first
# unless record
# raise RecordNotFound, "Couldn't find #{name} with '#{primary_key}'=#{id}"
# end
# record
# rescue RangeError
  #------

  # 2) When use 'filter_resource_access :additional_collection => { :depot_monthly_usage => :read } ' - OK BUT, semua action ok, tapi report 'depot monthly usage' pun filter sekali - 'Sorry, you are not allowed to access that page.', seems like additional_collection not functioning. found this --> https://github.com/stffn/declarative_authorization/issues/204 (title: "additional_collection" attribute does't work with Rails 4 by default) but have no idea how to make it works..
  
  ##filter_access_to :all, :except => :depot_monthly_usage
  #filter_resource_access :additional_collection => { :depot_monthly_usage => :read } 
  #before_action :set_depot_fuel, only: [:show, :edit, :update, :destroy]

  ### 13 September 2015
  
  #filter_access_to :all, :except => [:depot_monthly_usage]
  #filter_resource_access :except => :depot_monthly_usage
  #filter_access_to :index, :show, :edit, :update, :destroy, :import_excel
  #filter_resource_access
  #filter_resource_access :additional_member => { :import_excel => :create }
#   filter_resource_access :additional_member => {:depot_monthly_usage => :read}
#   before_action :set_depot_fuel, only: [:show, :edit, :update, :destroy]
  
  ###index je check
  before_filter :set_depot_fuel, :only => [:show, :edit, :update, :destroy]
  filter_access_to :index, :create, :import_excel, :attribute_check => false
  filter_access_to :show, :edit, :update, :destroy, :attribute_check => true
  
  # GET /depot_fuels
  # GET /depot_fuels.json
  def index
    is_admin=current_user.roles[:user_roles][:administration]
    if is_admin=="1" || current_user.staff_id
      @search = DepotFuel.search_by_role(is_admin, current_user.staff_id).search(params[:q])
      @depot_fuels = @search.result
    end
    respond_to do |format|
      if is_admin=="1" || current_user.staff_id
        format.html
      else
        format.html {redirect_to root_path, notice: (t 'users.staff_required')}
      end
    end
    #@search = DepotFuel.search(params[:q])
    #@depot_fuels = @search.result
  end

  # GET /depot_fuels/1
  # GET /depot_fuels/1.json
  def show
  end

  # GET /depot_fuels/new
  def new
    @depot_fuel = DepotFuel.new
  end

  # GET /depot_fuels/1/edit
  def edit
  end

  # POST /depot_fuels
  # POST /depot_fuels.json
  def create
    @depot_fuel = DepotFuel.new(depot_fuel_params)

    respond_to do |format|
      if @depot_fuel.save
        format.html { redirect_to @depot_fuel, notice:  (t 'depot_fuels.title')+(t 'actions.created') }
        format.json { render action: 'show', status: :created, location: @depot_fuel }
      else
        format.html { render action: 'new' }
        format.json { render json: @depot_fuel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /depot_fuels/1
  # PATCH/PUT /depot_fuels/1.json
  def update
    respond_to do |format|
      if @depot_fuel.update(depot_fuel_params)
        limit_diesel=FuelLimit.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'DIESEL').first.id).first
        limit_petrol=FuelLimit.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'PETROL').first.id).first
        limit_avtur=FuelLimit.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'AVTUR').first.id).first
        limit_avcat=FuelLimit.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'AVCAT').first.id).first
        budget_diesel=FuelBudget.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'DIESEL').first.id).first
        budget_petrol=FuelBudget.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'PETROL').first.id).first
        budget_avtur=FuelBudget.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'AVTUR').first.id).first
        budget_avcat=FuelBudget.where(unit_id: @depot_fuel.unit_id).where(fuel_type_id: FuelType.where(name: 'AVCAT').first.id).first
        surplus_diesel=@depot_fuel.surplus_diesel_amount
        surplus_petrol=@depot_fuel.surplus_petrol_amount
        surplus_avtur=@depot_fuel.surplus_avtur_amount
        surplus_avcat=@depot_fuel.surplus_avcat_amount
        if (limit_diesel && budget_diesel)&& (limit_petrol && budget_petrol) && (limit_avtur && budget_avtur) && (limit_avcat && budget_avcat)
          if  surplus_diesel > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails &&  surplus_avtur > 0 && limit_diesel.emails==limit_avtur.emails &&  surplus_avcat > 0 && limit_petrol.emails && limit_avcat.emails
            NotificationMailer.notify_email_combine(limit_diesel, limit_petrol, limit_avtur, limit_avcat, @depot_fuel).deliver_now 
          end
        elsif (limit_avcat && budget_avcat) && (limit_petrol && budget_petrol) && (limit_avtur && budget_avtur)
          if  surplus_avcat > 0 &&  surplus_petrol > 0 && limit_avcat.emails==limit_petrol.emails &&  surplus_avtur > 0 && limit_avcat.emails==limit_avtur.emails
            NotificationMailer.notify_email_combine(0, limit_petrol, limit_avtur, limit_avcat, @depot_fuel).deliver_now 
          end
        elsif (limit_diesel && budget_diesel)&& (limit_avcat && budget_avcat) && (limit_avtur && budget_avtur)
          if  surplus_diesel > 0 &&  surplus_avcat > 0 && limit_diesel.emails==limit_avcat.emails &&  surplus_avtur > 0 && limit_diesel.emails==limit_avtur.emails
            NotificationMailer.notify_email_combine(limit_diesel, 0, limit_avtur, @depot_fuel).deliver_now 
          end
        elsif (limit_diesel && budget_diesel)&& (limit_petrol && budget_petrol) && (limit_avcat && budget_avcat)
          if  surplus_diesel > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails &&  surplus_avcat > 0 && limit_diesel.emails==limit_avcat.emails
            NotificationMailer.notify_email_combine(limit_diesel, limit_petrol, 0, limit_avcat, @depot_fuel).deliver_now 
          end
        elsif (limit_diesel && budget_diesel)&& (limit_petrol && budget_petrol) && (limit_avtur && budget_avtur)
          if  surplus_diesel > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails &&  surplus_avtur > 0 && limit_diesel.emails==limit_avtur.emails
            NotificationMailer.notify_email_combine(limit_diesel, limit_petrol, limit_avtur, 0, @depot_fuel).deliver_now 
          end
        elsif (limit_diesel && budget_diesel)&& (limit_petrol && budget_petrol)
          if  surplus_diesel > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails
            NotificationMailer.notify_email_combine(limit_diesel, limit_petrol, 0, 0, @depot_fuel).deliver_now 
          end
        elsif (limit_diesel && budget_diesel)&& (limit_avtur && budget_avtur)
          if  surplus_diesel > 0 &&  surplus_avtur > 0 && limit_diesel.emails==limit_avtur.emails
            NotificationMailer.notify_email_combine(limit_diesel, 0, limit_avtur, 0, @depot_fuel).deliver_now 
          end
        elsif (limit_avtur && budget_avtur) && (limit_petrol && budget_petrol)
          if  surplus_avtur > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails
            NotificationMailer.notify_email_combine(0, limit_petrol, limit_avtur, 0, @depot_fuel).deliver_now 
          end
	elsif (limit_avcat && budget_avcat)&& (limit_avtur && budget_avtur)
          if  surplus_avcat > 0 &&  surplus_avtur > 0 && limit_diesel.emails==limit_petrol.emails
            NotificationMailer.notify_email_combine(0, limit_petrol, limit_avtur, 0, @depot_fuel).deliver_now 
          end  
	elsif (limit_avcat && budget_avcat) && (limit_petrol && budget_petrol)
          if  surplus_avcat > 0 &&  surplus_petrol > 0 && limit_diesel.emails==limit_petrol.emails
            NotificationMailer.notify_email_combine(0, limit_petrol, limit_avtur, 0, @depot_fuel).deliver_now 
          end
	elsif (limit_avcat && budget_avcat)&& limit_diesel
          if  surplus_avcat > 0 &&  surplus_diesel > 0 && limit_diesel.emails==limit_petrol.emails
            NotificationMailer.notify_email_combine(0, limit_petrol, limit_avtur, 0, @depot_fuel).deliver_now 
          end
        else
          if (limit_diesel && budget_diesel)&&  surplus_diesel > 0 
            NotificationMailer.notify_email(limit_diesel, @depot_fuel).deliver_now
          end
          if (limit_petrol && budget_petrol) &&  surplus_petrol > 0 
            NotificationMailer.notify_email(limit_petrol, @depot_fuel).deliver_now
          end
	  if (limit_avtur && budget_avtur) &&  surplus_avtur > 0 
            NotificationMailer.notify_email(limit_avtur, @depot_fuel).deliver_now
          end
          if (limit_avcat && budget_avcat) &&  surplus_avcat > 0 
            NotificationMailer.notify_email(limit_avcat, @depot_fuel).deliver_now
          end
        end
        format.html { redirect_to @depot_fuel, notice:  (t 'depot_fuels.title')+(t 'actions.updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @depot_fuel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /depot_fuels/1
  # DELETE /depot_fuels/1.json
  def destroy
    @depot_fuel.destroy
    respond_to do |format|
      format.html { redirect_to depot_fuels_url }
      format.json { head :no_content }
    end
  end
  
  def depot_monthly_usage 
    @depot_fuels=DepotFuel.all
    if params[:search].present? && params[:search][:start_date].present?
      @start_from = Date.parse((params[:search][:start_date])).beginning_of_day.strftime('%Y-%m-%d')
    else
      @start_from = (Date.today.beginning_of_month).strftime('%Y-%m-%d')
    end
    if params[:search].present? && params[:search][:end_date].present?
      @end_on = Date.parse(params[:search][:end_date]).end_of_day.strftime('%Y-%m-%d')
    else
      @end_on = (Date.today.end_of_day).strftime('%Y-%m-%d')
    end
    @monthly_usage =DepotFuel.where('issue_date >=? and issue_date <=?', @start_from, @end_on)
    @last_prev_depot_fuel = DepotFuel.where( "issue_date < ? ", @start_from).last
  end
  
  def import_excel
  end
  
  def import
    unless params[:file].nil?
	a=DepotFuel.import(params[:file]) 		#errorneous : "stc" " tn" " cap" " ftcm"
	if a == "stc"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')# "stc"
	elsif a == " tn"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.tn')#"tn"
	#elsif a == " cap"
	#	redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.cap')#"cap"
	elsif a == " ftcm"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.ftcm')#"ftcm"
	elsif a == "stc tn"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')+(t 'depot_fuels.tn')#"stc"+"tn"
	elsif a == "stc tn"# cap"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')+(t 'depot_fuels.tn')#+(t 'depot_fuels.cap')#"stc"+"tn"+"cap"
	elsif a == "stc tn ftcm"# cap ftcm"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')+(t 'depot_fuels.tn')+(t 'depot_fuels.ftcm')#+(t 'depot_fuels.cap') #"stc"+"tn"+"cap"+"ftcm"
	elsif a == "stc"# cap"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')#+(t 'depot_fuels.cap')# "stc"+"cap"
	elsif a == "stc ftcm"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')+(t 'depot_fuels.ftcm')#"stc"+"ftcm"
	elsif a == "stc ftcm"# cap ftcm"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.stc')+(t 'depot_fuels.ftcm')#+(t 'depot_fuels.cap') #"stc"+"cap"+"ftcm"
	elsif a == "tn"# cap"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.tn')#+(t 'depot_fuels.cap')# "tn"+"cap"
	elsif a == "tn ftcm"
		redirect_to import_excel_depot_fuel_url, notice: (t 'depot_fuels.failed')+(t 'depot_fuels.tn')+(t 'depot_fuels.ftcm')#"tn"+"ftcm"
	elsif a == "ftcm"#"cap ftcm"
		redirect_to import_excel_depot_fuel_url, notice:  (t 'depot_fuels.failed')+(t 'depot_fuels.ftcm')#+(t 'depot_fuels.cap')#"cap"+"ftcm"
	elsif a == "depot_not_exist"
		redirect_to import_excel_depot_fuel_url, notice:  (t 'depot_fuels.failed')+(t 'depot_fuels.depot_not_exist')
	else
		redirect_to depot_fuels_url, notice:(t 'depot_fuels.imported')
	end 
    else
      redirect_to import_excel_depot_fuel_url, notice: "Please select an Excel file for import."
    end
  end
  
  def download_excel_format
    send_file ("#{::Rails.root.to_s}/public/excel_format/DepotFuel_Excel.xls")
  end 
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_depot_fuel
      @depot_fuel = DepotFuel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def depot_fuel_params
      params.require(:depot_fuel).permit(:unit_id, :issue_date, fuel_issueds_attributes: [:id, :depot_fuel_id, :fuel_type_id, :quantity, :unit_type_id, :unit_id, :_destroy], fuel_supplieds_attributes: [:id, :depot_fuel_id, :fuel_type_id, :quantity, :unit_type_id,:_destroy], fuel_balances_attributes: [:id, :depot_fuel_id, :fuel_tank_id, :current, :unit_type_id,:_destroy])
    end
end
