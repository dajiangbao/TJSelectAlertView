import UIKit
import SnapKit

// MARK: - 数据模式枚举
enum TJSelectMode {
    /// 各列数据独立，互不影响
    case independent(data: [[String]])
    /// 列间联动模式：下一列数据依赖上一列选中项
    /// - level1: 第一列所有选项
    /// - level2: 第一列每个选项对应的第二列数据（二维数组，count 等于第一列数量）
    /// - level3: 第二列每个选项对应的第三列数据（三维数组，仅三列联动时传入）
    case linked(level1: [String], level2: [[String]], level3: [[[String]]]?)
}

// MARK: - 确认回调：(每列选中的文本, 每列选中的索引)
typealias TJSelectConfirmBlock = ([String], [Int]) -> Void

class TJSelectAlertView: UIView {
    
    // MARK: - 可配置属性
    /// 头部标题
    var title: String = "选项" {
        didSet { titleLabel.text = title }
    }
    /// 确认按钮点击回调
    var confirmBlock: TJSelectConfirmBlock?
    
    // MARK: - 私有属性
    private let mode: TJSelectMode
    private let columnCount: Int
    private var selectedIndexs: [Int] // 记录每一列选中的行索引
    private let rowHeight: CGFloat = 44
    private let pickerHeight: CGFloat = 220 // 5行高度
    
