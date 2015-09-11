authorization do

 role :administration do
   has_omnipotence
   has_permission_on :authorization_rules, :to => :read
 end
 
 role :data_entry do
   has_permission_on [:units, :vessels, :inden_cards, :fuel_types, :unit_types, :vessel_types, :vessel_categories], :to => :manage
   has_permission_on  :fuel_tanks, :to => :manage   
   
   #UNIT FUEL
   has_permission_on :unit_fuels, :to => [:read, :update, :delete] do 
     if_attribute :unit_id => is {user.staff.unit_id}
   end
   has_permission_on [:add_fuels, :external_issueds, :external_supplieds, :inden_usages], :to => [:read, :update, :delete] do
     if_attribute :unit_fuel_id => is_in {UnitFuel.where(unit_id: user.staff.unit_id).pluck(:id)}
   end
   
   #DEPOT FUEL
   has_permission_on :depot_fuels, :to => [:read, :update, :delete, :import_excel, :import] do 
     if_attribute :unit_id => is {user.staff.unit_id}
   end
   has_permission_on [:fuel_supplieds, :fuel_issueds, :fuel_balances], :to => [:read, :update, :delete] do
     if_attribute :depot_fuel_id =>  is_in {DepotFuel.where(unit_id: user.staff.unit_id).pluck(:id)}
   end
   has_permission_on :fuel_transactions, :to => [:read, :update, :delete] do
     if_attribute :fuel_tank_id =>  is_in {FuelTank.where(unit_id: user.staff.unit_id).pluck(:id)}
   end
   has_permission_on [:fuel_limits, :fuel_budgets], :to => [:read, :update, :delete] do
     if_attribute :unit_id => is {user.staff.unit_id}
   end
   
   includes :guest
 end
 
 #Unit Fuel - REPORT -  :fuel_type_usage_category, :unit_fuel_usage, :unit_fuel_list_usage, :annual_usage_report] do
 #Depot Fuel - REPORT - depot_monthly_usage 
 #fuel tank - REPORT -  :tank_capacity_chart, :tank_capacity_list
 #fuel budget - REPORT - :annual_budget, :budget_vs_usage, :budget_vs_usage_list
 
 role :guest do  
   has_permission_on [:units, :vessels, :inden_cards, :fuel_types, :unit_types, :vessel_types, :vessel_categories], :to => :read
   has_permission_on [:fuel_transactions, :fuel_limits], :to => :create #restrict new Transaction record in HEADER if data entry staff not from depot

   has_permission_on :fuel_tanks, :to => [:read, :tank_capacity_chart, :tank_capacity_list]
   has_permission_on :fuel_budgets, :to => [:create, :annual_budget, :budget_vs_usage, :budget_vs_usage_list]

   has_permission_on :unit_fuels, :to => [:create, :fuel_type_usage_category, :unit_fuel_usage, :unit_fuel_list_usage, :annual_usage_report]
   has_permission_on :depot_fuels, :to =>[:create, :depot_monthly_usage] #restrict new record in INDEX if data entry staff not from depot
   
   has_permission_on [:fuel_supplieds, :fuel_issueds, :fuel_balances], :to => :create #restricted in Depot Fuel-action_menu
   has_permission_on [:add_fuels, :external_issueds, :external_supplieds, :inden_usages], :to => :create
 end

end

privileges do
  # default privilege hierarchies to facilitate RESTful Rails apps
  privilege :manage, :includes => [:create, :read, :update, :delete]
  privilege :create, :includes => :new
  privilege :read, :includes => [:index, :show]
  privilege :update, :includes => :edit
  privilege :delete, :includes => :destroy
end
