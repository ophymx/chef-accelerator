#!/usr/bin/env ruby
require 'yaml'
require 'json'

yaml_file = ARGV.fetch(0)
json_file = ARGV.fetch(1)

node = YAML.load_file(yaml_file)
recipes = node.delete('recipes')
node[:run_list] = recipes.map { |r| "recipe[#{r}]" }
File.write(json_file, JSON.dump(node))  
