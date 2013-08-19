/*global module:false*/
module.exports = function(grunt) {

    grunt.initConfig({
        clean:[
            "source/public/css",
            "source/public/js",
            "source/public/img/UI",
            "source/public/img/language",
            "source/public/img/bootstrap-colorpicker"            
        ],
        less: {
            production: {
                options: {
                    paths: ["source/client/static/less"]
                },
                files: {
                    "source/client/static/css/app.css": "source/client/static/less/app.less",
                    "source/client/static/css/admin.css": "source/client/static/less/admin.less"
                }
            }
        },
        cssmin: {
            compress: {
                files: {
                    "source/public/css/app.min.css": [
                        "source/client/static/css/bootstrap.min.css", "source/client/static/css/typicons.css",
                        "source/client/static/css/app.css"
                    ],
                    "source/public/css/admin.min.css": [
                        "source/client/static/css/bootstrap.min.css", "source/client/static/css/bootstrap-responsive.min.css",
                        "source/client/static/css/bootstrap-colorpicker.css", "source/client/static/css/admin.css"
                    ]
                }
            }
        },
        coffee : {
            compile: {
                options: {
                    bare: true,
                    separator: "\n\n/*=========================================================*/\n/*=========================================================*/\n"
                },
                files : {
                    'source/client/static/js/app.body.js':["source/client/models/*.coffee", "source/client/collections/*.coffee",
                        "source/client/views/**/**.coffee", "source/client/app.coffee"
                    ],
                    'source/client/static/js/admin.body.js':["source/client/admin.coffee"]                   
                }
            }
        },
        uglify : {
            head : {
                files : {
                    "source/public/js/app.head.js" : [
                        "source/client/static/js/jquery-1.9.1.min.js", "source/client/static/js/jquery.cookie.js",
                        "source/client/static/js/underscore.js", "source/client/static/js/backbone.js",
                        "source/client/static/js/infiniScroll.js", "source/client/static/js/doT.min.js",
                        "source/client/static/js/swfobject.js"
                    ]
                }
            },
            admin : {
                files : {
                    "source/public/js/admin.body.js" : [
                        "source/client/static/js/bootstrap.min.js", "source/client/static/js/bootstrap-colorpicker.js",
                        "source/client/static/js/admin.body.js"
                    ]
                }
            },
            app : {
                files : {
                    "source/public/js/app.body.js" : [
                        "source/client/static/js/bootstrap.min.js", "source/client/static/js/app.body.js"
                    ]
                }
            }
        },
        concat : {
            head : {
                src :[
                    "source/client/static/js/jquery-1.9.1.min.js", "source/client/static/js/jquery.cookie.js",
                    "source/client/static/js/underscore.js", "source/client/static/js/backbone.js",
                    "source/client/static/js/infiniScroll.js", "source/client/static/js/doT.min.js",
                    "source/client/static/js/swfobject.js"
                ],
                dest: "source/public/js/app.head.js"
            },
            admin : {
                src : [
                    "source/client/static/js/bootstrap.min.js", "source/client/static/js/bootstrap-colorpicker.js",
                    "source/client/static/js/admin.body.js"
                ],
                dest: "source/public/js/admin.body.js"
            },
            app : {
                src : ["source/client/static/js/bootstrap.min.js", "source/client/static/js/app.body.js"],
                dest: "source/public/js/app.body.js"
            }
        },
        copy: {
            main: {
                files: [
                    {expand: true, cwd: 'source/client/static/img/',
                        src: ['UI/*', 'language/*', 'bootstrap-colorpicker/*'], dest: 'source/public/img/'}
                ]
            }
        },
        rev: {
            options: {
                algorithm: 'md5',
                length: 32
            },
            assets: {
                files: {
                    src: ['source/public/js/*.*', 'source/public/css/*.*',
                        'source/public/img/UI/*.*', 'source/public/img/language/*.*']
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-rev');

    grunt.registerTask('default', ['clean', 'less', 'cssmin', 'coffee', 'uglify', 'copy', 'rev']);
    grunt.registerTask('dev', ['clean', 'less', 'cssmin', 'coffee', 'concat', 'copy', 'rev']);
};


