//
//  ViewController.swift
//  NeonApp
//
//  Created by Hamza Ibrahim on 15/02/2026.
//

import UIKit

class ViewController: UIViewController, UITabBarDelegate, UITextFieldDelegate {

    // MARK: - To-Do List Offline State & Models
    struct TodoItemData: Codable {
        var id: String
        var title: String
        var isCompleted: Bool
        var priority: String // "low", "medium", "high"
        var category: String // "Work", "Personal", "Study", "Shopping", "Health"
        var createdAt: Double = Date().timeIntervalSince1970 * 1000
    }

    private var todoTasks: [TodoItemData] = []
    private var newTaskTitle: String = ""
    private var selectedPriority: String = "medium"
    private var selectedCategory: String = "Work"
    private var filterStatus: String = "all" // "all", "active", "completed"
    private var activeCategoryFilter: String = "All"
    private let categories = ["Work", "Personal", "Study", "Shopping", "Health"]
    private let useRemoteServer = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0xF1/255.0, green: 0xF5/255.0, blue: 0xF9/255.0, alpha: 1.0)
        
        loadLocalTasks()
        
        if useRemoteServer {
            let loadingLabel = UILabel()
            loadingLabel.text = "Connecting to Neon Engine..."
            loadingLabel.textAlignment = .center
            loadingLabel.frame = view.bounds
            view.addSubview(loadingLabel)
            fetchUiTree()
        } else {
            renderLocalTree()
        }
    }

    private func loadLocalTasks() {
        if let data = UserDefaults.standard.data(forKey: "neon_todo_tasks"),
           let decoded = try? JSONDecoder().decode([TodoItemData].self, from: data),
           !decoded.isEmpty {
            self.todoTasks = decoded
            return
        }
        self.todoTasks = [
            TodoItemData(id: "task_1", title: "Explore Neon Framework architecture", isCompleted: true, priority: "high", category: "Work"),
            TodoItemData(id: "task_2", title: "Build custom mobile app with Neon SDK", isCompleted: false, priority: "high", category: "Work"),
            TodoItemData(id: "task_3", title: "Design native iOS bridge and UI tree", isCompleted: false, priority: "medium", category: "Study"),
            TodoItemData(id: "task_4", title: "Review local storage & networking layers", isCompleted: false, priority: "low", category: "Personal")
        ]
    }

    private func saveLocalTasks() {
        if let encoded = try? JSONEncoder().encode(todoTasks) {
            UserDefaults.standard.set(encoded, forKey: "neon_todo_tasks")
        }
    }

    private func renderLocalTree() {
        let tree = buildTodoTree()
        view.subviews.forEach { $0.removeFromSuperview() }
        let rootView = renderWidget(node: tree)
        rootView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootView)
        NSLayoutConstraint.activate([
            rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func handleLocalAction(id: String, value: Any? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if id == "btn_submit_task" {
                let title = self.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    let newTask = TodoItemData(
                        id: "task_\(Int(Date().timeIntervalSince1970 * 1000))",
                        title: title,
                        isCompleted: false,
                        priority: self.selectedPriority,
                        category: self.selectedCategory,
                        createdAt: Date().timeIntervalSince1970 * 1000
                    )
                    self.todoTasks.insert(newTask, at: 0)
                    self.newTaskTitle = ""
                    self.saveLocalTasks()
                }
            } else if id == "tf_new_task" {
                self.newTaskTitle = (value as? String) ?? ""
                return
            } else if id.hasPrefix("cb_task_") {
                let taskId = String(id.dropFirst("cb_task_".count))
                if let index = self.todoTasks.firstIndex(where: { $0.id == taskId }) {
                    if let boolVal = value as? Bool {
                        self.todoTasks[index].isCompleted = boolVal
                    } else {
                        self.todoTasks[index].isCompleted.toggle()
                    }
                    self.saveLocalTasks()
                }
            } else if id.hasPrefix("btn_del_") {
                let taskId = String(id.dropFirst("btn_del_".count))
                self.todoTasks.removeAll { $0.id == taskId }
                self.saveLocalTasks()
            } else if id == "btn_clear_completed_tasks" {
                self.todoTasks.removeAll { $0.isCompleted }
                self.saveLocalTasks()
            } else if id == "btn_toggle_all_tasks" {
                let hasUncompleted = self.todoTasks.contains { !$0.isCompleted }
                for i in 0..<self.todoTasks.count {
                    self.todoTasks[i].isCompleted = hasUncompleted
                }
                self.saveLocalTasks()
            } else if id == "chip_prio_low" {
                self.selectedPriority = "low"
            } else if id == "chip_prio_med" {
                self.selectedPriority = "medium"
            } else if id == "chip_prio_high" {
                self.selectedPriority = "high"
            } else if id.hasPrefix("chip_cat_") {
                self.selectedCategory = String(id.dropFirst("chip_cat_".count))
            } else if id == "filter_status_all" {
                self.filterStatus = "all"
            } else if id == "filter_status_active" {
                self.filterStatus = "active"
            } else if id == "filter_status_done" {
                self.filterStatus = "completed"
            } else if id == "filter_cat_all" {
                self.activeCategoryFilter = "All"
            } else if id.hasPrefix("filter_cat_") {
                self.activeCategoryFilter = String(id.dropFirst("filter_cat_".count))
            }
            
            self.renderLocalTree()
        }
    }

    private func buildTodoTree() -> [String: Any] {
        let totalCount = todoTasks.count
        let completedCount = todoTasks.filter { $0.isCompleted }.count
        let activeCount = totalCount - completedCount
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
        let percentInt = Int(progress * 100)

        let filteredList = todoTasks.filter { task in
            if filterStatus == "active" && task.isCompleted { return false }
            if filterStatus == "completed" && !task.isCompleted { return false }
            if activeCategoryFilter != "All" && task.category != activeCategoryFilter { return false }
            return true
        }

        var rootItems: [[String: Any]] = []

        // 1. Header Card with App Title & Stats
        var headerItems: [[String: Any]] = []
        let titleRow: [String: Any] = [
            "id": "header_title_row",
            "type": "Row",
            "spacing": 8.0,
            "children": [
                [
                    "type": "Text",
                    "text": "Neon Task Studio",
                    "fontSize": 24.0,
                    "fontWeight": "bold",
                    "color": 0xFFFFFFFF
                ],
                [
                    "type": "Spacer"
                ],
                [
                    "type": "Container",
                    "color": 0x33FFFFFF,
                    "borderRadius": 12.0,
                    "children": [
                        [
                            "type": "Padding",
                            "padding_left": 10.0,
                            "padding_right": 10.0,
                            "padding_top": 4.0,
                            "padding_bottom": 4.0,
                            "children": [
                                [
                                    "type": "Text",
                                    "text": "\(activeCount) active",
                                    "fontSize": 12.0,
                                    "fontWeight": "bold",
                                    "color": 0xFFFFFFFF
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        headerItems.append(titleRow)
        headerItems.append(["type": "SizedBox", "height": 4.0, "children": []])
        headerItems.append([
            "type": "Text",
            "text": "Organize with clarity & momentum",
            "fontSize": 14.0,
            "color": 0xCCFFFFFF
        ])

        let headerCard: [String: Any] = [
            "id": "header_card",
            "type": "Container",
            "color": 0xFF4F46E5,
            "borderRadius": 0.0,
            "children": [
                [
                    "type": "Padding",
                    "padding_left": 18.0,
                    "padding_right": 18.0,
                    "padding_top": 16.0,
                    "padding_bottom": 16.0,
                    "children": [
                        [
                            "type": "Column",
                            "spacing": 4.0,
                            "children": headerItems
                        ]
                    ]
                ]
            ]
        ]
        rootItems.append(headerCard)

        // 2. Scrollable Body Content
        var scrollItems: [[String: Any]] = []

        // Card: Progress Overview Card
        var progressColItems: [[String: Any]] = []
        let progHeaderRow: [String: Any] = [
            "id": "prog_header_row",
            "type": "Row",
            "children": [
                [
                    "type": "Text",
                    "text": "Progress Overview",
                    "fontSize": 16.0,
                    "fontWeight": "bold",
                    "color": 0xFF1E293B
                ],
                [
                    "type": "Spacer"
                ],
                [
                    "type": "Text",
                    "text": "\(percentInt)% done (\(completedCount)/\(totalCount))",
                    "fontSize": 13.0,
                    "fontWeight": "bold",
                    "color": 0xFF4F46E5
                ]
            ]
        ]
        progressColItems.append(progHeaderRow)
        progressColItems.append(["type": "SizedBox", "height": 10.0, "children": []])

        let progIndicator: [String: Any] = [
            "id": "todo_progress_bar",
            "type": "LinearProgressIndicator",
            "value": progress,
            "minHeight": 8.0,
            "borderRadius": 4.0,
            "color": 0xFF4F46E5,
            "backgroundColor": 0xFFE2E8F0,
            "children": []
        ]
        progressColItems.append(progIndicator)
        progressColItems.append(["type": "SizedBox", "height": 12.0, "children": []])

        let statsRow: [String: Any] = [
            "type": "Row",
            "spacing": 8.0,
            "children": [
                [
                    "type": "Expanded",
                    "children": [
                        [
                            "type": "Container",
                            "color": 0xFFF8FAFC,
                            "borderRadius": 8.0,
                            "children": [
                                [
                                    "type": "Padding",
                                    "padding_top": 8.0,
                                    "padding_bottom": 8.0,
                                    "padding_left": 8.0,
                                    "padding_right": 8.0,
                                    "children": [
                                        [
                                            "type": "Column",
                                            "spacing": 2.0,
                                            "children": [
                                                ["type": "Text", "text": "Total", "fontSize": 11.0, "color": 0xFF64748B],
                                                ["type": "Text", "text": "\(totalCount)", "fontSize": 18.0, "fontWeight": "bold", "color": 0xFF1E293B]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    "type": "Expanded",
                    "children": [
                        [
                            "type": "Container",
                            "color": 0xFFF8FAFC,
                            "borderRadius": 8.0,
                            "children": [
                                [
                                    "type": "Padding",
                                    "padding_top": 8.0,
                                    "padding_bottom": 8.0,
                                    "padding_left": 8.0,
                                    "padding_right": 8.0,
                                    "children": [
                                        [
                                            "type": "Column",
                                            "spacing": 2.0,
                                            "children": [
                                                ["type": "Text", "text": "Active", "fontSize": 11.0, "color": 0xFF64748B],
                                                ["type": "Text", "text": "\(activeCount)", "fontSize": 18.0, "fontWeight": "bold", "color": 0xFFD97706]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    "type": "Expanded",
                    "children": [
                        [
                            "type": "Container",
                            "color": 0xFFF8FAFC,
                            "borderRadius": 8.0,
                            "children": [
                                [
                                    "type": "Padding",
                                    "padding_top": 8.0,
                                    "padding_bottom": 8.0,
                                    "padding_left": 8.0,
                                    "padding_right": 8.0,
                                    "children": [
                                        [
                                            "type": "Column",
                                            "spacing": 2.0,
                                            "children": [
                                                ["type": "Text", "text": "Done", "fontSize": 11.0, "color": 0xFF64748B],
                                                ["type": "Text", "text": "\(completedCount)", "fontSize": 18.0, "fontWeight": "bold", "color": 0xFF16A34A]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        progressColItems.append(statsRow)

        let progressCard: [String: Any] = [
            "id": "card_progress",
            "type": "Card",
            "color": 0xFFFFFFFF,
            "borderRadius": 14.0,
            "children": [
                [
                    "type": "Padding",
                    "padding_top": 14.0,
                    "padding_bottom": 14.0,
                    "padding_left": 14.0,
                    "padding_right": 14.0,
                    "children": [
                        [
                            "type": "Column",
                            "spacing": 4.0,
                            "children": progressColItems
                        ]
                    ]
                ]
            ]
        ]
        scrollItems.append(progressCard)
        scrollItems.append(["type": "SizedBox", "height": 14.0, "children": []])

        // Category Filter Chips
        var catChips: [[String: Any]] = []
        let allCategories = ["All"] + categories
        for cat in allCategories {
            let isSelected = (cat == activeCategoryFilter)
            catChips.append([
                "id": cat == "All" ? "filter_cat_all" : "filter_cat_\(cat)",
                "type": "FilterChip",
                "label": cat,
                "selected": isSelected,
                "selectedColor": 0xFF4F46E5,
                "children": []
            ])
        }
        let catScrollView: [String: Any] = [
            "id": "scroll_categories",
            "type": "SingleChildScrollView",
            "scrollDirection": "horizontal",
            "children": [
                [
                    "type": "Row",
                    "spacing": 8.0,
                    "children": catChips
                ]
            ]
        ]
        scrollItems.append(catScrollView)
        scrollItems.append(["type": "SizedBox", "height": 14.0, "children": []])

        // Add Task Card
        var addCardItems: [[String: Any]] = []
        addCardItems.append([
            "type": "Text",
            "text": "Quick Add Task",
            "fontSize": 15.0,
            "fontWeight": "bold",
            "color": 0xFF1E293B
        ])
        addCardItems.append(["type": "SizedBox", "height": 8.0, "children": []])

        let textFieldNode: [String: Any] = [
            "id": "tf_new_task",
            "type": "TextField",
            "value": newTaskTitle,
            "hintText": "What needs to be done?",
            "variant": "filled",
            "children": []
        ]
        addCardItems.append(textFieldNode)
        addCardItems.append(["type": "SizedBox", "height": 10.0, "children": []])

        var prioChips: [[String: Any]] = []
        prioChips.append([
            "id": "chip_prio_low",
            "type": "FilterChip",
            "label": "Low",
            "selected": selectedPriority == "low",
            "children": []
        ])
        prioChips.append([
            "id": "chip_prio_med",
            "type": "FilterChip",
            "label": "Medium",
            "selected": selectedPriority == "medium",
            "children": []
        ])
        prioChips.append([
            "id": "chip_prio_high",
            "type": "FilterChip",
            "label": "High",
            "selected": selectedPriority == "high",
            "children": []
        ])
        prioChips.append(["type": "Spacer"])

        let addBtn: [String: Any] = [
            "id": "btn_submit_task",
            "type": "Button",
            "isButton": true,
            "label": "Add Task",
            "children": [
                [
                    "type": "Text",
                    "text": "  Add Task  ",
                    "fontSize": 14.0,
                    "fontWeight": "bold",
                    "color": 0xFFFFFFFF
                ]
            ]
        ]
        prioChips.append(addBtn)

        addCardItems.append([
            "type": "Row",
            "spacing": 8.0,
            "children": prioChips
        ])

        let addCard: [String: Any] = [
            "id": "card_add_task",
            "type": "Card",
            "color": 0xFFFFFFFF,
            "borderRadius": 14.0,
            "children": [
                [
                    "type": "Padding",
                    "padding_top": 14.0,
                    "padding_bottom": 14.0,
                    "padding_left": 14.0,
                    "padding_right": 14.0,
                    "children": [
                        [
                            "type": "Column",
                            "spacing": 6.0,
                            "children": addCardItems
                        ]
                    ]
                ]
            ]
        ]
        scrollItems.append(addCard)
        scrollItems.append(["type": "SizedBox", "height": 16.0, "children": []])

        // Filter Tabs & Batch Actions Row
        var filterRowItems: [[String: Any]] = []
        filterRowItems.append([
            "id": "filter_status_all",
            "type": "FilterChip",
            "label": "All (\(totalCount))",
            "selected": filterStatus == "all",
            "children": []
        ])
        filterRowItems.append([
            "id": "filter_status_active",
            "type": "FilterChip",
            "label": "Active (\(activeCount))",
            "selected": filterStatus == "active",
            "children": []
        ])
        filterRowItems.append([
            "id": "filter_status_done",
            "type": "FilterChip",
            "label": "Done (\(completedCount))",
            "selected": filterStatus == "completed",
            "children": []
        ])
        filterRowItems.append(["type": "Spacer"])

        let allDone = totalCount > 0 && completedCount == totalCount
        let toggleAllBtn: [String: Any] = [
            "id": "btn_toggle_all_tasks",
            "type": "Button",
            "isButton": true,
            "children": [
                [
                    "type": "Text",
                    "text": allDone ? "Reset" : "Check All",
                    "fontSize": 12.0,
                    "fontWeight": "bold",
                    "color": 0xFF4F46E5
                ]
            ]
        ]
        filterRowItems.append(toggleAllBtn)

        if completedCount > 0 {
            let clearDoneBtn: [String: Any] = [
                "id": "btn_clear_completed_tasks",
                "type": "Button",
                "isButton": true,
                "children": [
                    [
                        "type": "Text",
                        "text": "Clear Done",
                        "fontSize": 12.0,
                        "fontWeight": "bold",
                        "color": 0xFFDC2626
                    ]
                ]
            ]
            filterRowItems.append(clearDoneBtn)
        }

        scrollItems.append([
            "type": "Row",
            "spacing": 8.0,
            "children": filterRowItems
        ])
        scrollItems.append(["type": "SizedBox", "height": 12.0, "children": []])

        // Tasks or Empty state
        if filteredList.isEmpty {
            let emptyCard: [String: Any] = [
                "type": "Card",
                "color": 0xFFFFFFFF,
                "borderRadius": 14.0,
                "children": [
                    [
                        "type": "Padding",
                        "padding_top": 32.0,
                        "padding_bottom": 32.0,
                        "padding_left": 20.0,
                        "padding_right": 20.0,
                        "children": [
                            [
                                "type": "Column",
                                "spacing": 8.0,
                                "children": [
                                    ["type": "Text", "text": "🎉", "fontSize": 42.0],
                                    ["type": "Text", "text": "All tasks organized!", "fontSize": 18.0, "fontWeight": "bold", "color": 0xFF1E293B],
                                    ["type": "Text", "text": "No pending tasks match this filter. Create a new task above.", "fontSize": 13.0, "color": 0xFF64748B]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            scrollItems.append(emptyCard)
        } else {
            for t in filteredList {
                var taskRowItems: [[String: Any]] = []

                taskRowItems.append([
                    "id": "cb_task_\(t.id)",
                    "type": "Checkbox",
                    "value": t.isCompleted,
                    "children": []
                ])
                taskRowItems.append(["type": "SizedBox", "width": 8.0, "children": []])

                var taskDetails: [[String: Any]] = []
                taskDetails.append([
                    "type": "Text",
                    "text": t.title,
                    "fontSize": 15.0,
                    "fontWeight": t.isCompleted ? "normal" : "bold",
                    "color": t.isCompleted ? 0xFF94A3B8 : 0xFF1E293B
                ])

                let prioColor: Int = t.priority == "high" ? 0xFFDC2626 : (t.priority == "medium" ? 0xFFD97706 : 0xFF16A34A)
                let metaRow: [String: Any] = [
                    "type": "Row",
                    "spacing": 6.0,
                    "children": [
                        [
                            "type": "Text",
                            "text": t.priority.uppercased(),
                            "fontSize": 10.0,
                            "fontWeight": "bold",
                            "color": prioColor
                        ],
                        [
                            "type": "Text",
                            "text": "• \(t.category)",
                            "fontSize": 10.0,
                            "color": 0xFF64748B
                        ]
                    ]
                ]
                taskDetails.append(metaRow)

                taskRowItems.append([
                    "type": "Expanded",
                    "children": [
                        [
                            "type": "Column",
                            "spacing": 2.0,
                            "children": taskDetails
                        ]
                    ]
                ])

                let delBtn: [String: Any] = [
                    "id": "btn_del_\(t.id)",
                    "type": "Button",
                    "isButton": true,
                    "children": [
                        [
                            "type": "Text",
                            "text": " ✕ ",
                            "fontSize": 14.0,
                            "fontWeight": "bold",
                            "color": 0xFF94A3B8
                        ]
                    ]
                ]
                taskRowItems.append(delBtn)

                let taskCard: [String: Any] = [
                    "id": "card_task_\(t.id)",
                    "type": "Card",
                    "color": 0xFFFFFFFF,
                    "borderRadius": 12.0,
                    "children": [
                        [
                            "type": "Padding",
                            "padding_top": 12.0,
                            "padding_bottom": 12.0,
                            "padding_left": 12.0,
                            "padding_right": 12.0,
                            "children": [
                                [
                                    "type": "Row",
                                    "spacing": 4.0,
                                    "children": taskRowItems
                                ]
                            ]
                        ]
                    ]
                ]
                scrollItems.append(taskCard)
                scrollItems.append(["type": "SizedBox", "height": 8.0, "children": []])
            }
        }

        let mainScrollView: [String: Any] = [
            "id": "main_scroll_view",
            "type": "SingleChildScrollView",
            "scrollDirection": "vertical",
            "children": [
                [
                    "type": "Padding",
                    "padding_top": 14.0,
                    "padding_bottom": 28.0,
                    "padding_left": 14.0,
                    "padding_right": 14.0,
                    "children": [
                        [
                            "type": "Column",
                            "spacing": 0.0,
                            "children": scrollItems
                        ]
                    ]
                ]
            ]
        ]

        rootItems.append([
            "type": "Expanded",
            "children": [mainScrollView]
        ])

        return [
            "id": "root",
            "type": "Column",
            "sourceType": "TodoApp",
            "children": rootItems
        ]
    }
    
    private func fetchUiTree() {
        // The iOS Simulator shares the Mac's localhost automatically!
        guard let url = URL(string: "https://custom-frameworks-neon-framework.iix8qf.easypanel.host/api/tree") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showError("Error connecting to Dart:\n\(error.localizedDescription)\n\nEnsure 'dart run' is active.")
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.showError("Invalid JSON received from Neon Engine.")
                }
                return
            }
            
            // Render UI on Main Thread
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                
                let rootView = self.renderWidget(node: json)
                rootView.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(rootView)
                
                // Center the rendered UI on the screen
                NSLayoutConstraint.activate([
                    rootView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    rootView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
                ])
            }
        }
        task.resume()
    }
    
    private func showError(_ message: String) {
        view.subviews.forEach { $0.removeFromSuperview() }
        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.frame = view.bounds.insetBy(dx: 20, dy: 20)
        view.addSubview(errorLabel)
    }
    
    // Recursive function mapping JSON to iOS UIViews
        private func renderWidget(node: [String: Any]) -> UIView {
            let type = node["type"] as? String ?? ""
            let sourceType = node["sourceType"] as? String ?? ""

            // ✅ TOP PRIORITY: Layout Helpers
            if type == "Expanded" {
                let view = UIView()
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        childView.topAnchor.constraint(equalTo: view.topAnchor),
                        childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
                return view
            }
            
            else if type == "Center" {
                let view = UIView()
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        childView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                }
                return view
            }
            
            else if type == "SizedBox" {
                let view = UIView()
                if let width = node["width"] as? Double {
                    view.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
                }
                if let height = node["height"] as? Double {
                    view.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
                }
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        childView.topAnchor.constraint(equalTo: view.topAnchor),
                        childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
                return view
            }
            
            else if type == "Spacer" {
                let view = UIView()
                view.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
                view.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .vertical)
                return view
            }
            
            else if type == "Padding" {
                let container = UIView()
                var top: CGFloat = 0
                var bottom: CGFloat = 0
                var left: CGFloat = 0
                var right: CGFloat = 0
                
                if let p = node["padding"] as? Double {
                    top = CGFloat(p); bottom = CGFloat(p); left = CGFloat(p); right = CGFloat(p)
                } else if let pDict = node["padding"] as? [String: Any] {
                    top = CGFloat(pDict["top"] as? Double ?? 0)
                    bottom = CGFloat(pDict["bottom"] as? Double ?? 0)
                    left = CGFloat(pDict["left"] as? Double ?? 0)
                    right = CGFloat(pDict["right"] as? Double ?? 0)
                }
                if let pt = node["padding_top"] as? Double ?? node["top"] as? Double { top = CGFloat(pt) }
                if let pb = node["padding_bottom"] as? Double ?? node["bottom"] as? Double { bottom = CGFloat(pb) }
                if let pl = node["padding_left"] as? Double ?? node["left"] as? Double { left = CGFloat(pl) }
                if let pr = node["padding_right"] as? Double ?? node["right"] as? Double { right = CGFloat(pr) }

                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: container.topAnchor, constant: top),
                        childView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -bottom),
                        childView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: left),
                        childView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -right)
                    ])
                }
                return container
            }

            else if type == "Text" {
                let label = UILabel()
                label.text = node["text"] as? String ?? ""
                let fontSize = CGFloat(node["fontSize"] as? Double ?? 16.0)
                let weightStr = node["fontWeight"] as? String ?? "normal"
                let weight: UIFont.Weight = (weightStr == "bold" || weightStr == "w700" || weightStr == "w600") ? .bold : .regular
                label.font = .systemFont(ofSize: fontSize, weight: weight)
                if let colorInt = node["color"] as? Int {
                    label.textColor = colorFromARGB(colorInt)
                } else if let colorInt64 = node["color"] as? Int64 {
                    label.textColor = colorFromARGB(Int(colorInt64))
                } else {
                    label.textColor = .label
                }
                label.numberOfLines = node["maxLines"] as? Int ?? 0
                return label
            } else if type == "SegmentedButton" {
                let items = node["segments"] as? [String] ?? []
                let segmentedControl = UISegmentedControl(items: items)
                segmentedControl.selectedSegmentIndex = node["selectedIndex"] as? Int ?? 0
                segmentedControl.accessibilityIdentifier = node["id"] as? String
                segmentedControl.addTarget(self, action: #selector(handleSegmentChange(_:)), for: .valueChanged)
                return segmentedControl
            }
            
            else if type.contains("Column") || type.contains("Row") {
                let stackView = UIStackView()
                let isCol = type.contains("Column")
                stackView.axis = isCol ? .vertical : .horizontal
                stackView.alignment = isCol ? .fill : .center
                stackView.distribution = .fill
                let spacing = CGFloat(node["spacing"] as? Double ?? 12.0)
                stackView.spacing = spacing
                
                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        stackView.addArrangedSubview(renderWidget(node: child))
                    }
                }
                return stackView
                
            }
            // ✅ NEW: Container Support (Maps to UIView with background)
            // ✅ FIX: Don't treat as a plain Container if it's flagged as a Button
            else if type.contains("Container") && !(node["isButton"] as? Bool ?? false) {
                let container = UIView()
                if let colorInt = node["color"] as? Int {
                    container.backgroundColor = colorFromARGB(colorInt)
                } else if let colorInt64 = node["color"] as? Int64 {
                    container.backgroundColor = colorFromARGB(Int(colorInt64))
                } else {
                    container.backgroundColor = .systemGray5
                }
                
                let borderRadius = CGFloat(node["borderRadius"] as? Double ?? 12.0)
                container.layer.cornerRadius = borderRadius
                if borderRadius > 0 {
                    container.layer.masksToBounds = true
                }
                
                let hasChildPadding = (node["children"] as? [[String: Any]])?.first?["type"] as? String == "Padding"
                let defaultPad: CGFloat = hasChildPadding ? 0.0 : 0.0
                let paddingTop = CGFloat(node["padding_top"] as? Double ?? defaultPad)
                let paddingBottom = CGFloat(node["padding_bottom"] as? Double ?? defaultPad)
                let paddingLeft = CGFloat(node["padding_left"] as? Double ?? defaultPad)
                let paddingRight = CGFloat(node["padding_right"] as? Double ?? defaultPad)
                
                if let width = node["width"] as? Double {
                    container.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
                }
                if let height = node["height"] as? Double {
                    container.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
                }
                
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(childView)
                    
                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: container.topAnchor, constant: paddingTop),
                        childView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -paddingBottom),
                        childView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: paddingLeft),
                        childView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -paddingRight)
                    ])
                }
                return container
                
            }
            // ✅ NEW: Button Support (Maps to blue UIView wrapper)
            // ✅ FIX: Check for isButton flag from Dart
            // ✅ NEW: Ultra-Resilient Button Support
            // ✅ FIX: Restore isButton check from Dart to handle interactive Containers
            else if (node["isButton"] as? Bool ?? false) || type.contains("Button") {
                // 1. Upgrade from standard UIView to a native UIButton
                // This guarantees iOS treats it as an interactive element.
                let buttonView = UIButton(type: .custom)
                
                // 🎨 Material 3 Styling based on sourceType or color
                if let colorInt = node["color"] as? Int {
                    buttonView.backgroundColor = colorFromARGB(colorInt)
                } else if let colorInt64 = node["color"] as? Int64 {
                    buttonView.backgroundColor = colorFromARGB(Int(colorInt64))
                } else if sourceType == "FilledTonalButton" {
                    buttonView.backgroundColor = UIColor(red: 0xEA/255.0, green: 0xDD/255.0, blue: 0xFF/255.0, alpha: 1.0)
                } else if sourceType == "OutlinedButton" {
                    buttonView.backgroundColor = .clear
                    buttonView.layer.borderWidth = 1
                    buttonView.layer.borderColor = UIColor.systemGray.cgColor
                } else if sourceType == "TextButton" {
                    buttonView.backgroundColor = .clear
                } else if sourceType == "ElevatedButton" {
                    buttonView.backgroundColor = .systemBackground
                    buttonView.layer.shadowColor = UIColor.black.cgColor
                    buttonView.layer.shadowOpacity = 0.2
                    buttonView.layer.shadowOffset = CGSize(width: 0, height: 2)
                    buttonView.layer.shadowRadius = 4
                } else if sourceType == "FloatingActionButton" {
                    buttonView.backgroundColor = UIColor(red: 0xD0/255.0, green: 0xBC/255.0, blue: 0xFF/255.0, alpha: 1.0)
                    buttonView.layer.cornerRadius = 16
                } else if sourceType == "IconButton" {
                    buttonView.backgroundColor = .clear
                    buttonView.layer.cornerRadius = 24 // Assume fixed size
                } else {
                    buttonView.backgroundColor = .systemBlue
                    buttonView.layer.cornerRadius = 8
                }
                
                let bRadius = CGFloat(node["borderRadius"] as? Double ?? 8.0)
                buttonView.layer.cornerRadius = bRadius
                buttonView.clipsToBounds = true
                
                // 2. Aggressive ID Fetching
                // We check "id", "actionId", and "key" to ensure we catch whatever Dart sent.
                let rawId = node["id"] ?? node["actionId"] ?? node["key"]
                
                if let rawId = rawId {
                    let buttonId = "\(rawId)" // Safely convert to String
                    print("🔗 Attaching tap gesture to Button ID: \(buttonId)")
                    
                    let tap = ActionTapGesture(target: self, action: #selector(handleTap(_:)))
                    tap.buttonId = buttonId
                    buttonView.addGestureRecognizer(tap)
                    buttonView.isUserInteractionEnabled = true
                } else {
                    print("⚠️ WARNING: Button received from Dart without ANY id field!")
                }
                
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    
                    if let label = childView as? UILabel {
                        // Adjust text color for transparent/white buttons
                        if node["color"] == nil {
                            if sourceType == "OutlinedButton" || sourceType == "TextButton" || sourceType == "ElevatedButton" {
                                label.textColor = .systemBlue
                            } else {
                                label.textColor = .white
                            }
                        }
                        label.font = .boldSystemFont(ofSize: 14)
                    }
                    
                    // 3. THE CRITICAL FIX: Disable interaction on the entire child tree.
                    // This forces the touch to pass completely through the Text/Container
                    // and hit the Button underneath it.
                    childView.isUserInteractionEnabled = false
                    
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    buttonView.addSubview(childView)
                    
                    let pTop = CGFloat(node["padding_top"] as? Double ?? 10.0)
                    let pBottom = CGFloat(node["padding_bottom"] as? Double ?? 10.0)
                    let pLeft = CGFloat(node["padding_left"] as? Double ?? 16.0)
                    let pRight = CGFloat(node["padding_right"] as? Double ?? 16.0)
                    
                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: buttonView.topAnchor, constant: pTop),
                        childView.bottomAnchor.constraint(equalTo: buttonView.bottomAnchor, constant: -pBottom),
                        childView.leadingAnchor.constraint(equalTo: buttonView.leadingAnchor, constant: pLeft),
                        childView.trailingAnchor.constraint(equalTo: buttonView.trailingAnchor, constant: -pRight)
                    ])
                }
                return buttonView
                
            }
            
            // ✅ NEW: RemoteWidget Support
            else if type == "RemoteWidget" {
                let container = UIView()
                let loadingLabel = UILabel()
                loadingLabel.text = "Loading..."
                loadingLabel.textAlignment = .center
                loadingLabel.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(loadingLabel)
                
                NSLayoutConstraint.activate([
                    loadingLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    loadingLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
                ])
                
                if let urlString = node["url"] as? String, let url = URL(string: urlString) {
                    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        guard let self = self, let data = data,
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                        
                        DispatchQueue.main.async {
                            container.subviews.forEach { $0.removeFromSuperview() }
                            let remoteView = self.renderWidget(node: json)
                            remoteView.translatesAutoresizingMaskIntoConstraints = false
                            container.addSubview(remoteView)
                            
                            NSLayoutConstraint.activate([
                                remoteView.topAnchor.constraint(equalTo: container.topAnchor),
                                remoteView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                                remoteView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                                remoteView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                            ])
                        }
                    }.resume()
                }
                return container
            }
            
            // ✅ NEW: NavigationBar Support
            else if type == "NavigationBar" {
                let tabBar = UITabBar()
                var items: [UITabBarItem] = []
                
                if let destinations = node["destinations"] as? [[String: Any]] {
                    for (index, dest) in destinations.enumerated() {
                        let label = dest["label"] as? String ?? "Item \(index)"
                        let item = UITabBarItem(title: label, image: UIImage(systemName: "circle"), tag: index)
                        items.append(item)
                    }
                }
                tabBar.setItems(items, animated: false)
                tabBar.delegate = self
                tabBar.accessibilityIdentifier = node["id"] as? String
                
                if let selectedIndex = node["selectedIndex"] as? Int {
                    tabBar.selectedItem = items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
                }
                return tabBar
            }
            
            // ✅ NEW: AppBar Support
            else if type == "AppBar" {
                let header = UIView()
                header.backgroundColor = .systemBackground
                
                let titleLabel = UILabel()
                titleLabel.font = .boldSystemFont(ofSize: 20)
                titleLabel.textAlignment = .center
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                header.addSubview(titleLabel)
                
                let variant = node["variant"] as? String ?? "small"
                if variant == "large" || variant == "medium" {
                    titleLabel.font = .boldSystemFont(ofSize: 32)
                    titleLabel.textAlignment = .left
                }
                
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let child = renderWidget(node: firstChild)
                    if let label = child as? UILabel {
                        titleLabel.text = label.text
                    }
                }
                
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
                    titleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
                    titleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
                    titleLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16)
                ])
                
                return header
            }
            
            // ✅ NEW: TabBar Support
            else if type == "TabBar" {
                let segment = UISegmentedControl()
                segment.accessibilityIdentifier = node["id"] as? String
                segment.addTarget(self, action: #selector(handleSegmentChange(_:)), for: .valueChanged)
                
                if let tabs = node["tabs"] as? [[String: Any]] {
                    for (index, tab) in tabs.enumerated() {
                        let text = tab["text"] as? String ?? ""
                        segment.insertSegment(withTitle: text, at: index, animated: false)
                    }
                }
                if let selectedIndex = node["selectedIndex"] as? Int {
                    segment.selectedSegmentIndex = selectedIndex
                }
                return segment
            }
            
            // ✅ NEW: NavigationDrawer Support
            else if type == "NavigationDrawer" {
                let drawer = UIStackView()
                drawer.axis = .vertical
                drawer.alignment = .fill
                drawer.spacing = 5
                drawer.backgroundColor = .systemGray6
                drawer.layer.cornerRadius = 16
                drawer.isLayoutMarginsRelativeArrangement = true
                drawer.layoutMargins = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
                
                if let children = node["children"] as? [[String: Any]] {
                    for (index, child) in children.enumerated() {
                        let btn = UIButton(type: .system)
                        btn.setTitle(child["label"] as? String ?? "", for: .normal)
                        btn.contentHorizontalAlignment = .left
                        btn.tag = index
                        btn.accessibilityIdentifier = node["id"] as? String
                        btn.addTarget(self, action: #selector(handleDrawerItemTap(_:)), for: .touchUpInside)
                        drawer.addArrangedSubview(btn)
                    }
                }
                return drawer
            }
            
            // ✅ NEW: NavigationRail Support
            else if type == "NavigationRail" {
                let rail = UIStackView()
                rail.axis = .vertical
                rail.alignment = .center
                rail.spacing = 20
                rail.backgroundColor = .systemGray6
                rail.isLayoutMarginsRelativeArrangement = true
                rail.layoutMargins = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0)
                
                if let destinations = node["destinations"] as? [[String: Any]] {
                    for (index, dest) in destinations.enumerated() {
                        let btn = UIButton(type: .system)
                        btn.setTitle(dest["label"] as? String ?? "", for: .normal)
                        btn.tag = index
                        btn.accessibilityIdentifier = node["id"] as? String
                        btn.addTarget(self, action: #selector(handleDrawerItemTap(_:)), for: .touchUpInside)
                        rail.addArrangedSubview(btn)
                    }
                }
                return rail
            }
            
            // ✅ NEW: Switch Support
            else if type == "Switch" {
                let toggle = UISwitch()
                toggle.isOn = node["value"] as? Bool ?? false
                toggle.accessibilityIdentifier = node["id"] as? String
                toggle.addTarget(self, action: #selector(handleSwitchChange(_:)), for: .valueChanged)
                return toggle
            }
            
            // ✅ NEW: Checkbox Support
            else if type == "Checkbox" {
                let checkbox = UIButton(type: .system)
                let isChecked = node["value"] as? Bool ?? false
                checkbox.setImage(UIImage(systemName: isChecked ? "checkmark.square.fill" : "square"), for: .normal)
                checkbox.accessibilityIdentifier = node["id"] as? String
                checkbox.addTarget(self, action: #selector(handleCheckboxTap(_:)), for: .touchUpInside)
                return checkbox
            }
            
            // ✅ NEW: Radio Support
            else if type == "Radio" {
                let radio = UIButton(type: .system)
                let isSelected = node["selected"] as? Bool ?? false
                radio.setImage(UIImage(systemName: isSelected ? "circle.fill" : "circle"), for: .normal)
                radio.accessibilityIdentifier = node["id"] as? String
                radio.addTarget(self, action: #selector(handleRadioTap(_:)), for: .touchUpInside)
                return radio
            }
            
            // ✅ NEW: Slider Support
            else if type == "Slider" {
                let slider = UISlider()
                slider.value = Float(node["value"] as? Double ?? 0.5)
                slider.minimumValue = Float(node["min"] as? Double ?? 0.0)
                slider.maximumValue = Float(node["max"] as? Double ?? 1.0)
                slider.accessibilityIdentifier = node["id"] as? String
                slider.addTarget(self, action: #selector(handleSliderChange(_:)), for: .valueChanged)
                return slider
            }
            
            // ✅ NEW: Chip Support (ActionChip, FilterChip, etc.)
            else if type == "ActionChip" || type == "FilterChip" || type == "ChoiceChip" || type == "InputChip" {
                let chip = UIButton(type: .system)
                chip.backgroundColor = .systemGray5
                chip.layer.cornerRadius = 16
                chip.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
                chip.accessibilityIdentifier = node["id"] as? String
                
                // Set label
                if let labelStr = node["label"] as? String {
                    chip.setTitle(labelStr, for: .normal)
                } else if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    if let label = childView as? UILabel {
                        chip.setTitle(label.text, for: .normal)
                    }
                }
                
                // FilterChip shows selected state
                if type == "FilterChip" {
                    let isSelected = node["selected"] as? Bool ?? false
                    if isSelected {
                        if let selColor = node["selectedColor"] as? Int {
                            chip.backgroundColor = colorFromARGB(selColor)
                        } else if let selColor64 = node["selectedColor"] as? Int64 {
                            chip.backgroundColor = colorFromARGB(Int(selColor64))
                        } else {
                            chip.backgroundColor = .systemBlue
                        }
                        chip.setTitleColor(.white, for: .normal)
                    } else {
                        chip.backgroundColor = .systemGray5
                        chip.setTitleColor(.label, for: .normal)
                    }
                }
                
                chip.addTarget(self, action: #selector(handleChipTap(_:)), for: .touchUpInside)
                return chip
            }
            
            else if type == "Card" {
                let card = UIView()
                let variant = node["variant"] as? String ?? "elevated"
                let borderRadius = node["borderRadius"] as? Double ?? 12.0
                card.layer.cornerRadius = CGFloat(borderRadius)
                card.clipsToBounds = false
                
                if let colorInt = node["color"] as? Int {
                    card.backgroundColor = colorFromARGB(colorInt)
                } else if let colorInt64 = node["color"] as? Int64 {
                    card.backgroundColor = colorFromARGB(Int(colorInt64))
                } else {
                    switch variant {
                    case "elevated":
                        card.backgroundColor = .systemBackground
                    case "filled":
                        card.backgroundColor = UIColor(red: 0xE8/255.0, green: 0xDE/255.0, blue: 0xFF/255.0, alpha: 1.0)
                    case "outlined":
                        card.backgroundColor = .systemBackground
                        card.layer.borderWidth = 1
                        card.layer.borderColor = UIColor.systemGray.cgColor
                    default:
                        card.backgroundColor = .systemBackground
                    }
                }
                
                if variant == "elevated" {
                    card.layer.shadowColor = UIColor.black.cgColor
                    card.layer.shadowOpacity = 0.08
                    card.layer.shadowOffset = CGSize(width: 0, height: 2)
                    card.layer.shadowRadius = 4
                }
                
                let hasChildPadding = (node["children"] as? [[String: Any]])?.first?["type"] as? String == "Padding"
                let defaultCardPad: CGFloat = hasChildPadding ? 0.0 : 16.0
                let paddingTop = CGFloat(node["padding_top"] as? Double ?? defaultCardPad)
                let paddingBottom = CGFloat(node["padding_bottom"] as? Double ?? defaultCardPad)
                let paddingLeft = CGFloat(node["padding_left"] as? Double ?? defaultCardPad)
                let paddingRight = CGFloat(node["padding_right"] as? Double ?? defaultCardPad)
                
                let contentStack = UIStackView()
                contentStack.axis = .vertical
                contentStack.spacing = 8
                contentStack.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(contentStack)
                
                NSLayoutConstraint.activate([
                    contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: paddingTop),
                    contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -paddingBottom),
                    contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: paddingLeft),
                    contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -paddingRight)
                ])
                
                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        contentStack.addArrangedSubview(renderWidget(node: child))
                    }
                }
                return card
            }
            
            else if type == "Dialog" {
                let container = UIView()
                let visible = node["visible"] as? Bool ?? false
                let dialogId = node["id"] as? String ?? ""
                
                if visible {
                    let title = node["title"] as? String ?? ""
                    let contentText = node["contentText"] as? String ?? ""
                    let variant = node["variant"] as? String ?? "standard"
                    
                    let alert = UIAlertController(
                        title: title.isEmpty ? nil : title,
                        message: contentText.isEmpty ? nil : contentText,
                        preferredStyle: variant == "fullscreen" ? .alert : .alert
                    )
                    
                    if let actions = node["dialogActions"] as? [[String: Any]] {
                        for actionData in actions {
                            let label = actionData["label"] as? String ?? "OK"
                            let key = actionData["key"] as? String ?? ""
                            let action = UIAlertAction(title: label, style: .default) { [weak self] _ in
                                if !dialogId.isEmpty {
                                    self?.sendActionToDart(buttonId: dialogId, value: key)
                                }
                            }
                            alert.addAction(action)
                        }
                    }
                    
                    if alert.actions.isEmpty {
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.present(alert, animated: true)
                    }
                }
                
                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        let childView = renderWidget(node: child)
                        childView.translatesAutoresizingMaskIntoConstraints = false
                        container.addSubview(childView)
                    }
                }
                return container
            }
            
            else if type == "BottomSheet" {
                let container = UIView()
                let visible = node["visible"] as? Bool ?? false
                let showDragHandle = node["showDragHandle"] as? Bool ?? true
                let sheetId = node["id"] as? String ?? ""
                
                if visible {
                    let sheetVC = UIViewController()
                    sheetVC.view.backgroundColor = .systemBackground
                    sheetVC.view.layer.cornerRadius = 16
                    sheetVC.view.clipsToBounds = true
                    
                    let contentStack = UIStackView()
                    contentStack.axis = .vertical
                    contentStack.spacing = 8
                    contentStack.translatesAutoresizingMaskIntoConstraints = false
                    sheetVC.view.addSubview(contentStack)
                    
                    var topOffset: CGFloat = 16
                    
                    if showDragHandle {
                        let handle = UIView()
                        handle.backgroundColor = .systemGray3
                        handle.layer.cornerRadius = 2
                        handle.translatesAutoresizingMaskIntoConstraints = false
                        sheetVC.view.addSubview(handle)
                        NSLayoutConstraint.activate([
                            handle.topAnchor.constraint(equalTo: sheetVC.view.topAnchor, constant: 8),
                            handle.centerXAnchor.constraint(equalTo: sheetVC.view.centerXAnchor),
                            handle.widthAnchor.constraint(equalToConstant: 32),
                            handle.heightAnchor.constraint(equalToConstant: 4)
                        ])
                        topOffset = 24
                    }
                    
                    NSLayoutConstraint.activate([
                        contentStack.topAnchor.constraint(equalTo: sheetVC.view.topAnchor, constant: topOffset),
                        contentStack.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 16),
                        contentStack.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -16),
                        contentStack.bottomAnchor.constraint(lessThanOrEqualTo: sheetVC.view.bottomAnchor, constant: -16)
                    ])
                    
                    if let children = node["children"] as? [[String: Any]] {
                        for child in children {
                            contentStack.addArrangedSubview(renderWidget(node: child))
                        }
                    }
                    
                    if #available(iOS 15.0, *) {
                        if let sheet = sheetVC.sheetPresentationController {
                            sheet.detents = [.medium(), .large()]
                            sheet.prefersGrabberVisible = showDragHandle
                        }
                    }
                    sheetVC.modalPresentationStyle = .pageSheet
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.present(sheetVC, animated: true)
                    }
                }
                return container
            }
            
            else if type == "TextField" {
                let stack = UIStackView()
                stack.axis = .vertical
                stack.spacing = 4
                
                let variant = node["variant"] as? String ?? "filled"
                let fieldId = node["id"] as? String ?? ""
                
                let labelText = node["labelText"] as? String ?? ""
                if !labelText.isEmpty {
                    let label = UILabel()
                    label.text = labelText
                    label.font = .systemFont(ofSize: 12)
                    label.textColor = .secondaryLabel
                    stack.addArrangedSubview(label)
                }
                
                let textField = UITextField()
                textField.text = node["value"] as? String ?? ""
                textField.placeholder = node["hintText"] as? String ?? ""
                textField.borderStyle = .none
                textField.font = .systemFont(ofSize: 16)
                
                if variant == "outlined" {
                    textField.layer.borderWidth = 1
                    textField.layer.borderColor = UIColor.systemGray.cgColor
                    textField.layer.cornerRadius = 8
                    textField.backgroundColor = .clear
                } else {
                    textField.backgroundColor = .systemGray6
                    textField.layer.cornerRadius = 8
                    textField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                }
                
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
                textField.leftView = paddingView
                textField.leftViewMode = .always
                textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
                textField.rightViewMode = .always
                textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                if node["obscureText"] as? Bool ?? false {
                    textField.isSecureTextEntry = true
                }
                
                textField.accessibilityIdentifier = fieldId
                textField.delegate = self
                textField.addTarget(self, action: #selector(handleTextFieldChange(_:)), for: .editingChanged)
                stack.addArrangedSubview(textField)
                
                let errorText = node["errorText"] as? String ?? ""
                let helperText = node["helperText"] as? String ?? ""
                if !errorText.isEmpty {
                    let errorLabel = UILabel()
                    errorLabel.text = errorText
                    errorLabel.font = .systemFont(ofSize: 12)
                    errorLabel.textColor = .systemRed
                    stack.addArrangedSubview(errorLabel)
                } else if !helperText.isEmpty {
                    let helperLabel = UILabel()
                    helperLabel.text = helperText
                    helperLabel.font = .systemFont(ofSize: 12)
                    helperLabel.textColor = .secondaryLabel
                    stack.addArrangedSubview(helperLabel)
                }
                return stack
            }
            
            else if type == "SearchBar" {
                let searchBar = UISearchBar()
                searchBar.placeholder = node["hintText"] as? String ?? "Search"
                searchBar.text = node["value"] as? String ?? ""
                searchBar.searchBarStyle = .minimal
                searchBar.accessibilityIdentifier = node["id"] as? String
                return searchBar
            }
            
            else if type == "SearchAnchor" {
                let stack = UIStackView()
                stack.axis = .vertical
                stack.spacing = 0
                
                let searchId = node["id"] as? String ?? ""
                let expanded = node["expanded"] as? Bool ?? false
                
                let searchBar = UISearchBar()
                searchBar.placeholder = node["hintText"] as? String ?? "Search"
                searchBar.text = node["value"] as? String ?? ""
                searchBar.searchBarStyle = .minimal
                searchBar.accessibilityIdentifier = searchId
                stack.addArrangedSubview(searchBar)
                
                if expanded, let suggestions = node["suggestions"] as? [[String: Any]] {
                    for (index, suggestion) in suggestions.enumerated() {
                        let btn = UIButton(type: .system)
                        btn.setTitle(suggestion["text"] as? String ?? "", for: .normal)
                        btn.contentHorizontalAlignment = .left
                        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
                        btn.tag = index
                        btn.accessibilityIdentifier = searchId
                        btn.addTarget(self, action: #selector(handleSearchSuggestionTap(_:)), for: .touchUpInside)
                        stack.addArrangedSubview(btn)
                    }
                }
                return stack
            }
            
            else if type == "MenuAnchor" {
                let container = UIView()
                let menuId = node["id"] as? String ?? ""
                let expanded = node["expanded"] as? Bool ?? false
                
                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: container.topAnchor),
                        childView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                        childView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                        childView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                    ])
                }
                
                if expanded, let menuItems = node["menuItems"] as? [[String: Any]] {
                    if #available(iOS 14.0, *) {
                        var actions: [UIAction] = []
                        for (index, item) in menuItems.enumerated() {
                            let label = item["label"] as? String ?? "Item \(index)"
                            let enabled = item["enabled"] as? Bool ?? true
                            let action = UIAction(title: label, attributes: enabled ? [] : .disabled) { [weak self] _ in
                                if !menuId.isEmpty {
                                    self?.sendActionToDart(buttonId: menuId, index: index)
                                }
                            }
                            actions.append(action)
                        }
                        let menu = UIMenu(title: "", children: actions)
                        let menuButton = UIButton(type: .system)
                        menuButton.menu = menu
                        menuButton.showsMenuAsPrimaryAction = true
                        menuButton.setTitle("⋮", for: .normal)
                        menuButton.translatesAutoresizingMaskIntoConstraints = false
                        container.addSubview(menuButton)
                        NSLayoutConstraint.activate([
                            menuButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                            menuButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
                        ])
                    }
                }
                return container
            }
            
            else if type == "MenuBar" {
                let stack = UIStackView()
                stack.axis = .horizontal
                stack.spacing = 0
                stack.distribution = .fillEqually
                
                let menuId = node["id"] as? String ?? ""
                let selectedIndex = node["selectedIndex"] as? Int ?? -1
                
                if let menuItems = node["menuItems"] as? [[String: Any]] {
                    for (index, item) in menuItems.enumerated() {
                        let btn = UIButton(type: .system)
                        let label = item["label"] as? String ?? "Item \(index)"
                        let enabled = item["enabled"] as? Bool ?? true
                        btn.setTitle(label, for: .normal)
                        btn.isEnabled = enabled
                        btn.tag = index
                        btn.accessibilityIdentifier = menuId
                        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
                        
                        if index == selectedIndex {
                            btn.backgroundColor = UIColor(red: 0xEA/255.0, green: 0xDD/255.0, blue: 0xFF/255.0, alpha: 1.0)
                        }
                        
                        btn.addTarget(self, action: #selector(handleMenuBarTap(_:)), for: .touchUpInside)
                        stack.addArrangedSubview(btn)
                    }
                }
                return stack
            }
            
            // ✅ NEW: Badge Support
            else if type == "Badge" {
                let badge = UILabel()
                badge.text = node["label"] as? String ?? ""
                badge.backgroundColor = .systemRed
                badge.textColor = .white
                badge.font = .systemFont(ofSize: 12, weight: .bold)
                badge.textAlignment = .center
                badge.layer.cornerRadius = 10
                badge.clipsToBounds = true
                badge.widthAnchor.constraint(equalToConstant: 20).isActive = true
                badge.heightAnchor.constraint(equalToConstant: 20).isActive = true
                return badge
            }
            
            // ✅ NEW: SegmentedButton Support (Basic Stack with divider style)
            else if sourceType == "SegmentedButton" {
                let stack = UIStackView()
                stack.axis = .horizontal
                stack.distribution = .fillEqually
                stack.layer.borderWidth = 1
                stack.layer.borderColor = UIColor.systemGray.cgColor
                stack.layer.cornerRadius = 8
                stack.clipsToBounds = true
                
                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        stack.addArrangedSubview(renderWidget(node: child))
                    }
                }
                return stack
            }
            
            else if type == "ListTile" {
                let tileStack = UIStackView()
                tileStack.axis = .horizontal
                tileStack.alignment = .center
                tileStack.spacing = 12
                let isDense = node["dense"] as? Bool ?? false
                let isSelected = node["selected"] as? Bool ?? false
                let isEnabled = node["enabled"] as? Bool ?? true
                let tileId = node["id"] as? String

                tileStack.isLayoutMarginsRelativeArrangement = true
                tileStack.layoutMargins = UIEdgeInsets(top: isDense ? 4 : 8, left: 16, bottom: isDense ? 4 : 8, right: 16)

                if isSelected {
                    tileStack.backgroundColor = UIColor(red: 0xEA/255.0, green: 0xDD/255.0, blue: 0xFF/255.0, alpha: 1.0)
                    tileStack.layer.cornerRadius = 8
                }

                if let leading = node["leading"] as? [String: Any] {
                    let leadingView = renderWidget(node: leading)
                    leadingView.setContentHuggingPriority(.required, for: .horizontal)
                    tileStack.addArrangedSubview(leadingView)
                }

                let textStack = UIStackView()
                textStack.axis = .vertical
                textStack.spacing = 2

                let titleLabel = UILabel()
                titleLabel.text = node["title"] as? String ?? ""
                titleLabel.font = isDense ? .systemFont(ofSize: 14) : .systemFont(ofSize: 16)
                titleLabel.textColor = isEnabled ? .label : .secondaryLabel
                textStack.addArrangedSubview(titleLabel)

                if let subtitle = node["subtitle"] as? String, !subtitle.isEmpty {
                    let subtitleLabel = UILabel()
                    subtitleLabel.text = subtitle
                    subtitleLabel.font = .systemFont(ofSize: isDense ? 12 : 14)
                    subtitleLabel.textColor = .secondaryLabel
                    subtitleLabel.numberOfLines = 0
                    textStack.addArrangedSubview(subtitleLabel)
                }

                tileStack.addArrangedSubview(textStack)

                if let trailing = node["trailing"] as? [String: Any] {
                    let trailingView = renderWidget(node: trailing)
                    trailingView.setContentHuggingPriority(.required, for: .horizontal)
                    tileStack.addArrangedSubview(trailingView)
                }

                if isEnabled, let tileId = tileId {
                    tileStack.isUserInteractionEnabled = true
                    let tap = ActionTapGesture(target: self, action: #selector(handleTap(_:)))
                    tap.buttonId = tileId
                    tileStack.addGestureRecognizer(tap)
                }

                tileStack.alpha = isEnabled ? 1.0 : 0.5
                return tileStack
            }

            else if type == "LinearProgressIndicator" || type == "ProgressBar" {
                let container = UIView()
                let indeterminate = node["indeterminate"] as? Bool ?? false
                let minHeight = CGFloat(node["minHeight"] as? Double ?? 4.0)
                let borderRadius = CGFloat(node["borderRadius"] as? Double ?? 0.0)

                let progressView = UIProgressView(progressViewStyle: .default)
                progressView.translatesAutoresizingMaskIntoConstraints = false

                if !indeterminate, let value = node["value"] as? Double {
                    progressView.progress = Float(value)
                } else {
                    progressView.progress = 0.5
                }

                if let colorInt = node["color"] as? Int {
                    progressView.progressTintColor = colorFromARGB(colorInt)
                }
                if let bgColorInt = node["backgroundColor"] as? Int {
                    progressView.trackTintColor = colorFromARGB(bgColorInt)
                }

                container.addSubview(progressView)
                container.layer.cornerRadius = borderRadius
                container.clipsToBounds = true

                NSLayoutConstraint.activate([
                    progressView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    progressView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    progressView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    container.heightAnchor.constraint(equalToConstant: minHeight),
                    container.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
                ])

                let scaleY = minHeight / 4.0
                progressView.transform = CGAffineTransform(scaleX: 1.0, y: scaleY)

                return container
            }

            else if type == "CircularProgressIndicator" {
                let size = CGFloat(node["size"] as? Double ?? 36.0)
                let indeterminate = node["indeterminate"] as? Bool ?? false
                let strokeWidth = CGFloat(node["strokeWidth"] as? Double ?? 4.0)

                let container = UIView()
                container.widthAnchor.constraint(equalToConstant: size).isActive = true
                container.heightAnchor.constraint(equalToConstant: size).isActive = true

                let indicator = UIActivityIndicatorView(style: size > 30 ? .large : .medium)
                indicator.translatesAutoresizingMaskIntoConstraints = false

                if let colorInt = node["color"] as? Int {
                    indicator.color = colorFromARGB(colorInt)
                }

                indicator.startAnimating()
                container.addSubview(indicator)
                NSLayoutConstraint.activate([
                    indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
                ])
                return container
            }

            else if type == "Tooltip" {
                let container = UIView()
                let message = node["message"] as? String ?? ""

                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(childView)
                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: container.topAnchor),
                        childView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                        childView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                        childView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                    ])
                }

                container.accessibilityLabel = message
                container.accessibilityHint = message
                return container
            }

            else if type == "SnackBar" {
                let container = UIView()
                let visible = node["visible"] as? Bool ?? false
                let snackId = node["id"] as? String ?? ""

                if visible {
                    let behavior = node["behavior"] as? String ?? "fixed"
                    let contentText = node["contentText"] as? String ?? ""
                    let actionLabel = node["actionLabel"] as? String ?? ""
                    let showCloseIcon = node["showCloseIcon"] as? Bool ?? false

                    let snackView = UIView()
                    snackView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                    snackView.layer.cornerRadius = behavior == "floating" ? 8 : 0

                    let hStack = UIStackView()
                    hStack.axis = .horizontal
                    hStack.alignment = .center
                    hStack.spacing = 8
                    hStack.translatesAutoresizingMaskIntoConstraints = false
                    snackView.addSubview(hStack)

                    NSLayoutConstraint.activate([
                        hStack.topAnchor.constraint(equalTo: snackView.topAnchor, constant: 12),
                        hStack.bottomAnchor.constraint(equalTo: snackView.bottomAnchor, constant: -12),
                        hStack.leadingAnchor.constraint(equalTo: snackView.leadingAnchor, constant: 16),
                        hStack.trailingAnchor.constraint(equalTo: snackView.trailingAnchor, constant: -16)
                    ])

                    let msgLabel = UILabel()
                    msgLabel.text = contentText
                    msgLabel.textColor = .white
                    msgLabel.font = .systemFont(ofSize: 14)
                    msgLabel.numberOfLines = 0
                    msgLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    hStack.addArrangedSubview(msgLabel)

                    if !actionLabel.isEmpty {
                        let actionBtn = UIButton(type: .system)
                        actionBtn.setTitle(actionLabel, for: .normal)
                        actionBtn.setTitleColor(UIColor(red: 0xD0/255.0, green: 0xBC/255.0, blue: 0xFF/255.0, alpha: 1.0), for: .normal)
                        actionBtn.titleLabel?.font = .boldSystemFont(ofSize: 14)
                        actionBtn.accessibilityIdentifier = snackId
                        actionBtn.addTarget(self, action: #selector(handleSnackBarAction(_:)), for: .touchUpInside)
                        hStack.addArrangedSubview(actionBtn)
                    }

                    if showCloseIcon {
                        let closeBtn = UIButton(type: .system)
                        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
                        closeBtn.tintColor = .white
                        closeBtn.accessibilityIdentifier = snackId
                        closeBtn.addTarget(self, action: #selector(handleSnackBarDismiss(_:)), for: .touchUpInside)
                        hStack.addArrangedSubview(closeBtn)
                    }

                    snackView.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(snackView)
                    NSLayoutConstraint.activate([
                        snackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: behavior == "floating" ? 16 : 0),
                        snackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: behavior == "floating" ? -16 : 0),
                        snackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: behavior == "floating" ? -16 : 0)
                    ])
                }
                return container
            }

            else if type == "SingleChildScrollView" {
                let scrollView = UIScrollView()
                let direction = node["scrollDirection"] as? String ?? "vertical"
                let reverse = node["reverse"] as? Bool ?? false

                scrollView.showsVerticalScrollIndicator = direction == "vertical"
                scrollView.showsHorizontalScrollIndicator = direction == "horizontal"

                if let children = node["children"] as? [[String: Any]], let firstChild = children.first {
                    let childView = renderWidget(node: firstChild)
                    childView.translatesAutoresizingMaskIntoConstraints = false
                    scrollView.addSubview(childView)

                    NSLayoutConstraint.activate([
                        childView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                        childView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                        childView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                        childView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
                    ])

                    if direction == "vertical" {
                        childView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
                    } else {
                        childView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true
                    }
                }

                if reverse {
                    scrollView.transform = CGAffineTransform(scaleX: direction == "horizontal" ? -1 : 1, y: direction == "vertical" ? -1 : 1)
                }
                return scrollView
            }

            else if type == "ListView" {
                let scrollView = UIScrollView()
                let direction = node["scrollDirection"] as? String ?? "vertical"
                let reverse = node["reverse"] as? Bool ?? false

                scrollView.showsVerticalScrollIndicator = direction == "vertical"
                scrollView.showsHorizontalScrollIndicator = direction == "horizontal"

                let stackView = UIStackView()
                stackView.axis = direction == "vertical" ? .vertical : .horizontal
                stackView.spacing = 0
                stackView.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(stackView)

                NSLayoutConstraint.activate([
                    stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                    stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                    stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
                ])

                if direction == "vertical" {
                    stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
                } else {
                    stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true
                }

                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        stackView.addArrangedSubview(renderWidget(node: child))
                    }
                }

                if reverse {
                    scrollView.transform = CGAffineTransform(scaleX: direction == "horizontal" ? -1 : 1, y: direction == "vertical" ? -1 : 1)
                }
                return scrollView
            }

            else if type == "CustomScrollView" {
                let scrollView = UIScrollView()
                let direction = node["scrollDirection"] as? String ?? "vertical"
                let reverse = node["reverse"] as? Bool ?? false

                scrollView.showsVerticalScrollIndicator = direction == "vertical"
                scrollView.showsHorizontalScrollIndicator = direction == "horizontal"

                let stackView = UIStackView()
                stackView.axis = direction == "vertical" ? .vertical : .horizontal
                stackView.spacing = 0
                stackView.translatesAutoresizingMaskIntoConstraints = false
                scrollView.addSubview(stackView)

                NSLayoutConstraint.activate([
                    stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                    stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                    stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
                ])

                if direction == "vertical" {
                    stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
                } else {
                    stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true
                }

                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        stackView.addArrangedSubview(renderWidget(node: child))
                    }
                }

                if reverse {
                    scrollView.transform = CGAffineTransform(scaleX: direction == "horizontal" ? -1 : 1, y: direction == "vertical" ? -1 : 1)
                }
                return scrollView
            }

            else if type == "SliverList" {
                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.spacing = 0

                if let children = node["children"] as? [[String: Any]] {
                    for child in children {
                        stackView.addArrangedSubview(renderWidget(node: child))
                    }
                }
                return stackView
            }

            else if type == "SliverAppBar" {
                let header = UIView()
                header.backgroundColor = .systemBackground

                let expandedHeight = CGFloat(node["expandedHeight"] as? Double ?? 120.0)
                header.heightAnchor.constraint(equalToConstant: expandedHeight).isActive = true

                let titleLabel = UILabel()
                titleLabel.text = node["title"] as? String ?? ""
                titleLabel.font = .boldSystemFont(ofSize: 28)
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                header.addSubview(titleLabel)

                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
                    titleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
                    titleLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16)
                ])

                return header
            }

            else {
                let fallback = UILabel()
                fallback.text = "[Unknown Widget: \(type)]"
                fallback.textColor = .systemRed
                return fallback
            }
        }
    
        @objc private func handleSegmentChange(_ sender: UISegmentedControl) {
            guard let tabId = sender.accessibilityIdentifier else { return }
            print("👆 Tab Segment changed to \(sender.selectedSegmentIndex)")
            sendActionToDart(buttonId: tabId, index: sender.selectedSegmentIndex)
        }
        
        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let navId = tabBar.accessibilityIdentifier else { return }
            print("👆 Tab Bar item selected: \(item.tag)")
            sendActionToDart(buttonId: navId, index: item.tag)
        }
        
        @objc private func handleDrawerItemTap(_ sender: UIButton) {
            guard let drawerId = sender.accessibilityIdentifier else { return }
            print("👆 Navigation item selected: \(sender.tag)")
            sendActionToDart(buttonId: drawerId, index: sender.tag)
        }
        
        @objc private func handleTap(_ sender: ActionTapGesture) {
            guard let buttonId = sender.buttonId else {
                print("❌ Tap registered, but buttonId was nil!")
                return
            }
            print("👆 Button Tapped! Triggering action for ID: \(buttonId)")
            sendActionToDart(buttonId: buttonId)
        }
        
        @objc private func handleSwitchChange(_ sender: UISwitch) {
            guard let switchId = sender.accessibilityIdentifier else { return }
            print("👆 Switch toggled to \(sender.isOn)")
            sendActionToDart(buttonId: switchId, value: sender.isOn)
        }
        
        @objc private func handleCheckboxTap(_ sender: UIButton) {
            guard let checkboxId = sender.accessibilityIdentifier else { return }
            let currentState = sender.currentImage == UIImage(systemName: "checkmark.square.fill")
            let newState = !currentState
            sender.setImage(UIImage(systemName: newState ? "checkmark.square.fill" : "square"), for: .normal)
            print("👆 Checkbox toggled to \(newState)")
            sendActionToDart(buttonId: checkboxId, value: newState)
        }
        
        @objc private func handleRadioTap(_ sender: UIButton) {
            guard let radioId = sender.accessibilityIdentifier else { return }
            print("👆 Radio selected")
            sendActionToDart(buttonId: radioId)
        }
        
        @objc private func handleSliderChange(_ sender: UISlider) {
            guard let sliderId = sender.accessibilityIdentifier else { return }
            print("👆 Slider changed to \(sender.value)")
            sendActionToDart(buttonId: sliderId, value: Double(sender.value))
        }
        
        @objc private func handleSnackBarAction(_ sender: UIButton) {
            guard let snackId = sender.accessibilityIdentifier else { return }
            print("👆 SnackBar action tapped")
            sendActionToDart(buttonId: snackId, value: "action")
        }
        
        @objc private func handleSnackBarDismiss(_ sender: UIButton) {
            guard let snackId = sender.accessibilityIdentifier else { return }
            print("👆 SnackBar dismissed")
            sendActionToDart(buttonId: snackId, value: "dismiss")
        }
        
        @objc private func handleChipTap(_ sender: UIButton) {
            guard let chipId = sender.accessibilityIdentifier else { return }
            print("👆 Chip tapped")
            sendActionToDart(buttonId: chipId)
        }
        
        @objc private func handleTextFieldChange(_ sender: UITextField) {
            guard let fieldId = sender.accessibilityIdentifier else { return }
            print("👆 TextField changed to \(sender.text ?? "")")
            if fieldId == "tf_new_task" {
                self.newTaskTitle = sender.text ?? ""
            } else {
                sendActionToDart(buttonId: fieldId, value: sender.text ?? "")
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            if textField.accessibilityIdentifier == "tf_new_task" {
                self.newTaskTitle = textField.text ?? ""
                self.sendActionToDart(buttonId: "btn_submit_task")
            }
            return true
        }
        
        @objc private func handleSearchSuggestionTap(_ sender: UIButton) {
            guard let searchId = sender.accessibilityIdentifier else { return }
            let text = sender.title(for: .normal) ?? ""
            print("👆 Search suggestion tapped: \(text)")
            sendActionToDart(buttonId: searchId, index: sender.tag, value: text)
        }
        
        @objc private func handleMenuBarTap(_ sender: UIButton) {
            guard let menuId = sender.accessibilityIdentifier else { return }
            print("👆 Menu bar item tapped: \(sender.tag)")
            sendActionToDart(buttonId: menuId, index: sender.tag)
        }
        
        private func colorFromARGB(_ argb: Int) -> UIColor {
            let a = CGFloat((argb >> 24) & 0xFF) / 255.0
            let r = CGFloat((argb >> 16) & 0xFF) / 255.0
            let g = CGFloat((argb >> 8) & 0xFF) / 255.0
            let b = CGFloat(argb & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
        private func sendActionToDart(buttonId: String, index: Int? = nil, value: Any? = nil) {
            if !useRemoteServer {
                handleLocalAction(id: buttonId, value: value)
                return
            }
            guard let url = URL(string: "https://custom-frameworks-neon-framework.iix8qf.easypanel.host/action") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var body: [String: Any] = ["id": buttonId]
            if let index = index {
                body["index"] = index
            }
            if let value = value {
                body["value"] = value
            }
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            print("🚀 Sending POST request to Dart engine...")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    return
                }
                
                guard let self = self, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ Failed to parse new UI JSON from Dart")
                    return
                }
                
                print("✅ Received response from Dart.")
                
                DispatchQueue.main.async {
                    // Check if the response is a valid widget tree (must have a "type" field)
                    if json["type"] != nil {
                        print("🎨 Response is a widget tree. Redrawing screen!")
                        self.view.subviews.forEach { $0.removeFromSuperview() }
                        
                        let rootView = self.renderWidget(node: json)
                        rootView.translatesAutoresizingMaskIntoConstraints = false
                        self.view.addSubview(rootView)
                        
                        NSLayoutConstraint.activate([
                            rootView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                            rootView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
                        ])
                    } else {
                        print("ℹ️ Response is not a widget tree (likely a status message). Fetching full tree...")
                        self.fetchUiTree()
                    }
                }
            }
            task.resume()
        }
}

class ActionTapGesture: UITapGestureRecognizer {
    var buttonId: String? // Changed to match your Dart logic
}
