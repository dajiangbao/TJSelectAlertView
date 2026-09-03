
# TJSelectAlertView
swift选择器：支持一列、两列、三列数据（数据前后关联或者无关联均可）显示，title可配置，显示列数可配置！
<img width="863" height="538" alt="截屏2026-09-03 15 12 46" src="https://github.com/user-attachments/assets/03c81ef7-9dd0-4445-b28a-7854a483e1f5" />


调用方式 ：
 func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

            // 下面 5 个示例任选一个调用即可
//            showSingleColumnIndependent()    // 独立模式-1列
//            showTwoColumnIndependent()       // 独立模式-2列
//            showThreeColumnIndependent()     // 独立模式-3列
//            showTwoColumnLinked()            // 联动模式-2列
            showThreeColumnLinked()          // 联动模式-3列
 }


   // MARK: 1. 独立模式 - 单列
    func showSingleColumnIndependent() {
        let data: [[String]] = [
            ["选项1", "选项2", "选项3", "选项4", "选项5","选项1", "选项2", "选项3", "选项4", "选项5"]
        ]
        let selectView = TJSelectAlertView(mode: .independent(data: data), columnCount: 1)
        selectView.title = "选择类型"
        selectView.confirmBlock = { texts, indexs in
            print("选中：\(texts)，索引：\(indexs)")
            // 业务逻辑处理
        }
        selectView.show()
    }
    
    // MARK: 2. 独立模式 - 两列
    func showTwoColumnIndependent() {
        let data: [[String]] = [
            ["部门A", "部门B", "部门C"],
            ["岗位1", "岗位2", "岗位3", "岗位4"]
        ]
        let selectView = TJSelectAlertView(mode: .independent(data: data), columnCount: 2)
        selectView.title = "选择部门与岗位"
        selectView.confirmBlock = { texts, indexs in
            print("部门：\(texts[0])，岗位：\(texts[1])")
            // 业务逻辑处理
        }
        selectView.show()
    }
    
    // MARK: 3. 独立模式 - 三列
    func showThreeColumnIndependent() {
        let data: [[String]] = [
            ["省份1", "省份2", "省份3"],
            ["城市A", "城市B", "城市C"],
            ["区县X", "区县Y", "区县Z"]
        ]
        let selectView = TJSelectAlertView(mode: .independent(data: data), columnCount: 3)
        selectView.title = "选择地区"
        selectView.confirmBlock = { texts, indexs in
            print("省：\(texts[0])，市：\(texts[1])，区：\(texts[2])")
            // 业务逻辑处理
        }
        selectView.show()
    }
    
    // MARK: 4. 联动模式 - 两列（第二列随第一列变化）
    func showTwoColumnLinked() {
        // 第一列数据
        let level1 = ["北京", "上海", "广东"]
        // 第二列：每个省份对应的城市
        let level2 = [
            ["朝阳区", "海淀区", "丰台区"],
            ["黄浦区", "浦东新区", "静安区"],
            ["广州市", "深圳市", "东莞市"]
        ]
        
        let selectView = TJSelectAlertView(
            mode: .linked(level1: level1, level2: level2, level3: nil),
            columnCount: 2
        )
        selectView.title = "选择省市"
        selectView.confirmBlock = { texts, indexs in
            print("省份：\(texts[0])，城市：\(texts[1])")
            // 业务逻辑处理
        }
        selectView.show()
    }
    
    // MARK: 5. 联动模式 - 三列（省-市-区三级联动）
    func showThreeColumnLinked() {
        // 第一列：省份
        let level1 = ["北京", "广东"]
        // 第二列：每个省份对应的城市
        let level2 = [
            ["北京市"],
            ["广州市", "深圳市"]
        ]
        // 第三列：每个城市对应的区县
        let level3: [[[String]]] = [
            // 北京下的城市对应的区县
            [
                ["朝阳区", "海淀区", "丰台区", "东城区"]
            ],
            // 广东下的城市对应的区县
            [
                ["天河区", "越秀区", "白云区"],    // 广州市
                ["南山区", "福田区", "罗湖区"]     // 深圳市
            ]
        ]
        
        let selectView = TJSelectAlertView(
            mode: .linked(level1: level1, level2: level2, level3: level3),
            columnCount: 3
        )
        selectView.title = "选择省市区"
        selectView.confirmBlock = { texts, indexs in
            print("省：\(texts[0])，市：\(texts[1])，区：\(texts[2])")
            // 业务逻辑处理
        }
        selectView.show()
    }