    // MARK: - UI 组件
    private lazy var myMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var topBar: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.setTitleColor(UIColor.hexColor("#666666"), for: .normal)
        btn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let lab = UILabel()
        lab.text = "选项"
        lab.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        lab.textColor = UIColor.hexColor("#333333")
        lab.textAlignment = .center
        return lab
    }()
    
    private lazy var confirmBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("确认", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(UIColor.hexColor("#005BE6"), for: .normal)
        btn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return btn
    }()
    
    /// 固定的选中行背景（居中不动，无滚轮效果）
    private lazy var selectedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.hexColor("#F5F5F5")
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var columnsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 0
        return stack
    }()
    
    private var tableViewArray: [UITableView] = []
    
    // MARK: - 初始化
    init(mode: TJSelectMode, columnCount: Int) {
        self.mode = mode
        self.columnCount = columnCount
        self.selectedIndexs = Array(repeating: 0, count: columnCount)
        super.init(frame: UIScreen.main.bounds)
        setupUI()
        setupTableViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 布局
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(myMaskView)
        addSubview(contentView)
        
        myMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        
        // 顶部操作栏
        contentView.addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(44)
        }
        
        topBar.addSubview(cancelBtn)
        topBar.addSubview(titleLabel)
        topBar.addSubview(confirmBtn)
        
        cancelBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
        }
        
        confirmBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(cancelBtn.snp.right).offset(8)
            make.right.lessThanOrEqualTo(confirmBtn.snp.left).offset(-8)
        }
        
        // ✅ 修复：先添加多列列表容器，完整布局后，再添加选中背景
        contentView.addSubview(columnsStack)
        columnsStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom)
            make.height.equalTo(pickerHeight)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom)
        }
        
        // ✅ 修复：选中背景后添加，插入到列表下层，此时columnsStack已在父视图中，约束可正常激活
        contentView.insertSubview(selectedBackgroundView, belowSubview: columnsStack)
        selectedBackgroundView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(rowHeight)
            make.centerY.equalTo(columnsStack)
        }
    }
    
    private func setupTableViews() {
        let topInset = (pickerHeight - rowHeight) / 2
        
        for index in 0..<columnCount {
            let tableView = UITableView(frame: .zero, style: .plain)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tag = index
            tableView.separatorStyle = .none
            tableView.showsVerticalScrollIndicator = false
            tableView.backgroundColor = .clear
            tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: topInset, right: 0)
            tableView.contentInsetAdjustmentBehavior = .never
            tableView.register(TJSelectCell.self, forCellReuseIdentifier: "TJSelectCell")
            tableViewArray.append(tableView)
            columnsStack.addArrangedSubview(tableView)
        }
    }
    
    // MARK: - 公共方法：弹出显示
    func show() {
        guard let window = UIApplication.shared.keyWindow else { return }
        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutIfNeeded()
        
        // 初始滚动到默认选中行
        for column in 0..<columnCount {
            let indexPath = IndexPath(row: selectedIndexs[column], section: 0)
            tableViewArray[column].scrollToRow(at: indexPath, at: .middle, animated: false)
        }
        
        // 从底部弹出动画
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.myMaskView.alpha = 0.5
            self.contentView.transform = .identity
        }
    }
    
    // MARK: - 私有方法：消失
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.myMaskView.alpha = 0
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentView.bounds.height)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func cancelAction() {
        dismiss()
    }
    
    @objc private func confirmAction() {
        // 收集选中结果
        var selectedTexts: [String] = []
        for column in 0..<columnCount {
            let data = getDataForColumn(column)
            let index = selectedIndexs[column]
            if index < data.count {
                selectedTexts.append(data[index])
            } else {
                selectedTexts.append("")
            }
        }
        confirmBlock?(selectedTexts, selectedIndexs)
        dismiss()
    }
    
    // 获取指定列的数据源
    private func getDataForColumn(_ column: Int) -> [String] {
        switch mode {
        case .independent(let data):
            guard column < data.count else { return [] }
            return data[column]
            
        case .linked(let level1, let level2, let level3):
            switch column {
            case 0:
                return level1
            case 1:
                let index0 = selectedIndexs[0]
                guard index0 < level2.count else { return [] }
                return level2[index0]
            case 2:
                let index0 = selectedIndexs[0]
                let index1 = selectedIndexs[1]
                guard let level3 = level3,
                      index0 < level3.count,
                      index1 < level3[index0].count else { return [] }
                return level3[index0][index1]
            default:
                return []
            }
        }
    }
    
    // 联动模式：刷新当前列之后的所有列，并重置选中项为第0行
    private func reloadLinkedColumns(after column: Int) {
        for nextColumn in (column + 1)..<columnCount {
            selectedIndexs[nextColumn] = 0
            tableViewArray[nextColumn].reloadData()
            // 重置后滚动到第一行居中
            tableViewArray[nextColumn].scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: false)
        }
    }
    
    // 滚动结束后对齐到最近的行
    private func autoAlignScroll(for tableView: UITableView) {
        let column = tableView.tag
        let topInset = (pickerHeight - rowHeight) / 2
        let offsetY = tableView.contentOffset.y + topInset
        let row = Int(round(offsetY / rowHeight))
        let safeRow = max(0, min(row, getDataForColumn(column).count - 1))
        
        selectedIndexs[column] = safeRow
        tableView.reloadData()
        
        // 滚动到对齐位置
        tableView.scrollToRow(at: IndexPath(row: safeRow, section: 0), at: .middle, animated: true)
        
        // 联动模式下刷新后续列
        if case .linked = mode {
            reloadLinkedColumns(after: column)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TJSelectAlertView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getDataForColumn(tableView.tag).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TJSelectCell", for: indexPath) as! TJSelectCell
        let column = tableView.tag
        let text = getDataForColumn(column)[indexPath.row]
        let isSelected = indexPath.row == selectedIndexs[column]
        cell.config(text: text, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let column = tableView.tag
        selectedIndexs[column] = indexPath.row
        tableView.reloadData()
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        // 联动模式下刷新后续列
        if case .linked = mode {
            reloadLinkedColumns(after: column)
        }
    }
}

// MARK: - UIScrollViewDelegate（滚动对齐）
extension TJSelectAlertView: UIScrollViewDelegate {
    // 拖拽结束，即将开始减速
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            guard let tableView = scrollView as? UITableView else { return }
            autoAlignScroll(for: tableView)
        }
    }
    
    // 减速结束，滚动停止
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else { return }
        autoAlignScroll(for: tableView)
    }
}

// MARK: - 自定义选项 Cell
class TJSelectCell: UITableViewCell {
    
    private lazy var titleLabel: UILabel = {
        let lab = UILabel()
        lab.textAlignment = .center
        lab.backgroundColor = .clear
        return lab
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config(text: String, isSelected: Bool) {
        titleLabel.text = text
        if isSelected {
            titleLabel.textColor = UIColor.hexColor("#333333")
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        } else {
            titleLabel.textColor = UIColor.hexColor("#999999")
            titleLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }
}
