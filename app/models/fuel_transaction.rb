class FuelTransaction < ActiveRecord::Base
  include FuelTransactionsHelper
  before_save :set_vehicle_nil_if_vessel
  belongs_to :fuel_unit_type, :class_name => "UnitType" , :foreign_key => "fuel_unit_type_id"
  belongs_to :fuel_type
  belongs_to :fuel_tank
  belongs_to :vehicle
  belongs_to :vessel
  validates_presence_of :amount
  validate :fuel_type_must_match, :usage_vehicle_or_vessel
  
  def set_vehicle_nil_if_vessel
    if is_vehicle==false
      self.vehicle_id=nil 
    elsif is_vehicle==true
      self.vessel_id=nil
    end
  end
  
  def self.by_type(transaction_type)
    where(transaction_type: transaction_type)
  end
  
  def fuel_type_must_match
    if fuel_type_id != fuel_tank.fuel_type_id
      errors.add(:fuel_type_id, " must match with fuel type of Fuel Tank")
    end
  end
  
  def usage_vehicle_or_vessel
    if transaction_type=="Usage"
      if !vehicle_id && !vessel_id
        errors.add("Vehicle Or Vessel", " at least 1 item must be selected")
      end
    end
  end
  
  scope :resupply, -> { where(transaction_type: "Resupply")} #for use in Tank Capacity List - current balance
  scope :usage, -> {where(transaction_type: "Usage")}
  
  def self.search_by_role(is_admin, staffid)
    if is_admin== "1"
      FuelTransaction.all 
    else
      curr_staff=Staff.find(staffid) 
      if curr_staff && curr_staff.unit_id
        if Unit.is_depot.pluck(:id).include?(curr_staff.unit_id)
          FuelTransaction.where(fuel_tank_id:  FuelTank.where(unit_id: curr_staff.unit_id).pluck(:id)) 
        elsif Vessel.pluck(:unit_id).include?(curr_staff.unit_id)
          FuelTransaction.where(vessel_id: Vessel.where(unit_id: curr_staff.unit_id).first.id)
        else
          vehicle_ids=VehicleAssignmentDetail.where(vehicle_assignment_id: VehicleAssignment.where(unit_id: curr_staff.unit_id).pluck(:id)).pluck(:vehicle_id)
          FuelTransaction.where(vehicle_id: vehicle_ids)
        end
      end
    end
  end

end
