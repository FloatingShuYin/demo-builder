fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'
crypto  = require 'crypto'
gulp    = require 'gulp'
gutil   = require 'gulp-util'
rename  = require 'gulp-rename'
plumber = require 'gulp-plumber'
Buffer  = require('buffer').Buffer
Imagemin = require('imagemin')
setting = require './setting'
color   = gutil.colors
hashLength = setting.hashLength
imgMap = {}
_mapPath = setting.mapPath
###
# base functions
###
Tools =
    # md5
    md5: (source) ->
        # 使用二进制转换，解决中文摘要计算不准的问题
        _buf = new Buffer(source)
        _str = _buf.toString "binary"
        crypto.createHash('md5').update(_str).digest('hex')

    # make dir 
    mkdirsSync: (dirpath, mode)->
        if fs.existsSync(dirpath)
            return true
        else
            if Tools.mkdirsSync(path.dirname(dirpath), mode)
                fs.mkdirSync(dirpath, mode)
                return true

    # 错误警报
    errHandler:(e)->
        gutil.beep()
        gutil.beep()
        gutil.log e

    ###
    # obj mixin function
    # Example:
    # food = { 'key': 'apple' }
    # food2 = { 'name': 'banana', 'type': 'fruit' }
    # console.log objMixin(food2,food)
    # console.log objMixin(food,food2)
    ###
    objMixin: _.partialRight _.assign, (a, b) ->
        val = if (typeof a is 'undefined') then b else a
        return val

    # 读取json
    getJSONSync:(file)->
        return JSON.parse fs.readFileSync(file, 'utf8')

    # 获取img的hash
    getImgMap: ->
        _imgMap = {}
        try
            _imgMap = Tools.getJSONSync path.join(_mapPath, setting.imgMap)
        catch e
            # ...
        return _imgMap
        
    # 获取js和css的hash
    getHashMaps: ->
        _cssMap = {}
        _jsMap = {}
        try
            _cssMap = Tools.getJSONSync path.join(_mapPath, setting.cssMap)
            _jsMap = Tools.getJSONSync path.join(_mapPath, setting.jsMap)
        catch e
            # ...
        return Tools.objMixin _cssMap,_jsMap

    # 判断监控文件的类型
    getType:(dir)->
        type = (path.parse(dir).ext).replace('.','')
        if type in ['html','php','ejs']
            type = 'tpl'
        return type

    # 压缩html
    htmlMinify:(source)->
        return source
            .replace(/<!--([\s\S]*?)-->/g, '')
            .replace(/\/\*([\s\S]*?)\*\//g, '')
            .replace(/^\s+$/g, '')
            .replace(/\n/g, '')
            .replace(/\t/g, '')
            .replace(/\r/g, '')
            .replace(/\n\s+/g, ' ')
            .replace(/\s+/g, ' ')
            .replace(/>([\n\s+]*?)</g,'><')
            .replace(/<?phpforeach/g,'<?php foreach')
            .replace(/<?phpecho/g,'<?php echo')  

    # 复制img
    imgCopy:(cb)->
        gulp.src setting.imgPath + '**/*.{gif,jpg,png,svg}'
            .pipe gulp.dest(setting.distPath + 'img')
            .on 'end',->
                gutil.log "Img copy done!"
                cb and cb()

    # 生成图片资源的map
    imgHash:(cb)->
        _map = {}
        _imgSrcPath = path.join setting.root, setting.imgPath
        
        Tools.imgCopy()
        # 递归输出文件的路径Tree和hash
        makePaths = (sup_path)->
            _sup_path = sup_path or _imgSrcPath
            _ext = ['.png','.jpg','.gif']
            fs.readdirSync(_sup_path).forEach (v)->
                sub_Path = path.join(_sup_path, v)
                if fs.statSync(sub_Path).isDirectory()
                    makePaths(sub_Path)
                else if fs.statSync(sub_Path).isFile() and v.indexOf('.') != 0 and path.extname(sub_Path) in _ext
                    _name = sub_Path.replace(_imgSrcPath,'')
                                    .replace(/\\\\/g,'/')
                                    .replace(/\\/g,'/')
                    _this_ext = path.extname(_name)

                    #使用二进制转换
                    _source = String fs.readFileSync(sub_Path, 'utf8')

                    _hash = Tools.md5(_source)

                    _distname = _name.replace(_this_ext,'.') + _hash.substring(0,hashLength) + _this_ext
                    _map[_name] = {}
                    _map[_name].hash = _hash
                    _map[_name].distname = _distname.replace(/\\\\/g,'/')
                                                    .replace(/\\/g,'/')
                    # 优化并生成带MD5戳的新文件
                    _imgmin = new Imagemin()
                        .src(sub_Path)
                        .dest(setting.distPath + 'img')
                        .use(rename(_distname))
                    _imgmin.run (err, files) ->
                            err and throw err
                            # console.log(files[0].path)

        makePaths(_imgSrcPath)
        jsonData = JSON.stringify _map, null, 2

        #更新imgMap
        not fs.existsSync(_mapPath) and butil.mkdirsSync(_mapPath)
        fs.writeFileSync path.join(_mapPath, setting.imgMap), jsonData, 'utf8'
        gutil.log color.green "#{setting.imgMap} build success"
        
        cb and cb()
module.exports = Tools