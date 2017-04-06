class FuelTank < ActiveRecord::Base
  before_save :set_default_maximum
  before_destroy :restrict_related_exist
  belongs_to :unit,   :class_name => "Unit",   :foreign_key => "unit_id"
  belongs_to :unittype,   :class_name => "UnitType",   :foreign_key => "unit_type"
  belongs_to :fuel_type,   :class_name => "FuelType",   :foreign_key => "fuel_type_id"
  has_many :fuel_balances, dependent: :destroy
  has_many :fuel_transactions
  
  validates_presence_of :unit_id, :locations, :capacity, :unit_type,:fuel_type_id
  
  scope :in_use, -> { where("capacity > ?", 0) }
  
  def self.of_depot(unitid)
    in_use.where(unit_id: unitid)
  end
  
  def set_default_maximum
    self.maximum=capacity*0.95
  end
  
  def fuel_tank_type
    "#{locations}"+" - #{fuel_type.name}"
  end
  
  def fuel_tank_details
    "#{unit.name}"+" | "+fuel_tank_type
  end
  
  def ddd
    [fuel_tank_details, id]
  end
	
  def self.get_tank(tank_name, depot_id, fuel_type_id)#, capacity)
    tankno = tank_name.split(" ")[tank_name.split(" ").count-1]
	#capacity = 20553
	#tankname = tank_name.split(" ")[0]
	#where('locations ILIKE (?)', "%kios%")[0].id
	#where('locations ILIKE (?)',"%#{tankname}%")[0].id
	#where('unit_id=? AND fuel_type_id=? AND capacity=?',depot_id, fuel_type_id, capacity)[0].id  
	#where('locations ILIKE (?) AND unit_id=? AND fuel_type_id=? AND capacity=?',"%#{tankno}",depot_id,fuel_type_id, capacity)[0].id
	where('locations ILIKE (?) AND unit_id=? AND fuel_type_id=?',"%#{tankno}",depot_id,fuel_type_id)[0].id
  end
  
  def self.get_tank2(tank_name, depot_id, fuel_type_id)#, capacity)
    tankno = tank_name.split("")[tank_name.split("").count-1]
    where('locations ILIKE (?) AND unit_id=? AND fuel_type_id=?',"%#{tankno}",depot_id,fuel_type_id)[0].id
    #where('locations ILIKE (?) AND unit_id=? AND fuel_type_id=? AND capacity=?',"%#{tankno}",depot_id,fuel_type_id, capacity)[0].id	
  end
  
  def self.groupped
    groupped_tank=[]
    groupped_tank2=[]
    all_tanks=[]
    FuelTank.all.where('capacity > 0').group_by{|x|x.fuel_type.shortname}.each do |fuelname, fuel_tanks|
      tanks_of_type=[]
      fuel_tanks.each do |tank|
        tanks_of_type << [tank.fuel_tank_details, tank.id]
        all_tanks << [tank.fuel_tank_details, tank.id]
      end
      groupped_tank << [fuelname, tanks_of_type]
    end
    groupped_tank << ['Not Defined', all_tanks]
    groupped_tank
  end
  
  #for use in select w OPTGROUP - in New/Edit depot_fuel -> select/upon selection of depot fuel -- fuel tank list is shortlisted according to selected depot.
  def self.by_depot
    arr=[]
    FuelTank.in_use.includes(:unit).includes(:fuel_type).order(:id).group_by(&:unit).each do |unit, x|
      y=[[(I18n.t 'helpers.prompt.select_fuel_tank')]]
      x.each{ |xx| y << [xx.fuel_tank_details, xx.id]}
      arr << [unit.name, y]
    end
    arr
  end
  
  def restrict_related_exist
    if unit.depot_fuels.count > 0
      return false
    else
      return true
    end
  end
  
end

# == Schema Information
#
# Table name: fuel_tanks
#
#  capacity     :decimal(, )
#  created_at   :datetime
#  fuel_type_id :integer
#  id           :integer          not null, primary key
#  locations    :string(255)
#  maximum      :decimal(, )
#  unit_id      :integer
#  unit_type    :integer
#  updated_at   :datetime
#
