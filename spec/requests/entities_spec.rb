# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

feature 'entities', %q{
  As an user
  I want to view entities
} do

  before :each do
    create(:chart)
  end

  scenario 'view entities', js: true do
    per_page = Settings.root.per_page
    (per_page + 1).times { create(:entity) }
    create(:legal_entity)

    entities = SubjectOfLaw.all(page: 1, per_page: per_page)
    count = SubjectOfLaw.count

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']" +
                           "/li[@id='entities' and @class='sidebar-selected']")

    titles = [I18n.t('views.entities.tag'), I18n.t('views.entities.type')]

    check_header("#container_documents table", titles)
    check_content("#container_documents table", entities) do |entity|
      [entity.tag, I18n.t("activerecord.models.#{entity.type.tableize.singularize}")]
    end

    check_paginate("div[@class='paginate']", count, per_page)
    next_page("div[@class='paginate']")

    entities = SubjectOfLaw.all(page: 2, per_page: per_page)

    check_content("#container_documents table", entities) do |entity|
      [entity.tag, I18n.t("activerecord.models.#{entity.type.tableize.singularize}")]
    end
  end

  scenario 'view balances by entity', js: true do
    entity = create(:entity)
    deal = create(:deal, entity: entity, rate: 10)
    create(:balance, deal: deal)

    page_login
    page.find('#btn_slide_lists').click
    click_link I18n.t('views.home.entities')
    current_hash.should eq('entities')
    page.should have_xpath("//ul[@id='slide_menu_lists']"+
                           "//li[@id='entities' and @class='sidebar-selected']")

    within('#container_documents table tbody') do
      page.find(:xpath, ".//tr[1]/td[1]").click
    end
    current_hash.should eq("balance_sheet?entity%5Bid%5D=#{entity.id}&"+
                                   "entity%5Btype%5D=#{entity.class.name}")
    find('#slide_menu_conditions').visible?.should be_true
    within('#container_documents table tbody') do
      page.should have_selector('tr', count: 1)
      page.should have_content(deal.tag)
      page.should have_content(deal.entity.name)
    end
  end

  scenario 'create/edit entity', js: true do
    page_login
    page.find('#btn_slide_services').click
    page.find('#arrow_entities_actions').click
    click_link I18n.t('views.home.entity')
    current_hash.should eq('documents/entities/new')
    page.should have_xpath("//li[@id='entities_new' and @class='sidebar-selected']")
    page.should have_selector("div[@id='container_documents'] form")
    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.new'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should be_nil
    find_button(I18n.t('views.users.edit'))[:disabled].should eq("true")

    click_button(I18n.t('views.users.save'))

    within("#container_documents form") do
      find("#container_notification").visible?.should be_true
      within("#container_notification") do
        page.should have_content("#{I18n.t(
            'views.entities.tag')} : #{I18n.t('errors.messages.blank')}")
      end
    end

    fill_in('entity_tag', with: 'new entity')
    page.should_not have_selector("#container_notification")

    lambda do
      click_button(I18n.t('views.users.save'))
      wait_for_ajax
      wait_until_hash_changed_to "documents/entities/#{Entity.last.id}"
    end.should change(Entity, :count).by(1)

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil
    find_field('entity_tag')[:disabled].should eq("true")
    click_button(I18n.t('views.users.edit'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/entities/#{Entity.last.id}/edit"

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.edit'))
    end

    find_field('entity_tag')[:disabled].should be_nil

    fill_in('entity_tag', with: 'edited new entity')

    click_button(I18n.t('views.users.save'))
    wait_for_ajax
    wait_until_hash_changed_to "documents/entities/#{Entity.last.id}"

    within('#page-title') do
      page.should have_content(I18n.t('views.entities.page.title.show'))
    end

    find_button(I18n.t('views.users.save'))[:disabled].should eq("true")
    find_button(I18n.t('views.users.edit'))[:disabled].should be_nil

    find_field('entity_tag')[:disabled].should eq("true")
    find_field('entity_tag')[:value].should eq('edited new entity')
  end
end
