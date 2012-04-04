# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'distributions', %q{
  As an user
  I want to view distributions
} do

  scenario 'view distributions', js: true do
    Factory(:chart)
    @waybills = nil
    wb = Factory.build(:waybill)
    (0..4).each { |i|
      wb.add_item("resource##{i}", "mu#{i}", 100+i, 10+i)
    }
    wb.save!

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/distributions/new']").click
    current_hash.should eq('documents/distributions/new')

    page.should have_selector("div[@id='container_documents'] form")
    page.should have_selector("input[@value='Save']")
    page.should have_selector("input[@value='Cancel']")
    page.should have_selector("input[@value='Draft']")
    page.find_by_id("inbox")[:class].should_not eq("sidebar-selected")

    page.should have_xpath("//div[@id='ui-datepicker-div']")
    page.find("#created").click
    page.should have_xpath("//div[@id='ui-datepicker-div' and contains(@style, 'display: block')]")
    page.find("#container_documents").click
    page.should have_xpath("//div[@id='ui-datepicker-div' and contains(@style, 'display: none')]")

    page.find("#created").click
    page.find("#ui-datepicker-div table[@class='ui-datepicker-calendar'] tbody tr td a").click

    within("#container_documents form") do
      6.times.collect { Factory(:place) }
      items = Place.find(:all, order: :tag, limit: 5)
      check_autocomplete("storekeeper_place", items, :tag)
      check_autocomplete("foreman_place", items, :tag)

      6.times.collect { Factory(:entity) }
      items = Entity.find(:all, order: :tag, limit: 5)
      check_autocomplete("storekeeper_entity", items, :tag)
      check_autocomplete("foreman_entity", items, :tag)
    end

    within("#container_documents") do
      page.should have_selector("div[@id='resources-tables']")
      within("#resources-tables") do
        page.should have_selector("#available-resources tbody tr")
        within("#available-resources") do
          page.should have_selector('tbody tr', count: 5)
          page.all('tbody tr').each_with_index { |tr, i|
            tr.should have_content("resource##{i}")
            tr.should have_content("mu#{i}")
            tr.should have_content(100+i)
          }
        end

        within("#selected-resources") do
          page.should_not have_selector('tbody tr')
        end

        (0..4).each do |i|
          page.find("#available-resources tbody tr td[@class='distribution-actions'] span").click
          if i < 4 then
            page.should have_selector('#available-resources tbody tr', count: 4-i)
            page.should have_selector('#selected-resources tbody tr', count: 1+i)
          else
            page.should_not have_selector('#available-resources tbody tr')
          end
        end

        within("#available-resources") do
          page.all('tbody tr').each_with_index { |tr, i|
            tr.find("td input[@type='text']")[:value].should eq("#{100+i}")
          }
        end

        (0..4).each do |i|
          page.find("#selected-resources tbody tr td[@class='distribution-actions'] span").click
          if i < 4 then
            page.should have_selector('#selected-resources tbody tr', count: 4-i)
            page.should have_selector('#available-resources tbody tr', count: 1+i)
          else
            page.should_not have_selector('#selected-resources tbody tr')
          end
        end
      end
    end
  end

  scenario 'test distributions save', js: true do
    PaperTrail.enabled = true

    Factory(:chart)
    @waybill = nil
    wb = Factory.build(:waybill, created: DateTime.current.change(year: 2011))
    wb.add_item('roof', 'm2', 12, 100.0)
    wb.add_item('roof2', 'm2', 12, 100.0)
    wb.save!
    @waybill = wb

    page_login

    page.find("#btn_create").click
    page.find("a[@href='#documents/distributions/new']").click

    click_button("Save")
    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("Created field is required.")
        page.should have_content("Storekeeper Entity field is required.")
        page.should have_content("Storekeeper Place field is required.")
        page.should have_content("Foreman Entity field is required.")
        page.should have_content("Foreman Place field is required.")
      end
    end

    page.find("#created").click
    page.find("#ui-datepicker-div table[@class='ui-datepicker-calendar'] tbody tr td a").click

    within("#container_documents form") do
      fill_in("storekeeper_entity", :with => @waybill.storekeeper.tag)
      fill_in("storekeeper_place", :with => @waybill.storekeeper_place.tag)
      fill_in("foreman_entity", :with =>"entity")
      fill_in("foreman_place", :with => "place")
    end

    within("#container_documents #resources-tables") do
      page.find("#available-resources tbody tr td[@class='distribution-actions'] span").click
      page.find("#available-resources tbody tr td[@class='distribution-actions'] span").click
    end

    lambda {
      click_button("Save")
      page.should have_selector("#inbox[@class='sidebar-selected']")
    }.should change(Distribution, :count).by(1)

    PaperTrail.enabled = false
  end

  scenario 'show distributions', js: true do
    PaperTrail.enabled = true

    Factory(:chart)
    wb = Factory.build(:waybill)
    (0..4).each { |i|
      wb.add_item("resource##{i}", "mu#{i}", 100+i, 10+i)
    }
    wb.save!
    ds = Factory.build(:distribution, storekeeper: wb.storekeeper,
                                      storekeeper_place: wb.storekeeper_place)
    (0..4).each { |i|
      ds.add_item("resource##{i}", "mu#{i}", 10+i)
    }
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Distribution - #{wb.storekeeper.tag}')]").click
    current_hash.should eq("documents/distributions/#{ds.id}")

    within("#container_documents form") do
      find("#created")[:value].should eq(ds.created.strftime("%m/%d/%Y"))
      find("#storekeeper_entity")[:value].should eq(ds.storekeeper.tag)
      find("#storekeeper_place")[:value].should eq(ds.storekeeper_place.tag)
      find("#foreman_entity")[:value].should eq(ds.foreman.tag)
      find("#foreman_place")[:value].should eq(ds.foreman_place.tag)
      find("#state")[:value].should eq('Inwork')

      find("#created")[:disabled].should be_true
      find("#storekeeper_entity")[:disabled].should be_true
      find("#storekeeper_place")[:disabled].should be_true
      find("#foreman_entity")[:disabled].should be_true
      find("#foreman_place")[:disabled].should be_true
      find("#state")[:disabled].should be_true
    end

    within("#selected-resources tbody") do
      all(:xpath, './/tr').count.should eq(5)
      all(:xpath, './/tr').each_with_index {|tr, idx|
        tr.should have_content("resource##{idx}")
        tr.should have_content("mu#{idx}")
        tr.find(:xpath, './/input')[:value].should eq("#{10+idx}")
      }
    end

    PaperTrail.enabled = false
  end

  scenario 'applying distributions', js: true do
    PaperTrail.enabled = true

    Factory(:chart)
    wb = Factory.build(:waybill)
    wb.add_item("test resource", "test mu", 100, 10)
    wb.save!

    ds = Factory.build(:distribution, storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    ds.add_item("test resource", "test mu", 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Distribution - #{wb.storekeeper.tag}')]").click
      click_button("Apply")
      page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Distribution - #{wb.storekeeper.tag}')]").click
    page.should_not have_selector("div[@class='actions'] input[@value='Apply']")

    PaperTrail.enabled = false
  end

  scenario 'canceling distributions', js: true do
    PaperTrail.enabled = true

    Factory(:chart)
    wb = Factory.build(:waybill)
    wb.add_item("test resource", "test mu", 100, 10)
    wb.save!

    ds = Factory.build(:distribution, storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    ds.add_item("test resource", "test mu", 10)
    ds.save!

    page_login

    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Distribution - #{wb.storekeeper.tag}')]").click
    click_button("Cancel")
    page.should have_selector("#inbox[@class='sidebar-selected']")
    page.find(:xpath, "//td[@class='cell-title'][contains(.//text(),
      'Distribution - #{wb.storekeeper.tag}')]").click
    page.should_not have_selector("div[@class='actions'] input[@value='Cancel']")
    PaperTrail.enabled = false
  end

end