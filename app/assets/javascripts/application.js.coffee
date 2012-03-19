# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
#= require jquery
#= require jquery-ui
#= require jquery_ujs
#= require jquery.autocomplete
#= require jquery.validate
#= require sammy
#= require knockout
#= require pluralize
#= require_self
#= require_tree .

$ ->
  waybillFormValidate = ->
    $("#container_documents form").validate({
      errorContainer: "#container_notification"
      errorLabelContainer: "#container_notification ul",
      errorElement: "li"
      rules: {
        count: {
          required: true,
          number: true,
          min: 1
        }
      }
    })
    for item in $("input[rule='required']")
      $(item).rules("add", {
        required: true,
        messages: {
          required: $(item).attr("name") + " field is required.",
        }
      })
    for item in $("input[rule='required_num']")
      $(item).rules("add", {
        required: true,
        min: 1,
        messages: {
          required: $(item).attr("name") + " field is required.",
          min: $(item).attr("name") + " should be greater than or equal to 1."
        }
      })
    $("#container_documents form").valid()

  documentViewModel = (type, data, readonly = false) ->
    estimateBoM = (data = { id: null, tag: "", tab: "", count: null, sum: null }) ->
      id: ko.observable(data.id)
      tag: ko.observable(data.tag)
      tab: ko.observable(data.tab)
      count: ko.observable(data.count)
      sum: ko.observable(data.sum)
      opened: ko.observable(false)
      elements: ko.observableArray([])
    waybill_entry = (data = { id: null, tag: null, mu: null, count: null, price: null }) ->
      id: ko.observable(data.id)
      tag: ko.observable(data.tag)
      mu: ko.observable(data.mu)
      count: ko.observable(data.count)
      price: ko.observable(data.sum)
    self.readonly = ko.observable(readonly)
    #TODO: refactor
    self.object = ko.observable(if readonly then data.object else data)
    self.object().catalog_id = ko.observable(object().catalog_id)
    self.object().place_id = ko.observable(object().place_id)
    self.waybill_object = ko.observable(if readonly then data.object else data)
    self.waybill_object().created = ko.observable(waybill_object().created)
    self.waybill_object().document_id = ko.observable(waybill_object().document_id)
    self.legal_entity =
      name: ko.observable(if readonly then data.legal_entity.name else "")
      identifier_name: ko.observable(if readonly then data.legal_entity.identifier_name else "")
      identifier_value: ko.observable(if readonly then data.legal_entity.identifier_value else "")
    self.distributor =
      name: ko.observable(if readonly then data.distributor.name else "")
      identifier_name: ko.observable(if readonly then data.distributor.identifier_name else "")
      identifier_value: ko.observable(if readonly then data.distributor.identifier_value else "")
    self.distributor_place =
      tag: ko.observable(if readonly then data.distributor_place.tag else "")
    self.storekeeper_place =
      tag: ko.observable(if readonly then data.storekeeper_place.tag else "")
    self.storekeeper =
      tag: ko.observable(if readonly then data.storekeeper.tag else "")
    self.boms = ko.observableArray([])
    self.waybill_entries = ko.observableArray([])
    if readonly
      for item in data.boms
        self.boms.push(estimateBoM(item))
    else
      self.boms.push(estimateBoM())

    self.autocomplete_init = (data, event) ->
      unless $(event.target).attr("autocomplete")
        params = {}
        if((event.target.id == "estimate_catalog_date") ||
           ($(event.target).attr("class") == "bom_tab"))
          params["catalog_id"] = self.object()["catalog_id"]
        $(event.target).autocomplete($(event.target).attr("data-url"), {
          dataType: "json",
          selectFirst: false,
          delay: 600,
          cacheLength: 0,
          matchCase: true,
          extraParams: params,
          parse: (data) ->
            parsed = []
            for object, id in data
              parsed[id] =
                data: object
                value: object[$(event.target).attr("data-field")]
                result: object[$(event.target).attr("data-field")]
            parsed
          ,
          formatItem: (item) ->
            return item[$(event.target).attr("data-field")]
        })
        $(event.target).change( ->
          if($(event.target).attr("class").search("bom_tab") == 0)
            self.boms()[$(event.target).closest("tr").attr("idx")].id(null)
            self.boms()[$(event.target).closest("tr").attr("idx")].tag("")
            self.boms()[$(event.target).closest("tr").attr("idx")].tab("")
            self.boms()[$(event.target).closest("tr").attr("idx")].count(null)
            self.boms()[$(event.target).closest("tr").attr("idx")].sum(null)
          else
            self.object()[$(event.target).attr("bind-param")] = null
            self.waybill_object()[$(event.target).attr("bind-param")] = null
            switch $(event.target).attr("id")
              when "estimate_entity"
                self.legal_entity.identifier_name("")
                self.legal_entity.identifier_value("")
              when "waybill_entity"
                self.distributor.identifier_name("")
                self.distributor.identifier_value("")
              when "estimate_catalog_date"
                $(event.target).val("")
        )
        $(event.target).result((event, data, formatted) ->
          if($(event.target).attr("class").search("bom_tab") == 0)
            self.boms()[$(event.target).closest("tr").attr("idx")].id(data["id"])
            self.boms()[$(event.target).closest("tr").attr("idx")].tab($(event.target).val())
            self.boms()[$(event.target).closest("tr").attr("idx")].tag(data["tag"])
            self.boms()[$(event.target).closest("tr").attr("idx")].count("1")
            self.bom_sum(self.boms()[$(event.target).closest("tr").attr("idx")])
          else
            switch $(event.target).attr("id")
              when "estimate_entity"
                self.object()[$(event.target).attr("bind-param")] = data["id"]
                self.legal_entity.identifier_name(data[$("#estimate_ident_name").attr("data-field")])
                self.legal_entity.identifier_value(data[$("#estimate_ident_value").attr("data-field")])
              when "waybill_entity"
                self.waybill_object()[$(event.target).attr("bind-param")] = data["id"]
                self.distributor.identifier_name(data[$("#waybill_ident_name").attr("data-field")])
                self.distributor.identifier_value(data[$("#waybill_ident_value").attr("data-field")])
              when "estimate_catalog_date"
                self.object()[$(event.target).attr("bind-param")] = data["date"]
              when "distributor_place", "storekeeper_entity", "storekeeper_place"
                self.waybill_object()[$(event.target).attr("bind-param")] = data["id"]
        )
    self.catalogs = ko.observableArray([])
    self.parent_id = null
    self.get_catalogs = (params = {}) ->
      $.getJSON("/catalogs.json", params, (data) ->
        if data.parent_id == null
          $(".actions input[value=Previous]").attr("disabled", "true")
        else
          $(".actions input[value=Previous]").removeAttr("disabled")
        self.parent_id = data.parent_id
        self.catalogs(data.subcatalogs)
      )
    self.show_catalog_selector = () ->
      $("#container_documents form").hide()
      $("div.form_choose").show()
      $(".actions").html(button("Cancel", hide_catalog_selector))
      $(".actions").append(button("Previous", show_previous_catalogs))
      get_catalogs()
    self.show_subcatalogs = (data, event) ->
      if $(event.target).parent().attr("count") > 0
        get_catalogs({ parent_id: $(event.target).parent().attr("id") })
    self.show_previous_catalogs = (data, event) ->
      get_catalogs({ id: self.parent_id })
    self.hide_catalog_selector = () ->
      $("div.form_choose").hide()
      $("#container_documents form").show()
      actions()
    self.select_catalog = (data, event) ->
      self.object().catalog_id($(event.target).parent().attr("id"))
      $("#estimate_catalog").val($(event.target).parent().attr("name"))
      $("#estimate_catalog_date").val("")
      hide_catalog_selector()
    self.bom_add = ->
      self.boms.push(estimateBoM())
    self.waybill_entry_add = ->
      self.waybill_entries.push(waybill_entry())
      waybillFormValidate() if $("#container_documents form").attr("novalidate")
    self.bom_remove = (bom) ->
      self.boms.remove(bom)
    self.waybill_entry_remove = (waybill_entry) ->
      self.waybill_entries.remove(waybill_entry)
      waybillFormValidate() if $("#container_documents form").attr("novalidate")
    self.load_bom_sum = (data, event) ->
      if($(event.target).val().length && $(event.target).val() != "0" &&
         $(event.target).val().match('^([0-9]*)$'))
        self.bom_sum(self.boms()[$(event.target).attr("idx")])
      else
        self.boms()[$(event.target).attr("idx")].count("0")
        self.boms()[$(event.target).attr("idx")].sum("0.0")
    self.open_tree_elements = (bom) ->
      unless bom.elements().length
        params =
          catalog_id: self.object().catalog_id()
          date: self.object().date
          amount: bom.count()
        $.getJSON("/bo_ms/" + bom.id() + "/elements.json", params, (data) ->
          bom.elements(data)
        )
      bom.opened(true)
    self.close_tree_elements = (bom) ->
      bom.opened(false)
    self.bom_sum = (bom) ->
      params =
        catalog_id: self.object().catalog_id()
        date: self.object().date
        amount: bom.count()
      $.getJSON("/bo_ms/" + bom.id() + "/sum.json", params, (data) ->
        bom.sum(data.sum)
      )
    self.save = ->
      boms = []
      for id, bom of self.boms()
        boms.push({bom_id: bom.id(), amount: bom.count()})
      params =
        object: self.object()
        boms: boms
      params["legal_entity"] = self.legal_entity unless self.object().legal_entity_id
      $.ajax({
        type: if self.object().id then "PUT" else "POST",
        url: "/estimates" + if self.object().id then "/#{self.object().id}" else "",
        data: params,
        complete: (data) ->
          location.hash = "inbox" if data.responseText == "success"
      })
    self.waybill_save = ->
      items =[]
      for id, item of self.waybill_entries()
        items.push({tag: item.tag(), mu: item.mu(),
        count: item.count(), price: item.price})
      params =
        waybill_object:
          created: self.waybill_object().created
          document_id: self.waybill_object().document_id
          distributor_id: self.waybill_object().distributor_id
          distributor_place_id: self.waybill_object().distributor_place_id
          storekeeper_id: self.waybill_object().storekeeper_id
          storekeeper_place_id: self.waybill_object().storekeeper_place_id
        items: items
      params["distributor"] = self.distributor unless self.waybill_object().distributor_id
      params["distributor_place"] = self.distributor_place unless self.waybill_object().distributor_place_id
      params["storekeeper"] = self.storekeeper unless self.waybill_object().storekeeper_id
      params["storekeeper_place"] = self.storekeeper_place unless self.waybill_object().storekeeper_place_id
      $.ajax({
        type: if self.waybill_object().id then "PUT" else "POST",
        url: "/waybills" + if self.waybill_object().id then "/#{self.waybill_object().id}" else "",
        data: params,
        complete: (data) ->
          location.hash = "inbox" if data.responseText == "success"
      })
    $.sammy( ->
      this.get("#documents/:type/:id/edit", ->
        $(".actions").html(button("Save", -> $("#container_documents form").submit()))
        self.readonly(false)
      )
    )
    self

  folderViewModel = (data) ->
    self.documents = ko.observableArray(data)
    self.showDocument = (document) ->
      location.hash = "documents/" + owl.pluralize(document.type.toLowerCase()) + "/" + document.id
    $.sammy( ->
      this.get("#documents/:type/:id", ->
        document_id = this.params.id
        document_type = this.params.type
        $.get("/" + document_type + "/preview", {}, (form) ->
          $.getJSON("/" + document_type + "/" + document_id + ".json", {}, (data) ->
            $(".actions").html(button("Back", -> location.hash = "inbox"))
            $(".actions").append(button("Edit", -> location.hash =
              "#documents/#{document_type}/#{document_id}/edit"))
            $("#container_documents").html(form)
            viewModel = new documentViewModel(document_type, data, true)
            ko.applyBindings(viewModel, $("#container_documents").get(0))
          )
        )
      )
    )
  self

  homeViewModel = ->
    self.documentVM = null
    self.folderVM = null
    $.sammy( ->
      this.get("#inbox", ->
        $.get("/inbox", {}, (form) ->
          $.getJSON("/inbox_data.json", {}, (data) ->
            $(".actions").html("")
            $("#container_documents").html(form)
            $(".sidebar-selected").removeClass("sidebar-selected")
            $("#inbox").addClass("sidebar-selected")
            self.folderVM = new folderViewModel(data)
            ko.applyBindings(self.folderVM, $("#container_documents").get(0))
          )
        )
      )
      this.get("#documents/:type/new", ->
        menuClose()
        document_type = this.params.type
        $.get("/" + document_type + "/preview", {}, (form) ->
          $.getJSON("/" + document_type + "/new.json", {}, (data) ->
            actions()
            $("#container_documents").html(form)
            $("#inbox").removeClass("sidebar-selected")
            self.documentVM = new documentViewModel(document_type, data)
            ko.applyBindings(self.documentVM, $("#container_documents").get(0))
          )
        )
      )
      this.get("#warehouses", ->
        $.get("/warehouses", {}, (form) ->
          $(".actions").html("")
          $("#container_documents").html(form)
          $(".sidebar-selected").removeClass("sidebar-selected")
          $("#warehouses").addClass("sidebar-selected")
        )
      )
    ).run()
    location.hash = "inbox" if $("#main").length

  ko.applyBindings(new homeViewModel())

  window.actions = ->
    $(".actions").html(button("Save", -> $("#container_documents form").submit() if waybillFormValidate()))
    $(".actions").append(button("Cancel", -> location.hash = "inbox"))
    $(".actions").append(button("Draft"))
  window.button = (value, func = null) ->
    $("<input type='button'/>").attr("value", value).click(func)

  window.menuClose = ->
    $('#documents_list').slideUp('fast') unless $("#documents_list").css("display") == "none"

  $('#btn_create').click( ->
    $('#documents_list').slideToggle('fast')
    false
  )

  document.onclick = ->
    menuClose()