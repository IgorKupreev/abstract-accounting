# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Asset < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :tag
  validates_uniqueness_of :tag, :scope => :mu
  # TODO: fix direct access to side
  has_many :terms_as_give, :class_name => Term, :as => :resource, :conditions => { :side => false }
  has_many :terms_as_take, :class_name => Term, :as => :resource, :conditions => { :side => true }
  has_many :deal_gives, :class_name => "Deal", :through => :terms_as_give, :source => :deal
  has_many :deal_takes, :class_name => "Deal", :through => :terms_as_take, :source => :deal
  has_many :terms, :as => :resource
  belongs_to :detail, :class_name => "DetailedAsset"

  class << self
    def with_lower_tag_eq_to(value)
      where{lower(tag) == lower(value)}
    end

    def with_lower_mu_eq_to(value)
      where{lower(mu) == lower(value)}
    end
  end
end

# vim: ts=2 sts=2 sw=2 et:
