# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@waybills => :objects) do
  attributes :id, :document_id
  node(:created) { |waybill| waybill.created.strftime('%Y-%m-%d') }
  node(:distributor) { |waybill| waybill.distributor.name }
  node(:storekeeper) { |waybill| waybill.storekeeper.tag }
  node(:storekeeper_place) { |waybill| waybill.storekeeper_place.tag }
end
node(:per_page) { Settings.root.per_page }