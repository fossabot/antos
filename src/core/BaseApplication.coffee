self = this
_PM = self.OS.PM
_APP = self.OS.APP
_MAIL = self.OS.courrier
class BaseApplication extends this.OS.GUI.BaseModel
    constructor: (name) ->
        super name

    init: ->
        me = @
        # first register some base event to the app
        
        @on "focus", () ->
            me.sysdock.set "selectedApp", me
            me.appmenu.pid = me.pid
            me.appmenu.set "items", (me.baseMenu() || [])
            me.appmenu.set "onmenuselect", (d) ->
                me.trigger("menuselect", d)
        @on "hide", () ->
            me.sysdock.set "selectedApp", null
            me.appmenu.set "items", []
        @on "menuselect", (d) ->
            switch d.e.item.data.dataid
                when "#{me.name}-about" then alert "About " + me.pid + me.name
                when  "#{me.name}-exit" then me.trigger "exit"
        #now load the scheme
        path = "packages/#{@name}/scheme.html"
        @.render path

    show: () ->
        @trigger "focus"
    
    blur: () ->
        @.appmenu.set "items", [] if @.appmenu and @.pid == @.appmenu.pid
        @trigger "blur"
    
    hide: () ->
        @trigger "hide"
    
    toggle: () ->
        @trigger "toggle"
    
    onexit: (evt) ->
        @cleanup(evt)
        if not evt.prevent
            @.appmenu.set "items", [] if @.pid == @.appmenu.pid
            ($ @scheme).remove()
    
    baseMenu: ->
        mn =
            [{
                text: _APP[@name].meta.name,
                child: [
                    { text: "About", dataid: "#{@name}-about" },
                    { text: "Exit", dataid: "#{@name}-exit" }
                ]
            }]
        mn = mn.concat @menu() || []
        mn
            
    main: ->
        #main program
        # implement by subclasses
    menu: ->
        # implement by subclasses
        # to add menu to application
        []
    open:->
        #implement by subclasses
    data:->
        #implement by subclasses
        # to return app data
    update:->
        #implement by subclasses
    cleanup: (e) ->
        #implement by subclasses
        # to handle the exit event
        # use e.preventDefault() to
        # discard the quit command
BaseApplication.type = 1
this.OS.GUI.BaseApplication = BaseApplication