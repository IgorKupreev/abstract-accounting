# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Txn < ActiveRecord::Base
  validates :value, :fact_id, :status, :presence => true
  validates_uniqueness_of :fact_id
  belongs_to :fact
  after_initialize :after_init
  before_save :before_save

  def from_balance
    self.fact.from.balance
  end

  private
  def after_init
    self.value ||= 0.0 if self.attributes.has_key?('value')
    self.status ||= 0 if self.attributes.has_key?('status')
    self.earnings ||= 0.0 if self.attributes.has_key?('earnings')
  end

  def before_save
    self.fact.from.update_by_txn(self)
  end
end
