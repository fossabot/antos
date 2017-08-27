self.OS.API.handler =
    scandir: (p, c ) ->
        path = "lua-api/fs/scandir"
        _API.post path, { path: p }, c, (e, s) ->
            _courrier.osfail "Fail to make request: #{path}", e, s
    
    auth: (c) ->
        p = "lua-api/system/auth"
        _API.post p, {}, c, () ->
            alert "Resource not found: #{p}"
    login: (d, c) ->
        p = "lua-api/system/login"
        _API.post p, d, c, () ->
            alert "Resource not found: #{p}"
    logout: () ->
        p = "lua-api/system/logout"
        _API.post p, {}, (d) ->
                _OS.boot()
            , () ->
                alert "Resource not found #{p}"
    setting: () ->
        p = "lua-api/system/settings"
        _API.post p, _OS.setting, (d) ->
            _courrier.oserror "Cannot save system setting", d.error if d.error
        , (e, s) ->
            _courrier.osfail "Fail to make request: #{p}", e, s