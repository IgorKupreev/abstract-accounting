# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Warehouse
  attr_reader :place, :tag, :real_amount, :exp_amount, :mu

  def initialize(attrs)
    @place = attrs['place']
    @tag = attrs['tag']
    @real_amount = attrs['real_amount']
    @exp_amount = attrs['exp_amount']
    @mu = attrs['mu']
  end

  def self.all
    sql = "
      SELECT warehouse.* FROM (
        SELECT place, tag, SUM(real_amount) as real_amount,
               ROUND(SUM(real_amount - exp_amount), 2) as exp_amount, mu
        FROM (
          SELECT places.tag as place, assets.tag as tag,
                 states.amount as real_amount, 0.0 as exp_amount, assets.mu as mu
          FROM rules
            INNER JOIN waybills ON waybills.deal_id = rules.deal_id
            INNER JOIN states ON states.deal_id = rules.to_id
            INNER JOIN terms ON terms.deal_id = rules.to_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
            INNER JOIN places ON places.id = terms.place_id
          WHERE states.paid is NULL
          GROUP BY places.id, terms.resource_id
          UNION
          SELECT places.tag as place, assets.tag as tag, 0.0 as amount,
                 SUM(rules.rate) as exp_amount, assets.mu as mu
          FROM rules
            INNER JOIN distributions ON distributions.deal_id = rules.deal_id
            INNER JOIN states ON states.deal_id = rules.from_id
            INNER JOIN terms ON terms.deal_id = rules.from_id AND terms.side = 'f'
            INNER JOIN assets ON assets.id = terms.resource_id
            INNER JOIN places ON places.id = terms.place_id
          WHERE distributions.state = 1 AND states.paid is NULL
          GROUP BY places.id, terms.resource_id
        )
        GROUP BY place, tag, mu
      ) as warehouse
    WHERE warehouse.real_amount > 0.0 AND warehouse.exp_amount > 0.0"

    warehouse = []
    ActiveRecord::Base.connection.execute(sql).each { |entry|
      warehouse << Warehouse.new(entry)
    }
    warehouse
  end
end