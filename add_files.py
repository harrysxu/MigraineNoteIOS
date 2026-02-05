#!/usr/bin/env python3
import os
import uuid
import re

# Xcode 项目文件路径
pbxproj_path = 'migraine_note/migraine_note.xcodeproj/project.pbxproj'

# 读取项目文件
with open(pbxproj_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 要添加的文件列表
files_to_add = [
    ('Models/HealthEvent.swift', 'Models'),
    ('Models/TimelineItem.swift', 'Models'),
    ('Views/HealthEvent/AddHealthEventView.swift', 'HealthEvent'),
    ('Views/HealthEvent/HealthEventDetailView.swift', 'HealthEvent'),
    ('Utils/HealthEventTestData.swift', 'Utils'),
]

# 生成 UUID (Xcode 使用24字符的hex字符串)
def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

# 查找已存在的文件引用，确保不重复添加
existing_files = re.findall(r'path = ([^;]+\.swift);', content)

# 查找 PBXBuildFile section
build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
if not build_file_section:
    print("❌ 找不到 PBXBuildFile section")
    exit(1)

# 查找 PBXFileReference section
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
if not file_ref_section:
    print("❌ 找不到 PBXFileReference section")
    exit(1)

# 查找 PBXSourcesBuildPhase section
sources_phase_section = re.search(r'/\* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/', content, re.DOTALL)
if not sources_phase_section:
    print("❌ 找不到 PBXSourcesBuildPhase section")
    exit(1)

# 提取 Sources build phase 的 files 数组
sources_files_match = re.search(r'([\dA-F]+) /\* Sources \*/ = \{[^}]*files = \((.*?)\);', sources_phase_section.group(0), re.DOTALL)
if not sources_files_match:
    print("❌ 找不到 Sources files 数组")
    exit(1)

build_file_entries = []
file_ref_entries = []
sources_entries = []

for file_path, group_name in files_to_add:
    filename = os.path.basename(file_path)
    
    # 检查文件是否已存在
    if filename in str(existing_files):
        print(f"⚠️  {filename} 已存在，跳过")
        continue
    
    # 生成 UUIDs
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    # PBXBuildFile 条目
    build_file_entry = f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"
    build_file_entries.append(build_file_entry)
    
    # PBXFileReference 条目
    file_ref_entry = f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
    file_ref_entries.append(file_ref_entry)
    
    # Sources build phase 条目
    sources_entry = f"\t\t\t\t{build_file_uuid} /* {filename} in Sources */,"
    sources_entries.append(sources_entry)
    
    print(f"✅ 添加 {filename}")

if not build_file_entries:
    print("所有文件都已存在，无需添加")
    exit(0)

# 插入 PBXBuildFile 条目
build_file_insert_pos = content.find('/* End PBXBuildFile section */')
content = content[:build_file_insert_pos] + '\n'.join(build_file_entries) + '\n' + content[build_file_insert_pos:]

# 插入 PBXFileReference 条目
file_ref_insert_pos = content.find('/* End PBXFileReference section */')
content = content[:file_ref_insert_pos] + '\n'.join(file_ref_entries) + '\n' + content[file_ref_insert_pos:]

# 插入 Sources 条目
sources_files_end = sources_files_match.end(2)
# 需要在原始内容中找到这个位置
pattern = re.escape(sources_files_match.group(2)[:50])
match = re.search(pattern, content)
if match:
    # 找到 files 数组的结束位置
    array_end = content.find(');', match.start())
    content = content[:array_end] + '\n' + '\n'.join(sources_entries) + '\n\t\t\t' + content[array_end:]

# 写回文件
with open(pbxproj_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\n✅ 成功添加 {len(build_file_entries)} 个文件到 Xcode 项目！")
print("请重新打开 Xcode 项目以查看更改。")
