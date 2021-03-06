# Copyright 2017-2018 Xuan Sang LE <xsang.le AT gmail DOT com>

# AnTOS Web desktop is is licensed under the GNU General Public
# License v3.0, see the LICENCE file for more information

# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of 
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
#along with this program. If not, see https://www.gnu.org/licenses/.

class BaseService extends this.OS.GUI.BaseModel
    constructor: (name, args) ->
        super name, args
        @icon = undefined
        @iconclass = "fa-paper-plane-o"
        @text = ""
        @timer = undefined
        @holder = undefined

    init: ()->
        #implement by user
        # event registe, etc
        # scheme loader
    meta: () ->
        _OS.APP[@name].meta
    attach: (h) ->
        @holder = h

    update: () -> @holder.update() if @holder
    
    watch: ( t, f) ->
        me = @
        func = () ->
            f()
            me.timer = setTimeout (() -> func()), t
        func()
    onexit: (evt) ->
        console.log "clean timer" if @timer
        clearTimeout @timer if @timer
        @cleanup(evt)
        ($ @scheme).remove() if @scheme
        
    main: () ->
    show: () ->
    awake: (e) ->
        #implement by user to tart the service
    cleanup: (evt) ->
        #implemeted by user
BaseService.type = 2
BaseService.singleton = true
this.OS.GUI.BaseService = BaseService