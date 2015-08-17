###
# v.build config
# @date 2014-12-2 15:10:14
# @author pjg <iampjg@gmail.com>
# @link http://pjg.pw
# @version $Id$
###

path  = require 'path'
cfg   = require '../config.json'
args  = require('yargs').argv

_root = process.env.INIT_CWD
# 四个环境：dev开发 test测试 pre预生产 www生产
# 默认是dev环境
_env = (args.e or args.env) ? 'dev'


# 前端资源的源码目录名
_srcName = cfg.srcPathName

# 前端资源的生产目录名
_distName = cfg.distPathName

# 前端资源的生产目录名
_tplOutName = cfg.tplOutName

# 静态域名
_host = 'localhost'
_port = 8800
_cdnDomain = if _env isnt 'dev' then cfg.envs[_env].cdnDomain else "#{_host}:#{_port}"
_staticPath = "//#{_cdnDomain}/" + if _env isnt 'dev' then "#{_distName}" else "#{_srcName}"

module.exports =
  root: _root
  # 开发环境相关参数
  env: _env 
  host: _host
  port: _port
  cdnDomain: _cdnDomain
  staticPath: _staticPath

  # md5 hash长度
  hashLength: cfg.hashLength

  # 生产目录
  tplOutPath: "#{_tplOutName}/"
  distPath: "#{_distName}/"
  mapPath: "#{_distName}/map/"
  
  # 源码目录
  srcPath: "#{_srcName}/"
  jsPath: "#{_srcName}/js/"
  lessPath: "#{_srcName}/less/"
  cssPath: "#{_srcName}/css/"
  tplPath: "#{_srcName}/html/"
  imgPath: "#{_srcName}/img/"

  # map
  cssMap: "cssmap.json"
  imgMap: "imgmap.json"
  jsMap: "jsmap.json"
  
  # 监控的文件
  watchFiles: [
      "#{_srcName}/less/**/*.less"
      "#{_srcName}/img/**/*.{png,jpg,gif}"
      "#{_srcName}/html/**/*.{html,php,ejs}"
      "#{_srcName}/js/**/*.js"
      "!.DS_Store"
    ]
