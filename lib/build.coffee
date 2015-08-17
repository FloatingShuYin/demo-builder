fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'
gulp    = require 'gulp'
gutil   = require 'gulp-util'
less    = require 'gulp-less'
# mincss  = require 'gulp-minify-css'
plumber = require 'gulp-plumber'
Watch   = require 'gulp-watch'
Server  = require 'gulp-server-livereload'
Buffer  = require('buffer').Buffer
Imagemin = require 'imagemin'
include = require './include'
setting = require './setting'
Tools   = require './Tools'
cssCtl  = require './cssctl'
jsCtl   = require './jsctl'
tplCtl  = require './tplctl'
color   = gutil.colors

# 构建方法
build =
    # project init
    init: ->
        init_paths = [
            setting.distPath
            setting.srcPath
            setting.tplOutPath
            setting.cssPath
            setting.lessPath
            setting.jsPath
            setting.imgPath
            setting.tplPath
            setting.mapPath
        ]
        for dir in init_paths
            Tools.mkdirsSync dir
            gutil.log "#{dir} made success!"
        gutil.log color.green "Project init success!"
        
    # build less to CSS
    less2css: (cb)->
        _lessPath = setting.lessPath
        _file = [
            path.join(_lessPath, '*.less'),
            "!#{path.join(_lessPath, '_*.less')}"
        ]
        gulp.src(_file)
            .pipe plumber({errorHandler: Tools.errrHandler})
            .pipe less
                    compress: false
                    paths: [_lessPath]
            .pipe gulp.dest(setting.cssPath)
            .on 'end',-> 
                cb and cb()
    # build js to dist dir
    img2dist:(cb)->
        Tools.imgHash ->
            cb and cb()

    # build css to dist dir
    css2dist: (file,cb)->
        _file = "#{setting.cssPath}**/*.css"
        if typeof file is 'function'
            _cb = file
        else
            _file = file or _file
            _cb = cb or ->
        cssCtl(_file,_cb)
            
    # build html tpl
    tpl2dist: (file,cb)->
        _file = "#{setting.tplPath}**/*.html"
        if typeof file is 'function'
            _cb = file
        else
            _file = file or _file
            _cb = cb or ->
        tplCtl(_file,_cb)

    # build js to dist dir
    js2dist: (file,cb)->
        _file = "#{setting.jsPath}**/*.js"
        if typeof file is 'function'
            _cb = file
        else
            _file = file or _file
            _cb = cb or ->
        jsCtl(_file,_cb)


    watch: ->
        _this = @
        _list = []
        Watch setting.watchFiles,(file)->
            try
                _event = file.event
                if _event isnt 'undefined'
                    _file_path = file.path.replace(/\\/g,'/')
                    if _file_path not in _list
                        _list.push(_file_path) 
                        gutil.log '\'' + color.cyan(file.relative) + '\'',"was #{_event}"
                        _type = Tools.getType(_file_path)
                        switch _type
                            when 'less'
                                _this.less2css()
                            when 'img'
                                _this.img2dist()
                            when 'css'
                                _this.css2dist(_file_path)
                            when 'js'
                                _this.js2dist(_file_path)
                            when 'tpl'
                                _this.tpl2dist(_file_path)

                # clear watch list after 3 seconds
                clearTimeout watch_timer if watch_timer
                watch_timer = setTimeout ->
                    _list = []
                ,3000
            catch err
                console.log err


    server:->
        appPath = setting.root
        gulp.src(appPath)
            .pipe Server
                livereload: false,
                directoryListing: true,
                open: true
                host: setting.host
                port: setting.port
        

module.exports = build
