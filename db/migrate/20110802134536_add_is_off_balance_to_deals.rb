# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class AddIsOffBalanceToDeals < ActiveRecord::Migration
  def self.up
    add_column :deals, :isOffBalance, :boolean, :default => false
  end

  def self.down
    remove_column :deals, :isOffBalance
  end
end
