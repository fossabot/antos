<afx-list-view class = {dropdown: opts.dropdown == "true"} style = "display:flex; flex-direction:column">
    <div class = "list-container" ref = "container" style="flex:1;">
        <div if = {opts.dropdown == "true"} ref = "current"  onclick = {show_list}>
            <afx-label ref = "drlabel"></afx-label>
        </div>
        <ul  ref = "mlist" >
            <li each={item,i in items } class={selected: parent._autoselect(item,i)} ondblclick = {parent._dbclick}  onclick = {parent._select} oncontextmenu = {parent._select}>
                <afx-label class = {item.class} color = {item.color} iconclass = {item.iconclass} icon = {item.icon} text = {item.text}></afx-label>
                <i if = {item.closable} class = "closable" click = {parent._remove}></i>
                <ul if = {item.complex} class = "complex-content">
                    <li each = {ctn,j in item.detail} class = {ctn.class}>{ctn.text.toString()}</li>
                </ul>
            </li>
        </ul>
    </div>
    <div if = {opts.dropdown != "true" && buttons} class = "button_container">
        <afx-button each = {btn,i in buttons} text = {btn.text} icon = {btn.icon} iconclass = {btn.iconclass} onbtclick = {btn.onbtclick}></afx-button>
    </div>
    <script>
        this.items = opts.items || []
        var self = this
        self.selidx = -1
        self.onlistselect = opts.onlistselect
        self.onlistdbclick = opts.onlistdbclick
        self.onitemclose = opts.onitemclose
        self.buttons = opts.buttons
        var onclose = false
        this.rid = $(self.root).attr("data-id") || Math.floor(Math.random() * 100000) + 1
        self.root.set = function(k,v)
        {
            if(k == "selected")
            {
                if(self.selidx != -1)
                    self.items[self.selidx].selected =false
                if(v == -1)
                    self.selidx = -1
                else
                    if(self.items[v]) self.items[v].selected = true
            }
            else if(k == "*")
                for(var i in v)
                    self[i] = v[i]
            else
                self[k] = v
            self.update()
        }
        self.root.get = function(k)
        {
            if(k == "selected")
                if(self.selidx != -1)
                    return self.items[self.selidx]
                else
                    return undefined
            else if(k == "count")
                return self.items.length
            return self[k]
        }
        self.root.selectNext = function()
        {
            var idx = self.selidx + 1
            if(idx >= self.items.length) return;
            if(self.selidx != -1)
                self.items[self.selidx].selected =false
            self.items[idx].selected =true
            self.update()
        }
        self.root.selectPrev = function()
        {
            var idx = self.selidx - 1
            if(idx < 0) return;
            if(self.selidx != -1)
                self.items[self.selidx].selected =false
            self.items[idx].selected =true
            self.update()
        }
        self.root.push = function(e,u)
        {
            self.items.push(e)
            if(u) self.update()
        }
        self.root.unshift = function(e,u)
        {
            self.items.unshift(e)
            if(u) self.update()
        }
        self.root.replaceItem = function(o, n, u)
        {
            var ix = self.items.indexOf(o)
            if(ix >= 0)
            {
                self.items[ix] = n
                if(u) self.update()
            }
            
        }
        self.root.remove = function(e,u)
        {
            var i = self.items.indexOf(e)
            if(i >= 0)
            {
                if(self.selidx != -1)
                {
                    self.items[self.selidx].selected =false
                    self.selidx = -1
                }
                self.items.splice(i, 1)
                if(u)
                    self.update()
                onclose = true
            }
        }
        if(opts.observable)
            this.root.observable = opts.observable
        else
        {
            this.root.observable = riot.observable()
        }
        
        this.on("mount", function(){
            self.root.observable = opts.observable || (self.parent && self.parent.root && self.parent.root.observable) || riot.observable()
            
            if(opts.dropdown == "true")
            {
                var cl = function()
                {
                    $(self.refs.container).css("width", $(self.root).width() + "px" )
                    $(self.refs.current).css("width", $(self.root).width() + "px" )
                    $(self.refs.mlist).css("width", $(self.root).width() + "px" )
                }
                cl()
                self.root.observable.on("calibrate", function(){
                    cl()
                })
                self.root.observable.on("resize", function(){
                    cl()
                })
                $(document).click(function(event) { 
                    if(!$(event.target).closest(self.refs.container).length) {
                        $(self.refs.mlist).hide()
                    }
                })
                //$(self.root).css("position","relative")
                $(self.refs.container)
                        .css("position","absolute")
                        .css("display","inline-block")
                        
                $(self.refs.mlist)
                    .css("position","absolute")
                    .css("display","none")
                    .css("top","100%")
                    .css("left","0")
                
                self.root.observable.on("vboxchange", function(e){
                   if(e.id == self.parent.rid)
                        $(self.refs.container).css("width", $(self.root).parent().innerWidth() + "px" )
                })
            }
        })
        show_list(event)
        {
            var desktoph = $("#desktop").height()
            var off = $(self.root).offset().top + $(self.refs.mlist).height()
            if( off > desktoph )
                $(self.refs.mlist)
                    .css("top","-" +  $(self.refs.mlist).outerHeight() + "px")
            else 
                $(self.refs.mlist).css("top","100%")
            $(self.refs.mlist).show()
            //event.preventDefault()
            event.preventUpdate = true
        }
        _remove(event)
        {
            r = true
            if(self.onitemclose)
                r = self.onitemclose(event)
            if(r)
                self.root.remove(event.item.item, true)
        }
        _autoselect(it,i)
        {
            if(!it.selected || it.selected == false) return false
            if(self.selidx == i) return true 
            var data = {
                    id:self.rid, 
                    data:it, 
                    idx:i}
            //if(self.selidx != -1)
             //   self.items[self.selidx].selected =false
            self.selidx = i
            if(opts.dropdown  == "true")
            {
                $(self.refs.mlist).hide()

                self.refs.drlabel.root.set("*",it)
            }
            
            if(self.onlistselect)
                self.onlistselect(data)
            this.root.observable.trigger('listselect',data)
            //console.log("list select")
            return true
        }
        _select(event)
        {
            if(onclose)
            {
                onclose = false
                event.preventUpdate = true
                return
            }
            if(self.selidx != -1 && self.selidx < self.items.length)
                self.items[self.selidx].selected =false
            event.item.item.selected = true
        }
        _dbclick(event)
        {
            data =  {
                    id:self.rid, 
                    data:event.item.item,
                    idx: event.item.i}
            if(self.onlistdbclick)
                self.onlistdbclick(data)
            self.root.observable.trigger('listdbclick', data)
        }
    </script>
</afx-list-view>