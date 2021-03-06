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

class AntOSDK extends this.OS.GUI.BaseApplication
    constructor: ( args ) ->
        super "AntOSDK", args
        @currfile = if @args and @args.length > 0 then @args[0].asFileHandler() else null
    loadScheme: () ->
        path = "#{@meta().path}/" + if @currfile then "scheme.html" else "welcome.html"
        @render path
    main: () ->
        me = @
        @scheme.set "apptitle", "AntOSDK"
        @statbar = @find "editorstat"
        if not @currfile
            (@find "btnnewprj").set "onbtclick", () ->
                me.newProject (path) ->
                    me.currfile = "#{path}/project.apj".asFileHandler()
                    me.loadScheme()
            return
        @initWorkspace()

    initWorkspace: () ->
        me = @
        @fileview = @find "fileview"
        div = @find "datarea"
        
        ace.require "ace/ext/language_tools"

        @.editor = ace.edit div
        @.editor.setOptions {
            enableBasicAutocompletion: true,
            enableSnippets: true,
            enableLiveAutocompletion: true,
            fontSize: "13px"
        }
        @.editor.completers.push { getCompletions: ( editor, session, pos, prefix, callback ) -> }
        @.editor.getSession().setUseWrapMode true

        @fileview.contextmenuHandler = (e, m) ->
            m.set "items", me.contextMenu()
            m.set "onmenuselect", (evt) ->
                me.contextAction evt
            m.show e

        @mlist = @find "modelist"
        @modes = ace.require "ace/ext/modelist"
        ldata = []
        f = (m, i) ->
            ldata.push {
                text: m.name,
                mode: m.mode,
                selected: if m.mode is 'ace/mode/text' then true else false
            }
            m.idx = i
        f(m, i) for m, i in @modes.modes
        @mlist.set "items", ldata
        @mlist.set "onlistselect", (e) ->
            me.editor.session.setMode e.data.mode

        themelist = @find "themelist"
        themes = ace.require "ace/ext/themelist"
        ldata = []
        ldata.push {
            text: m.caption,
            mode: m.theme,
            selected: if m.theme is "ace/theme/monokai" then true else false
        } for k, m of themes.themesByName
        themelist.set "onlistselect", (e) ->
            me.editor.setTheme e.data.mode
        themelist.set "items", ldata

        stat = @find "editorstat"
        #status
        stup = (e) ->
            c = me.editor.session.selection.getCursor()
            l = me.editor.session.getLength()
            stat.set "text", __("Row {0}, col {1}, lines: {2}", c.row, c.column, l)
        stup(0)
        @.editor.getSession().selection.on "changeCursor", (e) -> stup(e)
        @editormux = false
        @editor.on "input", () ->
            if me.editormux
                me.editormux = false
                return false
            if not me.currfile.dirty
                me.currfile.dirty = true
                me.currfile.text += "*"
                me.tabarea.update()

        @on "resize", () -> me.editor.resize()
        @on "focus", () -> me.editor.focus()

        @fileview.set "fetch", (e, f) ->
            return unless e.child
            return if e.child.filename is "[..]"
            e.child.path.asFileHandler().read (d) ->
                return me.error __("Resource not found {0}", e.child.path) if d.error
                f d.result
        @fileview.set "onfileopen", (e) ->
            return if e.type is "dir"
            me.open e.path.asFileHandler()
        @subscribe "VFS", (d) ->
            p = (me.fileview.get "path").asFileHandler()
            me.chdir p.path if  d.data.file.hash()  is p.hash() or d.data.file.parent().hash() is p.hash()

        @tabarea = @find "tabarea"
        @tabarea.set "ontabselect", (e) ->
            me.selecteTab e.idx
        @tabarea.set "onitemclose", (e) ->
            it = e.item.item
            return false unless it
            return me.closeTab it unless it.dirty
            me.openDialog "YesNoDialog", (d) ->
                return me.closeTab it if d
                me.editor.focus()
            , __("Close tab"), { text: __("Close without saving ?") }
            return false
        #@tabarea.set "closable", true
        @bindKey "ALT-N", () -> me.actionFile "#{me.name}-New"
        @bindKey "ALT-O", () -> me.actionFile "#{me.name}-Open"
        @bindKey "CTRL-S", () -> me.actionFile "#{me.name}-Save"
        @bindKey "ALT-W", () -> me.actionFile "#{me.name}-Saveas"
        @openProject @currfile if @currfile
        @trigger "calibrate"
    
    newProject: (f) ->
        me = @
        @openDialog "FileDiaLog", (d, n, p) ->
            rpath = "#{d}/#{n}"
            # create folder
            # create javascripts dir
            # create css dir
            # create coffees dir
            # create asset dir
            dirs = [
                rpath,
                "#{rpath}/javascripts",
                "#{rpath}/css",
                "#{rpath}/coffees",
                "#{rpath}/assets"
            ]
            fn = (list, f1) ->
                return f1() if list.length is 0
                dir = (list.splice 0, 1)[0].asFileHandler()
                name = dir.basename
                dir = dir.parent().asFileHandler()
                dir.mk name, (r) ->
                    return me.error __("Error when create directory: {0}", r.error) if r.error
                    me.statbar.set "text", __("Created directory: {0}", dir.path + "/" + name)
                    #console.log "created", dir.path + "/" + name
                    fn list, f1
            
            fn dirs, () ->
                # create package.json
                # create README.md
                # create project.apj
                # create coffees/main.coffee
                # create shemes/scheme.html
                files =  [
                    {
                        path: "#{rpath}/package.json",
                        content: """
                            {
                                "app":"#{n}",
                                "name":"#{n}",
                                "description":"",
                                "info":{
                                    "author": "",
                                    "email": ""
                                },
                                "version":"0.1a",
                                "category":"Other",
                                "iconclass":"fa fa-adn",
                                "mimes":["none"]
                            }"""
                    },
                    {
                        path: "#{rpath}/README.md",
                        content: "##{n}"
                    },
                    {
                        path: "#{rpath}/project.apj",
                        content: """
                        {
                            "root": "#{d}/#{n}",
                            "css": [],
                            "javascripts": [],
                            "coffees": ["coffees/main.coffee"],
                            "copies": ["assets/scheme.htm", "package.json"]
                        }
                        """
                    },
                    {
                        path: "#{rpath}/coffees/main.coffee",
                        content: """
                        class #{n} extends this.OS.GUI.BaseApplication
                            constructor: ( args ) ->
                                super "#{n}", args
                            
                            main: () ->
                        
                        this.OS.register "#{n}", #{n}
                        """
                    },
                    {
                        path: "#{rpath}/assets/scheme.html",
                        content: """
                        <afx-app-window apptitle="" width="600" height="500" data-id="#{n}">
                            <afx-hbox ></afx-hbox>
                        </afx-app-window>
                        """
                    }
                ]
                fn1 = (list, f2) ->
                    return f2(rpath) if list.length is 0
                    entry  = (list.splice 0, 1)[0]
                    file = entry.path.asFileHandler()
                    file.cache = entry.content
                    file.write "text/plain", (res) ->
                        return me.error __("Cannot create file: {0}", res.error) if res.error
                        me.statbar.set "text", __("Created file: {0}", file.path)
                        fn1 list, f2
                fn1 files, f
        , "__(New Project at)", { file: { basename: __("ProjectName") } }

    openProject: (file) ->
        me = @
        file.read (d) ->
            me.chdir d.root if d.root
            me.pinfo = d
            me.open "#{d.root}/coffees/main.coffee".asFileHandler()
        ,"json"

    open: (file) ->
        #find table
        i = @findTabByFile file
        @fileview.set "preventUpdate", true
        return @tabarea.set "selected", i if i isnt -1
        return @newtab file if file.path.toString() is "Untitled"
        me = @
        file.read (d) ->
            file.cache = d or ""
            me.newtab file

    contextMenu: () ->
        [
            { text: __("New file"), dataid: "#{@name}-mkf" },
            { text: __("New folder"), dataid: "#{@name}-mkd" },
            { text: __("Delete"), dataid: "#{@name}-rm" }
            { text: __("Refresh"), dataid: "#{@name}-refresh" }
        ]

    contextAction: (e) ->
        me = @
        file = @fileview.get "selectedFile"
        dir = if file then file.path.asFileHandler() else (@fileview.get "path").asFileHandler()
        dir = dir.parent().asFileHandler() if file and file.type isnt "dir"
        switch e.item.data.dataid

            when "#{@name}-mkd"
                @openDialog "PromptDialog",
                    (d) ->
                        dir.mk d, (r) ->
                             me.error __("Fail to create {0}: {1}", d, r.error) if r.error
                    , "__(New folder)"
            
            when "#{@name}-mkf"
                @openDialog "PromptDialog",
                    (d) ->
                        fp = "#{dir.path}/#{d}".asFileHandler()
                        fp.write "", (r) ->
                            me.error __("Fail to create {0}: {1}", d, r.error) if r.error
                    , "__(New file)"
            when "#{@name}-rm"
                return unless file
                @openDialog "YesNoDialog",
                    (d) ->
                        return unless d
                        file.path.asFileHandler()
                            .remove (r) ->
                                me.error __("Fail to delete {0}: {1}", file.filename, r.error) if r.error
                , "__(Delete)" ,
                { iconclass: "fa fa-question-circle", text: __("Do you really want to delete: {0}?", file.filename) }
            when "#{@name}-refresh"
                @.chdir ( @fileview.get "path" )

    save: (file) ->
        me = @
        file.write "text/plain", (d) ->
            return me.error __("Error saving file {0}", file.basename) if d.error
            file.dirty = false
            file.text = file.basename
            me.tabarea.update()

    findTabByFile: (file) ->
        lst = @tabarea.get "items"
        its = ( i for d, i in lst when d.hash() is file.hash() )
        return -1 if its.length is 0
        return its[0]

    closeTab: (it) ->
        @tabarea.remove it, false
        cnt = @tabarea.get "count"
        if cnt is 0
            @open "Untitled".asFileHandler()
            return false
        @tabarea.set "selected", cnt - 1
        return false

    newtab: (file) ->
        file.text = if file.basename then file.basename else file.path
        file.cache = "" unless file.cache
        file.um = new ace.UndoManager()
        @currfile.selected = false
        file.selected = true
        #console.log cnt
        @tabarea.push file, true
        #@currfile = @file
        #TODO: fix problem : @tabarea.set "selected", cnt

    selecteTab: (i) ->
        #return if i is @tabarea.get "selidx"
        file = (@tabarea.get "items")[i]
        return unless file
        @scheme.set "apptitle", file.text.toString()
        #return if file is @currfile
        if @currfile isnt file
            @currfile.cache = @editor.getValue()
            @currfile.cursor = @editor.selection.getCursor()
            @currfile = file

        m = "ace/mode/text"
        m = (@modes.getModeForPath file.path) if file.path.toString() isnt "Untitled"
        @mlist.set "selected", m.idx
        
        @editormux = true
        @editor.setValue file.cache, -1
        @editor.session.setMode m.mode
        @editor.session.setUndoManager file.um
        if file.cursor
            @editor.renderer.scrollCursorIntoView { row: file.cursor.row, column: file.cursor.column }, 0.5
            @editor.selection.moveTo file.cursor.row, file.cursor.column
        @editor.focus()

    chdir: (pth) ->
        #console.log "called", @_api.throwe("FCK")
        return unless pth
        me = @
        dir = pth.asFileHandler()
        dir.read (d) ->
            if(d.error)
                return me.error __("Resource not found {0}", p)
            if not dir.isRoot()
                p = dir.parent().asFileHandler()
                p.filename = "[..]"
                p.type = "dir"
                #p.size = 0
                d.result.unshift p
            ($ me.navinput).val dir.path
            me.fileview.set "path", pth
            me.fileview.set "data", d.result

    menu: () ->
        me = @
        menu = [{
                text: "__(Project)",
                child: [
                    { text: "__(New)", dataid: "#{@name}-New", shortcut: "A-N"  },
                    { text: "__(Open)", dataid: "#{@name}-Open", shortcut: "A-O"  },
                    { text: "__(Save)", dataid: "#{@name}-Save", shortcut: "C-S" },
                    { text: "__(Save as)", dataid: "#{@name}-Saveas", shortcut: "A-W" }
                ],
                onmenuselect: (e) -> me.actionFile e.item.data.dataid
            }]
        menu
    
    actionFile: (e) ->
        me = @
        saveas = () ->
            me.openDialog "FileDiaLog", (d, n) ->
                file = "#{d}/#{n}".asFileHandler()
                file.cache = me.currfile.cache
                file.dirty = me.currfile.dirty
                file.um = me.currfile.um
                file.cursor = me.currfile.cursor
                file.selected = me.currfile.selected
                file.text = me.currfile.text
                me.tabarea.replaceItem me.currfile, file, false
                me.currfile = file
                me.save me.currfile
            , "__(Save as)", { file: me.currfile }
        switch e
            when "#{@name}-Open"
                @openDialog "FileDiaLog", ( d, f ) ->
                    me.open "#{d}/#{f}".asFileHandler()
                , "__(Open file)"
            when "#{@name}-Save"
                @currfile.cache = @editor.getValue()
                return @save @currfile if @currfile.basename
                saveas()
            when "#{@name}-Saveas"
                @currfile.cache = @editor.getValue()
                saveas()
            when "#{@name}-New"
                @open "Untitled".asFileHandler()
    
    cleanup: (evt) ->
        return unless @currfile
        dirties = ( v for v in  @tabarea.get "items" when v.dirty )
        return if dirties.length is 0
        me = @
        evt.preventDefault()
        @.openDialog "YesNoDialog", (d) ->
            if d
                v.dirty = false for v in dirties
                me.quit()
        , "__(Quit)", { text: __("Ignore all {0} unsaved files ?", dirties.length) }

AntOSDK.singleton = false
AntOSDK.dependencies = [
    "ace/ace",
    "ace/ext-language_tools",
    "ace/ext-modelist",
    "ace/ext-themelist"
]
this.OS.register "AntOSDK", AntOSDK