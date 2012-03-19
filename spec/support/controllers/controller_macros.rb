# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module ControllerMacros
  def page_login email = "root@localhost",
                 password = Settings.root.password,
                 remember = false
    visit login_path
    fill_in("Email", :with => email)
    fill_in("Password", :with => password)
    check('remember_me') if remember
    click_on "Log in"
  end

  def current_hash
    current_url.split("#")[1]
  end

  def check_autocomplete(element_id, items, attr)
    fill_in(element_id, :with => "qqqqq")
    page.find("##{element_id}").find(:xpath, ".//..").click
    find("##{element_id}")["value"].should eq("qqqqq")
    fill_in(element_id, :with => items[0].send(attr)[0..1])
    page.should have_xpath(
                    "//div[@class='ac_results' and contains(@style, 'display: block')]")
    within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
      all(:xpath, ".//ul//li").length.should eq(5)
      (0..4).each do |idx|
        page.should have_content(items[idx].send(attr))
      end
      page.should_not have_content(items[5].send(attr))
      all(:xpath, ".//ul//li")[1].click
    end
    find("##{element_id}")["value"].should eq(items[1].send(attr))
    yield(items[1]) if block_given?
    fill_in(element_id, :with => "")
    find("##{element_id}")["value"].should eq("")
    yield(nil) if block_given?
    fill_in(element_id, :with => items[0].send(attr)[0..1])
    within(:xpath, "//div[@class='ac_results' and contains(@style, 'display: block')]") do
      all(:xpath, ".//ul//li")[1].click
    end
  end

end

RSpec.configure do |config|
  config.include(ControllerMacros)
end