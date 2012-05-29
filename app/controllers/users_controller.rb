# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class UsersController < ApplicationController
  def index
    render "users/index", layout: false
  end

  def preview
    @document_types = implemented_documents
    render "users/preview", layout: false
  end

  def new
    @user = User.new
  end

  def create
    user = nil
    begin
      User.transaction do
        user = User.new(params[:user])
        unless user.entity
          user.entity = Entity.create!(tag: params[:entity][:tag])
        end
        user.save!
        if params[:credentials]
          params[:credentials].values.each do |credential|
            user.credentials.create!(
                place: Place.find_or_create_by_tag(credential[:tag]),
                document_type: credential[:document_type])
          end
        end
      end
      render text: "success"
    rescue
      render json: user.errors.messages
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    @users = User.limit(per_page).offset((page - 1) * per_page).all
    @count = User.count
  end

  def update
    user = User.find(params[:id])
    begin
      User.transaction do
        user.update_attributes(email: params[:user][:email])
        unless user.entity.tag == params[:entity][:tag]
          user.entity = Entity.find_or_create_by_tag(params[:entity][:tag])
        end
        user.credentials.delete_all
        if params[:credentials]
          params[:credentials].values.each do |credential|
            user.credentials.create!(
                place: Place.find_or_create_by_tag(credential[:tag]),
                document_type: credential[:document_type])
          end
        end
        user.save!
        if params[:user][:password]
          user.password_confirmation = params[:user][:password_confirmation]
          user.change_password!(params[:user][:password])
        end
      end
      render text: "success"
    rescue
      render json: user.errors.messages
    end
  end

  def names
    term = params[:term]
    @users = User.joins{entity}.where{entity.tag.like "%#{term}%"}.
        order("entities.tag").limit(5)
  end
end