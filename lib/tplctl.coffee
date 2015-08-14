###
# tpl模板构建和压缩模块
###

fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'
gulp    = require 'gulp'
plumber = require 'gulp-plumber'
gutil   = require 'gulp-util'
color   = gutil.colors
setting = require './setting'
include = require './include'
Tools   = require './Tools'


_staticPath = setting.staticPath
imgReg = /<img[\s\S]*?[^(src)]src=('|")\{\{staticPath\}\}([^'|^"]*)('|")/g
srcReg = /src=('|")([^'|^"]*)('|")/
imgPathReg = '{{staticPath}}/img/'

# 替换html中的图片地址
_replaceImg = (source)->
    imgMap = Tools.getImgMap()
    file_source = source.replace imgReg,(str)->
        return str if str.indexOf('{{staticPath}}') is -1
        map = ''
        # 抓取img的src内容
        str.replace srcReg,(ss)->
            map = ss.replace(/src=/,'')
                    .replace(/(\'|\")|(\'|\"$)/g, '')
        # console.log map
        key = map.replace(imgPathReg, '')
        val = _staticPath + '/img/' + (if _.has(imgMap,key) and setting.env isnt 'dev' then imgMap[key].distname else key + '?t=' + String(new Date().getTime()).substr(0,8))
        setting.env is 'dev' and console.log "#{map}--> #{val}"
        _str = str.replace(map, val)
        return _str
    return  file_source

# 生成模板
_buildHtml = (data)->
    _path = String(data.path).replace(/\\/g,'/')
    return false if _path.indexOf("#{setting.tplPath}_") > -1
    _name = _path.split(setting.tplPath)[1]
    _outPath = path.join(setting.root, setting.tplOutPath, _name)
    _source = String(data.contents)

    # 给html中的图片链接加上Hash
    _source = _replaceImg(_source)

    # 如果不是开发环境，则压缩html
    if setting.env isnt 'dev'
        _source = Tools.htmlMinify(_source)
        gutil.log color.cyan("'#{_name}'"),"combined."

    Tools.mkdirsSync(path.dirname(_outPath))
    fs.writeFileSync(_outPath, _source, 'utf8')

# 模板构建控制器
tplCtl = (file,cb)->
    _hashMaps = Tools.getHashMaps()
    # console.log _hashMaps
    gutil.log color.yellow "Combine html templates..."
    gulp.src(file)
        .pipe plumber({errorHandler: Tools.errHandler})
        .pipe include
            hashmap: _hashMaps
        .on "data",(res)->
            try
                _buildHtml(res)
            catch e
                console.log "#{res.path} Error--->"
                console.log e
        .on "end",->
            gutil.log color.green "Html templates done!"
            cb()

module.exports = tplCtl