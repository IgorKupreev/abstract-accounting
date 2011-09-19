# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "state_action"

class Balance < ActiveRecord::Base
  include StateAction

  validates :amount, :value, :start, :side, :deal_id, :presence => true
  validates_inclusion_of :side, :in => [PASSIVE, ACTIVE]
  validates_uniqueness_of :start, :scope => :deal_id
  belongs_to :deal
  after_initialize :do_init
  scope :pendings, where("balances.paid IS NULL")

  def update_value(side, amount, value)
    if update_amount(side, amount)
      if side == PASSIVE && self.side == PASSIVE
        raise "Invalid debit" unless has_debit?
        self.value = (self.amount * self.deal.rate).accounting_norm
      elsif side == ACTIVE && self.side == ACTIVE
        if has_debit?
          self.value = self.amount.accounting_norm
        elsif !value.accounting_zero?
          self.value = value
        else
          raise "Unexpected behaviour"
        end
      elsif side == PASSIVE && self.side == ACTIVE
        raise "Invalid debit" unless has_debit?
        self.value = self.amount.accounting_norm
      else
        return false
      end
    end
    true
  end

  def accounting_value
    if Balance::ACTIVE == self.side && self.has_debit?
      return self.amount
    end
    self.value
  end

  protected
  def do_init
    self.side ||= ACTIVE if self.attributes.has_key?('side')
    self.amount ||= 0.0 if self.attributes.has_key?('amount')
    self.value ||= 0.0 if self.attributes.has_key?('value')
  end

  def has_debit?
    !Chart.first.nil? and self.deal.take == Chart.first.currency
  end
end