self.OS.GUI =
    dialogs: new Object()
    dialog: undefined
    htmlToScheme: (html, app, parent) ->
        scheme =  $.parseHTML html
        ($ parent).append scheme
        riot.mount ($ scheme), { observable: app.observable }
        app.scheme = scheme[0]
        app.main()
        app.show()
    loadScheme: (path, app, parent) ->
        _API.get path,
        (x) ->
            return null unless x
            _GUI.htmlToScheme x, app, parent
        , (e, s) ->
            _courrier.osfail "Cannot load scheme file: #{path} for #{app.name} (#{app.pid})", e, s

    clearTheme: () ->
         $ "head link#ostheme"
            .attr "href", ""

    loadTheme: (name, force) ->
        _GUI.clearTheme() if force
        path = "resources/themes/#{name}/#{name}.css"
        $ "head link#ostheme"
            .attr "href", path

    pushServices: (srvs) ->
        f = (v) ->
            _courrier.observable.one "srvroutineready", () -> _GUI.pushService v
        _GUI.pushService srvs[0]
        srvs.splice 0, 1
        f i for i in srvs

    openDialog: (d, f, title, data) ->
        if _GUI.dialog
            _GUI.dialog.show()
            return
        if not _GUI.dialogs[d]
            ex = _API.throwe "Dialog"
            return _courrier.oserror "Dialog #{d} not found", ex, null
        _GUI.dialog = new _GUI.dialogs[d]()
        _GUI.dialog.parent = _GUI
        _GUI.dialog.handler = f
        _GUI.dialog.pid = -1
        _GUI.dialog.data = data
        _GUI.dialog.title = title
        _GUI.dialog.init()

    pushService: (ph) ->
        arr = ph.split "/"
        srv = arr[1]
        app = arr[0]
        return _PM.createProcess srv, _OS.APP[srv] if _OS.APP[srv]
        _GUI.loadApp app,
            (a) ->
                return _PM.createProcess srv, _OS.APP[srv] if _OS.APP[srv]
            (e, s) ->
                _courrier.trigger "srvroutineready", srv
                _courrier.osfail "Cannot read service script: #{srv} ", e, s

    appsByMime: (mime) ->
        metas = ( a.meta for k, a of _OS.APP when a and a.type is 1)
        mimes = ( m.mimes for m in metas when m)
        apps = []
        # search app by mimes
        f = ( arr, idx ) ->
            try
                arr.filter (m, i) ->
                    if mime.match (new RegExp m, "g")
                        apps.push metas[idx]
                        return false
                    return false
            catch e
                _courrier.osfail "Find app by mimes #{mime}", e, mime

        ( f m, i if m ) for m, i in mimes
        return apps
       
    openWith: (it) ->
        return unless it
        console.log "open #{it.path}"
        apps = _GUI.appsByMime ( if it.type is "dir" then "dir" else it.mime )
        return OS.info "No application available to open #{it.filename}" if apps.length is 0
        return _GUI.launch apps[0].app, [it.path] if apps.length is 1
        list = ( { text: e.app, icon: e.icon, iconclass: e.iconclass } for e in apps )
        _GUI.openDialog "SelectionDialog", ( d ) ->
            _GUI.launch d.text, [it.path]
        , "Open width", list

    forceLaunch: (app, args) ->
        console.log "This method is used for developing only, please use the launch method instead"
        _PM.killAll app
        _OS.APP[app] = undefined
        _GUI.launch app, args

    loadApp: (app, ok, err) ->
        path = "packages/#{app}/"
        _API.script path + "main.js",
            (d) ->
                #load css file
                _API.get "#{path}main.css",
                    () ->
                        $ '<link>', { rel: 'stylesheet', type: 'text/css', 'href': "#{path}main.css" }
                            .appendTo 'head'
                    , () ->
                #launch
                if _OS.APP[app]
                    # load app meta data
                    _API.get "#{path}package.json",
                        (data) ->
                            _OS.APP[app].meta = data
                            ok app
                        , (e, s) ->
                            _courrier.osfail "Cannot read application metadata: #{app}", e, s
                            err e, s
                else
                    ok app
            , (e, s) ->
                #BUG report here
                _courrier.osfail "Cannot load application script: #{app}", e, s
                console.log "bug report", e, s, path
                err e,s
    launch: (app, args) ->
        if not _OS.APP[app]
            # first load it
            _GUI.loadApp app,
                (a)->
                    _PM.createProcess a, _OS.APP[a], args
                , (e, s) ->
        else
            # now launch it
            if _OS.APP[app]
                _PM.createProcess app, _OS.APP[app], args
    dock: (app, meta) ->
        # dock an application to a dock
        # create a data object
        data =
            icon: null
            iconclass: meta.iconclass || ""
            app: app
            onbtclick: () -> app.toggle()
        data.icon = "packages/#{meta.app}/#{meta.icon}" if meta.icon
        # TODO: add default app icon class in system setting
        # so that it can be themed
        data.iconclass = "fa fa-cogs" if (not meta.icon) and (not meta.iconclass)
        dock = $ "#sysdock"
        app.one "rendered", () ->
            dock.get(0).newapp data
            app.sysdock = dock.get(0)
            app.appmenu = ($ "[data-id = 'appmenu']", "#syspanel")[0]
        app.init()

    undock: (app) ->
        ($ "#sysdock").get(0).removeapp app

    attachservice: (srv) ->
        ($ "#syspanel")[0].attachservice srv
        srv.init()
    detachservice: (srv) ->
        ($ "#syspanel")[0].detachservice srv
    bindContextMenu: (event) ->
        handler  = (e) ->
            if e.contextmenuHandler
                e.contextmenuHandler event, ($ "#contextmenu")[0]
            else
                p = $(e).parent().get(0)
                handler p if p isnt ($ "#workspace").get(0)
        handler event.target
        event.preventDefault()
    initDM: ->
        # check login first
        _API.resource "schemes/dm.html", (x) ->
            return null unless x
            scheme =  $.parseHTML x
            ($ "#wrapper").append scheme
            
            # system menu and dock
            riot.mount ($ "#syspanel", $ "#wrapper")
            riot.mount ($ "#sysdock", $ "#wrapper"), { items: [] }

            # context menu
            riot.mount ($ "#contextmenu")
            ($ "#workspace").contextmenu (e) -> _GUI.bindContextMenu e
            
            # desktop default file manager
            desktop = $ "#desktop"
            desktop[0].fetch = () ->
                fp = _OS.setting.desktop.path.asFileHandler()
                fn = () ->
                    fp.read (d) ->
                        return _courrier.osfail d.error, (_API.throwe "OS.VFS"), d.error if d.error
                        items = []
                        $.each d.result,  (i, v) ->
                            return if v.filename[0] is '.' and  not _OS.setting.desktop.showhidden
                            v.text = v.filename
                            #v.text = v.text.substring(0,9) + "..." ifv.text.length > 10
                            v.iconclass = v.type
                            items.push(v)
                        desktop[0].set "items", items
                        desktop[0].refresh()

                fp.onready () ->
                        fn()
                    , ( e ) -> # try to create the path
                        console.log "#{fp.path} not found"
                        name = fp.basename
                        fp.parent().asFileHandler().mk name, (r) ->
                            ex = _API.throwe "OS.VFS"
                            if r.error then _courrier.osfail d.error, ex, d.error else fn()
                
            desktop[0].ready = (e) ->
                e.observable = _courrier
                window.onresize = () ->
                    _courrier.trigger "desktopresize"
                    e.refresh()

                desktop[0].set "onlistselect", (d) ->
                    ($ "#sysdock").get(0).set "selectedApp", null
            
                desktop[0].set "onlistdbclick", ( d ) ->
                    ($ "#sysdock").get(0).set "selectedApp", null
                    it = desktop[0].get "selected"
                    _GUI.openWith it

                #($ "#workingenv").on "click", (e) ->
                #     desktop[0].set "selected", -1

                desktop.on "click", (e) ->
                    return unless e.target is desktop[0]
                    desktop[0].set "selected", -1
                    ($ "#sysdock").get(0).set "selectedApp", null
                    console.log "desktop clicked"
            
                desktop[0].contextmenuHandler = (e, m) ->
                    desktop[0].set "selected", -1 if e.target is desktop[0]
                    ($ "#sysdock").get(0).set "selectedApp", null
                    console.log "context menu handler for desktop"
                
                desktop[0].fetch()
                _courrier.trigger "desktoploaded"
            # mount it
            riot.mount desktop
        , (e, s) ->
            alert "System fall: Cannot init desktop manager"
            console.log s, e


    buildSystemMenu: () ->
        
        menu =
            text: ""
            iconclass: "fa fa-eercast"
            dataid: "sys-menu-root"
            child: [
                {
                    text: "Application",
                    child: [],
                    dataid: "sys-apps"
                    iconclass: "fa fa-adn",
                    onmenuselect: (d) ->
                        _GUI.launch d.item.data.app
                }
            ]
        menu.child = menu.child.concat _OS.setting.system.menu
        menu.child.push
            text: "Log out",
            dataid: "sys-logout",
            iconclass: "fa fa-user-times"
        menu.onmenuselect = (d) ->
            console.log d
            return _API.handler.logout() if d.item.data.dataid is "sys-logout"
            _GUI.launch d.item.data.app unless d.item.data.dataid
        
        #now get app list
        _API.packages.fetch (r) ->
            if r.result
                v.text = v.name for k, v of r.result
            menu.child[0].child = r.result if r.result
            ($ "[data-id = 'os_menu']", "#syspanel")[0].set "items", [menu]
        #console.log menu
        
        
    login: () ->
        _OS.cleanup()
        _API.resource "schemes/login.html", (x) ->
            return null unless x
            scheme = $.parseHTML x
            ($ "#wrapper").append scheme
            ($ "#btlogin").click () ->
                data =
                    username: ($ "#txtuser").val(),
                    password: ($ "#txtpass").val()
                _API.handler.login data, (d) ->
                    if d.error then ($ "#login_error").html d.error else _GUI.startAntOS d.result
        , (e, s) ->
            alert "System fall: Cannot init login screen"
    
    startAntOS: (conf) ->
        # clean up things
        _OS.cleanup()
        # get setting from conf
        _OS.setting.desktop = conf.desktop if conf.desktop
        _OS.setting.applications = conf.applications if conf.applications
        _OS.setting.appearance = conf.appearance if conf.appearance
        _OS.setting.user = conf.user
        _OS.setting.VFS = conf.VFS if conf.VFS
        _OS.setting.VFS.mountpoints = [
            #TODO: multi app try to write to this object, it neet to be cloned
            { text: "Applications", path: 'app:///', iconclass: "fa  fa-adn", type: "app" },
            { text: "Home", path: 'home:///', iconclass: "fa fa-home", type: "fs" },
            { text: "OS", path: 'os:///', iconclass: "fa fa-inbox", type: "fs" },
            { text: "Desktop", path: 'home:///.desktop', iconclass: "fa fa-desktop", type: "fs" },
        ] if not _OS.setting.VFS.mountpoints

        _OS.setting.system = conf.system if conf.system
        _OS.setting.system.pkgpaths = [
            "home:///.packages",
            "os:///packages"
        ] unless _OS.setting.system.pkgpaths
        _OS.setting.system.menu = [] unless _OS.setting.system.menu
        _OS.setting.desktop.path = "home:///.desktop" unless _OS.setting.desktop.path
        _OS.setting.appearance.theme = "antos" unless _OS.setting.appearance.theme
        # load theme
        _GUI.loadTheme _OS.setting.appearance.theme
        # initDM
        _GUI.initDM()
        _courrier.observable.one "syspanelloaded", () ->
            # TODO load packages list then build system menu
            # push startup services
            # TODO: get services list from user setting
            _GUI.buildSystemMenu()
            _GUI.pushServices [
                "CoreServices/PushNotification",
                "CoreServices/Spotlight",
                "CoreServices/Calendar"
            ]

        # startup application here
        _courrier.observable.one "desktoploaded", () ->
            #_GUI.launch "DummyApp"
            #_GUI.launch "NotePad"