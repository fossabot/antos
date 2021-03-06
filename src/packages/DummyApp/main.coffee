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

_GUI = this.OS.GUI
class DummyApp extends this.OS.GUI.BaseApplication
    constructor: (args) ->
        super "DummyApp", args
    main: () ->
        self = @
        @on "btclick", (e)->
            #_GUI.pushService "Budgy"
            self.openDialog "ColorPickerDialog", (d) -> console.log d
        @on "resize", (w,h)->
            console.log "#{self.name}: resize"
        #@on "listselect", (i)->
        #    console.log self.name, i
        @on "treeselect", (i) ->
            console.log self.name,i
        @on "focus", ()->
            console.log self.name, "is focused"
        @on "dayselect", (e) -> console.log "cellselected", e
        @on "gridselect", (e) -> console.log "GRID selected", e
        tree = @find "mytree"
        
        @scheme.set "apptitle", "Terminal"
        tdata = {
            name: 'My Tree',
            nodes: [
                { name: 'hello', iconclass:'fa fa-car'},
                { name: 'wat' },
                {
                    name: 'child folder',
                    nodes: [
                        {
                            name: 'child folder',
                            nodes: [
                                { name: 'hello' },
                                { name: 'wat' }
                            ]
                        },
                        { name: 'hello' },
                        { name: 'wat' },
                        {
                            name: 'child folder',
                            nodes: [
                                { name: 'hello' },
                                { name: 'wat' }
                            ]
                        }
                    ]
                }
            ]
        }
        tree.set "data",tdata

        list = @find "mylist"
        ldata = [
            {text:"some thing with avery long text"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing", complex:true, detail:[{text:"Inner content", class:""}]},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"},
            {text:"some thing"}
        ]
        list.set "items",ldata
        list.set "onlistselect", (e)->
            console.log e

        tabs = @find "mytabs"
        tabdatas = [
            {text:"file1.txt"},
            {text:"file2.cpp"}
        ]
        tabs.set "items", tabdatas 

        @scheme.set "apptitle", "AntOS feature showcase"

        @scheme.contextmenuHandler = (e, m) ->
            mdata = [ 
                { text: " Child 1" }, 
                { text: "child2", child: [
                    {text: "sub child", child:[{text:"sub sub child"}] },
                    {text: "sub child 1" }
                    ], onmenuselect: (e) -> console.log e
                }
            ]
            m.set "items", mdata
            m.show(e)

DummyApp.singleton = false
this.OS.register "DummyApp",DummyApp