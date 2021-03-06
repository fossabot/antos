<afx-sys-panel>
    <div>
        <afx-menu data-id = "os_menu" ref = "aOsmenu" child={osmenu.child} onmenuselect = {osmenu.onmenuselect} class="afx-panel-os-menu"></afx-menu>
        <afx-menu data-id = "appmenu" ref = "aAppmenu" child={appmenu.child}  class = "afx-panel-os-app"></afx-menu>
        <afx-menu data-id = "sys_tray" ref = "aTray" child={systray.child} onmenuselect = {systray.onmenuselect} class = "afx-panel-os-stray"></afx-menu>
    </div>
    
    <script>
        this.osmenu = { child: [] }
        this.appmenu = { child: [] }
        this.systray = { 
            child: [], 
            onmenuselect: function(d){
                if(d.root)
                    d.e.item.data.awake(d.e)
            }
        }

        var self = this
        self.root.attachservice = function(s)
        {
            self.refs.aTray.root.unshift(s,true)
            s.attach(self.refs.aTray)
        }
        self.root.detachservice = function(s)
        {
            self.refs.aTray.root.remove(s, true)
        }
        self.root.set = function(k,v)
        {
            if(k == "*")
                for(var i in v)
                    self[i] = v[i]
            else
                self[k] = v
            self.update()
        }
        self.root.get = function(k)
        {
            return self[k]
        }
        self.root.update = function()
        {
            self.update()
        }
        this.on('mount', function() {
            //console.log(self.refs.aOsmenu.root)
            $(self.refs.aOsmenu.root).css("z-index",1000000)
            $(self.refs.aAppmenu.root).css("z-index",1000000)
            $(self.refs.aTray.root).css("z-index",1000000)
            window.OS.courrier.trigger("syspanelloaded")
        })
    </script>
</afx-sys-panel>