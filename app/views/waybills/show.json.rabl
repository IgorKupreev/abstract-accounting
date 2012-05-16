# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object true
child(@waybill => :waybill) do
  attributes :document_id,
             :distributor_id, :distributor_place_id,
             :storekeeper_id, :storekeeper_place_id
  node(:created) { |waybill| waybill.created.strftime("%m/%d/%Y") }
end
child(@waybill.distributor => :distributor) do
  attributes :name, :identifier_name, :identifier_value
end
child(@waybill.distributor_place => :distributor_place) { attributes :tag }
child(@waybill.storekeeper => :storekeeper) { attributes :tag }
child(@waybill.storekeeper_place => :storekeeper_place) { attributes :tag }
child(@waybill.items => :items) do
  attributes :amount, :price
  glue :resource do
    attributes :tag, :mu
  end
end
