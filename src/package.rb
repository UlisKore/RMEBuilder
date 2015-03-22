# -*- coding: utf-8 -*-
=begin
RMEBuilder - Package
Copyright (C) 2015 Nuki <xaviervdw AT gmail DOT com>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
=end

Utils.define_exception :UnboundPackage

module Packages
  attr_accessor :locals, :all
  Packages.locals =
    (File.exist?(REP_TRACE)) ? (FileTools.eval_file(REP_TRACE)) : {}

  def exist?(name)
    list.has_key?(name)
  end

  def map
    list =
      Packages.list.map do |name, url|
        args    = url.split('/')
        schema  = args.pop
        uri     = args.join('/')
        [name, {uri: Http.service_with(uri), schema: schema}]
      end
    Packages.all = Hash[list]
  end
  map

end


class Package

  class << self

    def exist?(name)
      Packages.exist?(name)
    end

    def download(name, target = REP_PATH, update = false)
      raise UnboundPackage unless exist?(name)
      package = Packages.all[name]
      puts "Download #{name}"
      Console.refutable "From #{Packages.list[name]}"
      FileTools.safe_mkdir(target)
      target = target.addSlash + name.addSlash
      if update
        Console.warning "Suppress #{target} for redownload"
        FileTools.safe_rmdir(target)
      else
        if Dir.exist?(target)
          Console.alert "#{target} already exist"
          return
        end
      end
      Console.success "Create #{target}"
      Dir.mkdir(target)
      uri = package[:uri].clone
      uri << package[:schema]
      schema_content = uri.get
      FileTools.write(target + package[:schema], schema_content, 'w')
      Console.success "Schema is downloaded"
    end

  end

  attr_accessor :name
  attr_accessor :version
  attr_accessor :components
  attr_accessor :dependancies
  attr_accessor :exclude
  attr_accessor :description
  attr_accessor :authors
  attr_accessor :uri
  attr_accessor :schema

  def initialize(hash)
    @name         = hash[:name]
    @version      = hash[:version]      || vsn
    @components   = hash[:components]   || {}
    @dependancies = hash[:dependancies] || {}
    @exclude      = hash[:exclude]      || []
    @authors      = hash[:authors]      || {}
    @description  = hash[:description]  || ""
  end

  def serialize
    "Package.new(name:#{@name}, version:#{@version}," +
    " dependancies:#{@dependancies}, authors: #{@authors}," +
    "description: #{@description})"
  end
end

module Kernel


  def add_package(name, schema='package.rb')
    if Package.local_package?(name)
      Package.add_local(name, schema)
    else
      Package.add_distant(name)
    end
  end

end
