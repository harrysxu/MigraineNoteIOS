#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'migraine_note/migraine_note.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主 target
target = project.targets.find { |t| t.name == 'migraine_note' }

# 获取主 group
main_group = project.main_group.find_subpath('migraine_note', true)

# 1. 添加 Models 文件
models_group = main_group.find_subpath('Models', true)

health_event_file = models_group.new_file('Models/HealthEvent.swift')
timeline_item_file = models_group.new_file('Models/TimelineItem.swift')

target.add_file_references([health_event_file, timeline_item_file])

# 2. 创建 HealthEvent 文件夹并添加视图文件
views_group = main_group.find_subpath('Views', true)
health_event_views_group = views_group.new_group('HealthEvent')

add_health_event_view = health_event_views_group.new_file('Views/HealthEvent/AddHealthEventView.swift')
health_event_detail_view = health_event_views_group.new_file('Views/HealthEvent/HealthEventDetailView.swift')

target.add_file_references([add_health_event_view, health_event_detail_view])

# 3. 添加 Utils 文件
utils_group = main_group.find_subpath('Utils', true)
test_data_file = utils_group.new_file('Utils/HealthEventTestData.swift')

target.add_file_references([test_data_file])

# 保存项目
project.save

puts "✅ 成功添加所有新文件到 Xcode 项目！"
