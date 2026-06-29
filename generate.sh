#!/bin/bash

rm -rf ./data && mkdir -p ./data

awk '
BEGIN {
    # ================= 配置区 =================
    # 1. 完全排除的大分类
    exclude_names["China"] = 1
    
    # 2. 完全排除的具体服务
    exclude_services["Google Search"] = 1
    
    # 3. 需要自立门户、独立导出为文件的服务名
    standalone_services["Youtube"] = 1
    standalone_services["Instagram"] = 1
    standalone_services["Steam Store"] = 1
    
    # 4. 【新增】国家/地区名字简化映射表 (在这里添加你的缩写规则)
    alias_map["Taiwan"] = "TW"
    alias_map["Japan"] = "JP"
    alias_map["Canada"] = "CA"
    alias_map["Europe"] = "EU"
    alias_map["Korean"] = "KR"
    alias_map["Indian"] = "IN"
    alias_map["Hong Kong"] = "HK"
    alias_map["South America"] = "SA"
    alias_map["North America"] = "NA"
    alias_map["SouthEastAsia"] = "SEA"
    alias_map["Steam Store"] = "Steam"
    alias_map["Setanta Sports"] = "Setanta"

    # 5. 文件名杂质剔除正则
    noise_pattern = "media|Media|Platform|Plaform"
    # ==========================================
    
    current_category = ""
    current_service = ""
}

# 1. 捕捉大分类头部
/[ \t]*# ---------- > / {
    raw = $0
    sub(/^[ \t]*# ---------- > /, "", raw)
    gsub(noise_pattern, "", raw)
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", raw) # 强力 trim
    
    current_category = raw
    next
}

# 2. 捕捉服务头部
/[ \t]*# > / {
    if ($0 ~ /----------/) next

    raw = $0
    sub(/^[ \t]*# > /, "", raw)
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", raw) # 强力 trim
    current_service = raw

    if (current_category == "?") {
        current_category = current_service
    }
    next
}

# 3. 捕捉数据行、过滤并导出
/^[ \t]*~\^/ || /~\^/ {
    # 拦截过滤
    if (current_category in exclude_names) next
    if (current_service in exclude_services) next
    if (current_category == "" || current_service == "") next

    # 路由决策
    if (current_service in standalone_services) {
        if (current_service in alias_map) {
            target_file = alias_map[current_service]
        } else {
            target_file = current_service
        }
    } else {
        # 【核心修正】检查当前大分类是否有缩写别名
        if (current_category in alias_map) {
            target_file = alias_map[current_category]  # 使用缩写如 TW, JP
        } else {
            target_file = current_category             # 没找到缩写则沿用原名
        }
    }

    # 数据清洗
    cleaned = $0
    gsub(/~\^\(.*\|\)/, "", cleaned)
    gsub(/\\./, ".", cleaned)
    gsub(/\$;/, "", cleaned)

    # 写入文件
    print cleaned >> ("./data/" target_file)
}
' stream.list
