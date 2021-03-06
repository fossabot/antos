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
self.OS.API.HOST = self.location.hostname+ (if self.location.port then":#{self.location.port}" else "")
self.OS.API.REST = "#{self.location.protocol}//#{self.OS.API.HOST}/lua-api/os"

_REST = self.OS.API.REST
self.OS.API.handler =
    # get file, require authentification
    get: "#{_REST}/fs/get"
    # get shared file with publish
    shared: "#{_REST}/fs/shared"
    scandir: (p, c ) ->
        path = "#{_REST}/fs/scandir"
        _API.post path, { path: p }, c, (e, s) ->
            _courrier.osfail __("Fail to scan directory: {0}", p), e, s
    mkdir: (p, c ) ->
        path = "#{_REST}/fs/mkdir"
        _API.post path, { path: p }, c, (e, s) ->
            _courrier.osfail __("Fail to create directory: {0}", p), e, s
    sharefile: (p, pub , c) ->
        path = "#{_REST}/fs/publish"
        _API.post path, { path: p , publish: pub }, c, (e, s) ->
            _courrier.osfail __("Fail to publish file: {0}", p), e, s

    fileinfo: (p, c) ->
        path = "#{_REST}/fs/fileinfo"
        _API.post path, { path: p }, c, (e, s) ->
            _courrier.osfail __("Fail to get file meta data: {0}", p), e, s

    readfile: (p, c, t) ->
        path = "#{_REST}/fs/get/"
        _API.get path + p, c, (e, s) ->
            _courrier.osfail __("Fail to read file: {0}", p), e, s
        , t

    move: (s, d, c) ->
        path = "#{_REST}/fs/move"
        _API.post path, { src: s, dest: d }, c, (e, s) ->
            _courrier.osfail __("Fail to move file: {0} -> {1}", s, d), e, s

    delete: (p , c) ->
        path = "#{_REST}/fs/delete"
        _API.post path, { path: p }, c, (e, s) ->
            _courrier.osfail __("Fail to delete: {0}", p), e, s

    fileblob: (p, c) ->
        path = "#{_REST}/fs/get/"
        _API.blob path + p, c, (e, s)  ->
            _courrier.osfail "Fail to read file: #{p}", e, s

    packages: (d, c) ->
        path = "#{_REST}/system/packages"
        _API.post path, d, c, (e, s) ->
            _courrier.osfail __("Fail to {0} package", d.command), e, s

    upload: (d, c) ->
        path = "#{_REST}/fs/upload"
        _API.upload path, d, c, (e, s) ->
            _courrier.osfail __("Fail to upload file to: {0}", d), e, s

    write: (p, d , c) ->
        path = "#{_REST}/fs/write"
        _API.post path, { path: p, data: d }, c, (e, s) ->
            _courrier.osfail __("Fail to write to file: {0}", p), e, s

    scanapp: (p, c ) ->
        path = "#{_REST}/system/application"
    auth: (c) ->
        p = "#{_REST}/system/auth"
        _API.post p, {}, c, (e, s) ->
            console.log e, s
            alert __("Resource not found: {0}", p)
    login: (d, c) ->
        p = "#{_REST}/system/login"
        _API.post p, d, c, () ->
            alert __("Resource not found: {0}", p)
    logout: () ->
        p = "#{_REST}/system/logout"
        _API.post p, {}, (d) ->
            _OS.boot()
        , () ->
            alert __("Resource not found: {0}", p)
    setting: (f) ->
        p = "#{_REST}/system/settings"
        _API.post p, _OS.setting, (d) ->
            _courrier.oserror __("Cannot save system setting"), d.error if d.error
            f(d) if f
        , (e, s) ->
            m = __("Fail to make request: {0}", p)
            _courrier.osfail m , e, s
            f({ error: m }) if f
    
    dbquery: (cmd, d, c) ->
        path = "#{_REST}/db/#{cmd}"
        _API.post path, d, c, (e, s) ->
            _courrier.osfail __("Fail to query data from database: {0}", path), e, s