package com.neon.myapp

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : Activity() {

  companion object {
    private const val BASE_URL = "https://custom-frameworks-neon-framework.iix8qf.easypanel.host"
    // Set to false for 100% standalone, offline-capable release APK with zero localhost dependency.
    private const val USE_REMOTE_SERVER = false
  }

  // In-Memory & Persistent State for To-Do List App (Neon Task Studio)
  data class TodoItemData(
    val id: String,
    val title: String,
    var isCompleted: Boolean,
    val priority: String, // "low", "medium", "high"
    val category: String, // "Work", "Personal", etc.
    val createdAt: Long = System.currentTimeMillis()
  )

  private var todoTasks = mutableListOf<TodoItemData>()
  private var newTaskTitle = ""
  private var selectedPriority = "medium"
  private var selectedCategory = "Work"
  private var filterStatus = "all" // "all", "active", "completed"
  private var activeCategoryFilter = "All"
  private val categories = listOf("Work", "Personal", "Study", "Shopping", "Health")

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    loadLocalTasks()

    if (USE_REMOTE_SERVER) {
      val loadingText = TextView(this)
      loadingText.text = "Connecting to Neon Engine..."
      loadingText.gravity = Gravity.CENTER
      loadingText.textSize = 20f
      setContentView(loadingText)
      fetchUiTree()
    } else {
      renderLocalTree()
    }
  }

  private fun loadLocalTasks() {
    val prefs = getSharedPreferences("neon_todo_prefs", MODE_PRIVATE)
    val raw = prefs.getString("tasks_json", null)
    if (raw != null) {
      try {
        val array = JSONArray(raw)
        todoTasks.clear()
        for (i in 0 until array.length()) {
          val obj = array.getJSONObject(i)
          todoTasks.add(
            TodoItemData(
              id = obj.getString("id"),
              title = obj.getString("title"),
              isCompleted = obj.getBoolean("isCompleted"),
              priority = obj.optString("priority", "medium"),
              category = obj.optString("category", "Work"),
              createdAt = obj.optLong("createdAt", System.currentTimeMillis())
            )
          )
        }
        if (todoTasks.isNotEmpty()) return
      } catch (e: Exception) {
        e.printStackTrace()
      }
    }
    // Default initial tasks matching todo_screen.dart
    todoTasks = mutableListOf(
      TodoItemData("task_1", "Explore Neon Framework architecture", true, "high", "Work"),
      TodoItemData("task_2", "Build custom mobile app with Neon SDK", false, "high", "Work"),
      TodoItemData("task_3", "Design native Android bridge and UI tree", false, "medium", "Study"),
      TodoItemData("task_4", "Review local storage & networking layers", false, "low", "Personal")
    )
  }

  private fun saveLocalTasks() {
    val prefs = getSharedPreferences("neon_todo_prefs", MODE_PRIVATE)
    val array = JSONArray()
    for (t in todoTasks) {
      val obj = JSONObject()
      obj.put("id", t.id)
      obj.put("title", t.title)
      obj.put("isCompleted", t.isCompleted)
      obj.put("priority", t.priority)
      obj.put("category", t.category)
      obj.put("createdAt", t.createdAt)
      array.put(obj)
    }
    prefs.edit().putString("tasks_json", array.toString()).apply()
  }

  private fun renderLocalTree() {
    val tree = buildTodoTree()
    val rootView = renderWidget(tree)
    rootView.layoutParams = ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    )
    setContentView(rootView)
  }

  private fun buildTodoTree(): JSONObject {
    val totalCount = todoTasks.size
    val completedCount = todoTasks.count { it.isCompleted }
    val activeCount = totalCount - completedCount
    val progress = if (totalCount > 0) completedCount.toDouble() / totalCount.toDouble() else 0.0
    val percentInt = (progress * 100).toInt()

    val filteredList = todoTasks.filter { task ->
      if (filterStatus == "active" && task.isCompleted) return@filter false
      if (filterStatus == "completed" && !task.isCompleted) return@filter false
      if (activeCategoryFilter != "All" && task.category != activeCategoryFilter) return@filter false
      true
    }

    val root = JSONObject().apply {
      put("id", "root")
      put("type", "Column")
      put("sourceType", "TodoApp")
      put("axis", "vertical")
    }

    val rootChildren = JSONArray()

    // 1. AppBar
    val appBar = JSONObject().apply {
      put("id", "appbar_todo")
      put("type", "AppBar")
      put("sourceType", "AppBar")
      put("variant", "small")
      put("title", "Neon Task Studio")
      val actions = JSONArray()
      val badge = JSONObject().apply {
        put("type", "Badge")
        put("label", "$activeCount")
      }
      actions.put(badge)
      put("actions", actions)
      put("children", JSONArray())
    }
    rootChildren.put(appBar)

    // 2. Expanded Container with ScrollView
    val expanded = JSONObject().apply {
      put("id", "root.1")
      put("type", "Expanded")
      put("sourceType", "Expanded")
      put("flex", 1)

      val expChildren = JSONArray()
      val container = JSONObject().apply {
        put("id", "root.1.0")
        put("type", "Container")
        put("sourceType", "Container")
        put("color", 0xFFF1F5F9.toLong())
        put("padding_top", 12.0)
        put("padding_bottom", 12.0)
        put("padding_left", 16.0)
        put("padding_right", 16.0)

        val contChildren = JSONArray()
        val scrollView = JSONObject().apply {
          put("id", "root.1.0.0")
          put("type", "SingleChildScrollView")
          put("sourceType", "SingleChildScrollView")
          put("scrollDirection", "vertical")
          put("padding_bottom", 24.0)

          val scrollChildren = JSONArray()
          val col = JSONObject().apply {
            put("id", "root.1.0.0.0")
            put("type", "Column")
            put("sourceType", "Column")
            put("axis", "vertical")

            val items = JSONArray()

            // Card 1: Progress Overview Card
            val cardProg = JSONObject().apply {
              put("id", "card_progress")
              put("type", "Card")
              put("sourceType", "Card")
              put("variant", "elevated")
              put("borderRadius", 14.0)
              put("color", 0xFFFFFFFF.toLong())
              put("padding_top", 16.0)
              put("padding_bottom", 16.0)
              put("padding_left", 16.0)
              put("padding_right", 16.0)

              val cpChildren = JSONArray()
              val cpCol = JSONObject().apply {
                put("id", "card_progress.0")
                put("type", "Column")
                put("axis", "vertical")
                val cpItems = JSONArray()

                val rowHeader = JSONObject().apply {
                  put("id", "card_progress.0.0")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val rItems = JSONArray()
                  rItems.put(JSONObject().apply {
                    put("id", "card_progress.0.0.0")
                    put("type", "Text")
                    put("text", "Progress Overview")
                    put("fontSize", 16.0)
                    put("fontWeight", "bold")
                    put("color", 0xFF1E293B.toLong())
                    put("children", JSONArray())
                  })
                  rItems.put(JSONObject().apply {
                    put("id", "card_progress.0.0.1")
                    put("type", "Text")
                    put("text", "$percentInt% done ($completedCount/$totalCount)")
                    put("fontSize", 13.0)
                    put("fontWeight", "bold")
                    put("color", 0xFF4F46E5.toLong())
                    put("children", JSONArray())
                  })
                  put("children", rItems)
                }
                cpItems.put(rowHeader)

                cpItems.put(JSONObject().apply {
                  put("id", "card_progress.0.1")
                  put("type", "SizedBox")
                  put("height", 10.0)
                  put("children", JSONArray())
                })

                cpItems.put(JSONObject().apply {
                  put("id", "progress_bar")
                  put("type", "LinearProgressIndicator")
                  put("value", progress)
                  put("minHeight", 8.0)
                  put("borderRadius", 4.0)
                  put("color", 0xFF4F46E5.toLong())
                  put("backgroundColor", 0xFFE2E8F0.toLong())
                  put("children", JSONArray())
                })

                cpItems.put(JSONObject().apply {
                  put("id", "card_progress.0.3")
                  put("type", "SizedBox")
                  put("height", 12.0)
                  put("children", JSONArray())
                })

                val rowCounts = JSONObject().apply {
                  put("id", "card_progress.0.4")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val cntItems = JSONArray()
                  cntItems.put(JSONObject().apply {
                    put("id", "card_progress.0.4.0")
                    put("type", "Text")
                    put("text", "Total: $totalCount")
                    put("fontSize", 12.0)
                    put("color", 0xFF64748B.toLong())
                    put("children", JSONArray())
                  })
                  cntItems.put(JSONObject().apply {
                    put("id", "card_progress.0.4.1")
                    put("type", "Text")
                    put("text", "Active: $activeCount")
                    put("fontSize", 12.0)
                    put("fontWeight", "bold")
                    put("color", 0xFF0EA5E9.toLong())
                    put("children", JSONArray())
                  })
                  cntItems.put(JSONObject().apply {
                    put("id", "card_progress.0.4.2")
                    put("type", "Text")
                    put("text", "Done: $completedCount")
                    put("fontSize", 12.0)
                    put("fontWeight", "bold")
                    put("color", 0xFF10B981.toLong())
                    put("children", JSONArray())
                  })
                  put("children", cntItems)
                }
                cpItems.put(rowCounts)
                put("children", cpItems)
              }
              cpChildren.put(cpCol)
              put("children", cpChildren)
            }
            items.put(cardProg)

            items.put(JSONObject().apply {
              put("type", "SizedBox")
              put("height", 16.0)
              put("children", JSONArray())
            })

            // Card 2: Create New Task Card
            val cardAdd = JSONObject().apply {
              put("id", "card_add_task")
              put("type", "Card")
              put("sourceType", "Card")
              put("variant", "elevated")
              put("borderRadius", 14.0)
              put("color", 0xFFFFFFFF.toLong())
              put("padding_top", 16.0)
              put("padding_bottom", 16.0)
              put("padding_left", 16.0)
              put("padding_right", 16.0)

              val caChildren = JSONArray()
              val caCol = JSONObject().apply {
                put("id", "card_add_task.0")
                put("type", "Column")
                put("axis", "vertical")
                val caItems = JSONArray()

                caItems.put(JSONObject().apply {
                  put("id", "card_add_task.0.0")
                  put("type", "Text")
                  put("text", "Create New Task")
                  put("fontSize", 16.0)
                  put("fontWeight", "bold")
                  put("color", 0xFF1E293B.toLong())
                  put("children", JSONArray())
                })

                caItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("height", 10.0)
                  put("children", JSONArray())
                })

                caItems.put(JSONObject().apply {
                  put("id", "tf_new_task")
                  put("type", "TextField")
                  put("variant", "outlined")
                  put("value", newTaskTitle)
                  put("labelText", "Task Description")
                  put("hintText", "e.g. Test iOS native bridge...")
                  put("children", JSONArray())
                })

                caItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("height", 12.0)
                  put("children", JSONArray())
                })

                caItems.put(JSONObject().apply {
                  put("type", "Text")
                  put("text", "Priority:")
                  put("fontSize", 12.0)
                  put("fontWeight", "bold")
                  put("color", 0xFF64748B.toLong())
                  put("children", JSONArray())
                })

                val prioRow = JSONObject().apply {
                  put("id", "card_add_task.0.6")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val prItems = JSONArray()
                  val prios = listOf("low" to "Low", "medium" to "Medium", "high" to "High")
                  for ((pKey, pLabel) in prios) {
                    prItems.put(JSONObject().apply {
                      put("id", "chip_prio_$pKey")
                      put("type", "FilterChip")
                      put("label", pLabel)
                      put("selected", selectedPriority == pKey)
                      put("children", JSONArray())
                    })
                    prItems.put(JSONObject().apply {
                      put("type", "SizedBox")
                      put("width", 8.0)
                      put("children", JSONArray())
                    })
                  }
                  put("children", prItems)
                }
                caItems.put(prioRow)

                caItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("height", 12.0)
                  put("children", JSONArray())
                })

                caItems.put(JSONObject().apply {
                  put("type", "Text")
                  put("text", "Category:")
                  put("fontSize", 12.0)
                  put("fontWeight", "bold")
                  put("color", 0xFF64748B.toLong())
                  put("children", JSONArray())
                })

                val catRow = JSONObject().apply {
                  put("id", "card_add_task.0.10")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val catItems = JSONArray()
                  for (cat in categories) {
                    catItems.put(JSONObject().apply {
                      put("id", "chip_cat_$cat")
                      put("type", "FilterChip")
                      put("label", cat)
                      put("selected", selectedCategory == cat)
                      put("children", JSONArray())
                    })
                    catItems.put(JSONObject().apply {
                      put("type", "SizedBox")
                      put("width", 6.0)
                      put("children", JSONArray())
                    })
                  }
                  put("children", catItems)
                }
                caItems.put(catRow)

                caItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("height", 14.0)
                  put("children", JSONArray())
                })

                val submitBtn = JSONObject().apply {
                  put("id", "btn_submit_task")
                  put("type", "Container")
                  put("sourceType", "Button")
                  put("color", 0xFF4F46E5.toLong())
                  put("isButton", true)
                  put("padding_top", 12.0)
                  put("padding_bottom", 12.0)
                  put("padding_left", 16.0)
                  put("padding_right", 16.0)
                  val btnChildren = JSONArray()
                  btnChildren.put(JSONObject().apply {
                    put("id", "btn_submit_task.0")
                    put("type", "Text")
                    put("text", "+ Add Task to List")
                    put("color", 0xFFFFFFFF.toLong())
                    put("fontWeight", "bold")
                    put("children", JSONArray())
                  })
                  put("children", btnChildren)
                }
                caItems.put(submitBtn)

                put("children", caItems)
              }
              caChildren.put(caCol)
              put("children", caChildren)
            }
            items.put(cardAdd)

            items.put(JSONObject().apply {
              put("type", "SizedBox")
              put("height", 16.0)
              put("children", JSONArray())
            })

            // Card 3: Filter Controls Card
            val cardFilt = JSONObject().apply {
              put("id", "card_filters")
              put("type", "Card")
              put("sourceType", "Card")
              put("variant", "elevated")
              put("borderRadius", 14.0)
              put("color", 0xFFFFFFFF.toLong())
              put("padding_top", 10.0)
              put("padding_bottom", 10.0)
              put("padding_left", 14.0)
              put("padding_right", 14.0)

              val cfChildren = JSONArray()
              val cfCol = JSONObject().apply {
                put("id", "card_filters.0")
                put("type", "Column")
                put("axis", "vertical")
                val cfItems = JSONArray()

                val sfRow = JSONObject().apply {
                  put("id", "card_filters.0.0")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val sfItems = JSONArray()
                  val statuses = listOf(
                    Triple("all", "All ($totalCount)", filterStatus == "all"),
                    Triple("active", "Active ($activeCount)", filterStatus == "active"),
                    Triple("done", "Done ($completedCount)", filterStatus == "completed")
                  )
                  for ((sKey, sLabel, sSel) in statuses) {
                    sfItems.put(JSONObject().apply {
                      put("id", "filter_status_$sKey")
                      put("type", "FilterChip")
                      put("label", sLabel)
                      put("selected", sSel)
                      put("children", JSONArray())
                    })
                    sfItems.put(JSONObject().apply {
                      put("type", "SizedBox")
                      put("width", 8.0)
                      put("children", JSONArray())
                    })
                  }
                  put("children", sfItems)
                }
                cfItems.put(sfRow)

                cfItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("height", 8.0)
                  put("children", JSONArray())
                })

                val tagRow = JSONObject().apply {
                  put("id", "card_filters.0.2")
                  put("type", "Row")
                  put("axis", "horizontal")
                  val tagItems = JSONArray()
                  tagItems.put(JSONObject().apply {
                    put("id", "filter_cat_all")
                    put("type", "FilterChip")
                    put("label", "🏷️ All Tags")
                    put("selected", activeCategoryFilter == "All")
                    put("children", JSONArray())
                  })
                  tagItems.put(JSONObject().apply {
                    put("type", "SizedBox")
                    put("width", 6.0)
                    put("children", JSONArray())
                  })
                  for (cat in categories) {
                    tagItems.put(JSONObject().apply {
                      put("id", "filter_cat_$cat")
                      put("type", "FilterChip")
                      put("label", cat)
                      put("selected", activeCategoryFilter == cat)
                      put("children", JSONArray())
                    })
                    tagItems.put(JSONObject().apply {
                      put("type", "SizedBox")
                      put("width", 6.0)
                      put("children", JSONArray())
                    })
                  }
                  put("children", tagItems)
                }
                cfItems.put(tagRow)

                put("children", cfItems)
              }
              cfChildren.put(cfCol)
              put("children", cfChildren)
            }
            items.put(cardFilt)

            items.put(JSONObject().apply {
              put("type", "SizedBox")
              put("height", 16.0)
              put("children", JSONArray())
            })

            // Row 4: Tasks (N) Header + Actions
            val taskHeader = JSONObject().apply {
              put("id", "root.1.0.0.0.6")
              put("type", "Row")
              put("axis", "horizontal")
              val thItems = JSONArray()
              thItems.put(JSONObject().apply {
                put("id", "root.1.0.0.0.6.0")
                put("type", "Text")
                put("text", "Tasks (${filteredList.size})")
                put("fontSize", 18.0)
                put("fontWeight", "bold")
                put("color", 0xFF1E293B.toLong())
                put("children", JSONArray())
              })

              val actionsRow = JSONObject().apply {
                put("id", "root.1.0.0.0.6.1")
                put("type", "Row")
                put("axis", "horizontal")
                val actItems = JSONArray()

                val toggleText = if (activeCount == 0) "Reset" else "Check All"
                actItems.put(JSONObject().apply {
                  put("id", "btn_toggle_all_tasks")
                  put("type", "Container")
                  put("sourceType", "Button")
                  put("color", 0xFF64748B.toLong())
                  put("isButton", true)
                  put("padding_top", 8.0)
                  put("padding_bottom", 8.0)
                  put("padding_left", 12.0)
                  put("padding_right", 12.0)
                  val btnChild = JSONArray()
                  btnChild.put(JSONObject().apply {
                    put("type", "Text")
                    put("text", toggleText)
                    put("color", 0xFFFFFFFF.toLong())
                    put("fontSize", 12.0)
                    put("children", JSONArray())
                  })
                  put("children", btnChild)
                })

                actItems.put(JSONObject().apply {
                  put("type", "SizedBox")
                  put("width", 8.0)
                  put("children", JSONArray())
                })

                actItems.put(JSONObject().apply {
                  put("id", "btn_clear_completed_tasks")
                  put("type", "Container")
                  put("sourceType", "Button")
                  put("color", 0xFFEF4444.toLong())
                  put("isButton", true)
                  put("padding_top", 8.0)
                  put("padding_bottom", 8.0)
                  put("padding_left", 12.0)
                  put("padding_right", 12.0)
                  val btnChild = JSONArray()
                  btnChild.put(JSONObject().apply {
                    put("type", "Text")
                    put("text", "Clear Done")
                    put("color", 0xFFFFFFFF.toLong())
                    put("fontSize", 12.0)
                    put("children", JSONArray())
                  })
                  put("children", btnChild)
                })

                put("children", actItems)
              }
              thItems.put(actionsRow)
              put("children", thItems)
            }
            items.put(taskHeader)

            items.put(JSONObject().apply {
              put("type", "SizedBox")
              put("height", 10.0)
              put("children", JSONArray())
            })

            // 5. Tasks List or Empty State
            if (filteredList.isEmpty()) {
              val cardEmpty = JSONObject().apply {
                put("id", "card_empty_state")
                put("type", "Card")
                put("sourceType", "Card")
                put("variant", "elevated")
                put("borderRadius", 14.0)
                put("color", 0xFFFFFFFF.toLong())
                put("padding_top", 32.0)
                put("padding_bottom", 32.0)
                put("padding_left", 32.0)
                put("padding_right", 32.0)
                val ceChildren = JSONArray()
                val ceCol = JSONObject().apply {
                  put("type", "Column")
                  put("axis", "vertical")
                  val ceItems = JSONArray()
                  ceItems.put(JSONObject().apply {
                    put("type", "Text")
                    put("text", "🎉")
                    put("fontSize", 36.0)
                    put("children", JSONArray())
                  })
                  ceItems.put(JSONObject().apply {
                    put("type", "SizedBox")
                    put("height", 8.0)
                    put("children", JSONArray())
                  })
                  ceItems.put(JSONObject().apply {
                    put("type", "Text")
                    put("text", "No Tasks Found")
                    put("fontSize", 16.0)
                    put("fontWeight", "bold")
                    put("color", 0xFF1E293B.toLong())
                    put("children", JSONArray())
                  })
                  ceItems.put(JSONObject().apply {
                    put("type", "SizedBox")
                    put("height", 4.0)
                    put("children", JSONArray())
                  })
                  val hintMsg = if (todoTasks.isEmpty()) "Add your first task above to get started!" else "Try changing your status or category filters."
                  ceItems.put(JSONObject().apply {
                    put("type", "Text")
                    put("text", hintMsg)
                    put("fontSize", 13.0)
                    put("color", 0xFF64748B.toLong())
                    put("children", JSONArray())
                  })
                  put("children", ceItems)
                }
                ceChildren.put(ceCol)
                put("children", ceChildren)
              }
              items.put(cardEmpty)
            } else {
              val taskCol = JSONObject().apply {
                put("id", "root.1.0.0.0.8")
                put("type", "Column")
                put("axis", "vertical")
                val tItems = JSONArray()
                for (item in filteredList) {
                  val taskCard = JSONObject().apply {
                    put("id", "card_task_${item.id}")
                    put("type", "Card")
                    put("sourceType", "Card")
                    put("variant", "elevated")
                    put("borderRadius", 12.0)
                    val cardBg = if (item.isCompleted) 0xFFF8FAFC.toLong() else 0xFFFFFFFF.toLong()
                    put("color", cardBg)
                    put("padding_top", 10.0)
                    put("padding_bottom", 10.0)
                    put("padding_left", 12.0)
                    put("padding_right", 12.0)

                    val tcChildren = JSONArray()
                    val tRow = JSONObject().apply {
                      put("id", "card_task_${item.id}.0")
                      put("type", "Row")
                      put("axis", "horizontal")
                      val trItems = JSONArray()

                      // Checkbox
                      trItems.put(JSONObject().apply {
                        put("id", "cb_task_${item.id}")
                        put("type", "Checkbox")
                        put("value", item.isCompleted)
                        put("enabled", true)
                        put("children", JSONArray())
                      })

                      trItems.put(JSONObject().apply {
                        put("type", "SizedBox")
                        put("width", 12.0)
                        put("children", JSONArray())
                      })

                      // Expanded Task Details
                      val expDetails = JSONObject().apply {
                        put("type", "Expanded")
                        put("flex", 1)
                        val edChildren = JSONArray()
                        val edCol = JSONObject().apply {
                          put("type", "Column")
                          put("axis", "vertical")
                          val edItems = JSONArray()

                          val titleText = if (item.isCompleted) "✓ ${item.title}" else item.title
                          val titleColor = if (item.isCompleted) 0xFF94A3B8.toLong() else 0xFF0F172A.toLong()
                          val titleWeight = if (item.isCompleted) "normal" else "bold"
                          edItems.put(JSONObject().apply {
                            put("type", "Text")
                            put("text", titleText)
                            put("fontSize", 15.0)
                            put("fontWeight", titleWeight)
                            put("color", titleColor)
                            put("children", JSONArray())
                          })

                          edItems.put(JSONObject().apply {
                            put("type", "SizedBox")
                            put("height", 4.0)
                            put("children", JSONArray())
                          })

                          val subRow = JSONObject().apply {
                            put("type", "Row")
                            put("axis", "horizontal")
                            val srItems = JSONArray()
                            val prioBadge = when (item.priority) {
                              "high" -> "🔴 High"
                              "low" -> "🟢 Low"
                              else -> "🟡 Med"
                            }
                            srItems.put(JSONObject().apply {
                              put("type", "Text")
                              put("text", prioBadge)
                              put("fontSize", 11.0)
                              put("fontWeight", "bold")
                              put("color", 0xFF475569.toLong())
                              put("children", JSONArray())
                            })
                            srItems.put(JSONObject().apply {
                              put("type", "SizedBox")
                              put("width", 8.0)
                              put("children", JSONArray())
                            })
                            srItems.put(JSONObject().apply {
                              put("type", "Text")
                              put("text", "🏷️ ${item.category}")
                              put("fontSize", 11.0)
                              put("color", 0xFF64748B.toLong())
                              put("children", JSONArray())
                            })
                            put("children", srItems)
                          }
                          edItems.put(subRow)

                          put("children", edItems)
                        }
                        edChildren.put(edCol)
                        put("children", edChildren)
                      }
                      trItems.put(expDetails)

                      trItems.put(JSONObject().apply {
                        put("type", "SizedBox")
                        put("width", 8.0)
                        put("children", JSONArray())
                      })

                      // Delete Button (✕)
                      val delBtn = JSONObject().apply {
                        put("id", "btn_del_${item.id}")
                        put("type", "Container")
                        put("sourceType", "Button")
                        put("color", 0xFFFEE2E2.toLong())
                        put("isButton", true)
                        put("padding_top", 6.0)
                        put("padding_bottom", 6.0)
                        put("padding_left", 10.0)
                        put("padding_right", 10.0)
                        val dbChildren = JSONArray()
                        dbChildren.put(JSONObject().apply {
                          put("type", "Text")
                          put("text", "✕")
                          put("fontSize", 12.0)
                          put("fontWeight", "bold")
                          put("color", 0xFFDC2626.toLong())
                          put("children", JSONArray())
                        })
                        put("children", dbChildren)
                      }
                      trItems.put(delBtn)

                      put("children", trItems)
                    }
                    tcChildren.put(tRow)
                    put("children", tcChildren)
                  }
                  tItems.put(taskCard)
                  tItems.put(JSONObject().apply {
                    put("type", "SizedBox")
                    put("height", 8.0)
                    put("children", JSONArray())
                  })
                }
                put("children", tItems)
              }
              items.put(taskCol)
            }

            put("children", items)
          }
          scrollChildren.put(col)
          put("children", scrollChildren)
        }
        contChildren.put(scrollView)
        put("children", contChildren)
      }
      expChildren.put(container)
      put("children", expChildren)
    }
    rootChildren.put(expanded)

    root.put("children", rootChildren)
    return root
  }

  private fun handleLocalAction(id: String, value: Any? = null) {
    runOnUiThread {
      when {
        id == "btn_submit_task" -> {
          val title = newTaskTitle.trim()
          if (title.isNotEmpty()) {
            val newTask = TodoItemData(
              id = "task_${System.currentTimeMillis()}",
              title = title,
              isCompleted = false,
              priority = selectedPriority,
              category = selectedCategory
            )
            todoTasks.add(0, newTask)
            newTaskTitle = ""
            saveLocalTasks()
          }
        }
        id == "tf_new_task" -> {
          newTaskTitle = value?.toString() ?: ""
          return@runOnUiThread
        }
        id.startsWith("cb_task_") -> {
          val taskId = id.removePrefix("cb_task_")
          val task = todoTasks.find { it.id == taskId }
          if (task != null) {
            task.isCompleted = (value as? Boolean) ?: (!task.isCompleted)
            saveLocalTasks()
          }
        }
        id.startsWith("btn_del_") -> {
          val taskId = id.removePrefix("btn_del_")
          todoTasks.removeAll { it.id == taskId }
          saveLocalTasks()
        }
        id == "btn_clear_completed_tasks" -> {
          todoTasks.removeAll { it.isCompleted }
          saveLocalTasks()
        }
        id == "btn_toggle_all_tasks" -> {
          val hasUncompleted = todoTasks.any { !it.isCompleted }
          todoTasks.forEach { it.isCompleted = hasUncompleted }
          saveLocalTasks()
        }
        id == "chip_prio_low" -> selectedPriority = "low"
        id == "chip_prio_med" -> selectedPriority = "medium"
        id == "chip_prio_high" -> selectedPriority = "high"
        id.startsWith("chip_cat_") -> selectedCategory = id.removePrefix("chip_cat_")
        id == "filter_status_all" -> filterStatus = "all"
        id == "filter_status_active" -> filterStatus = "active"
        id == "filter_status_done" -> filterStatus = "completed"
        id == "filter_cat_all" -> activeCategoryFilter = "All"
        id.startsWith("filter_cat_") -> activeCategoryFilter = id.removePrefix("filter_cat_")
      }

      val newTree = buildTodoTree()
      val rootView = renderWidget(newTree)
      rootView.layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      )
      setContentView(rootView)
    }
  }

  private fun fetchUiTree() {
    thread {
      try {
        val cleanBaseUrl = BASE_URL.trimEnd('/')
        val url = URL("$cleanBaseUrl/api/tree")
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 8000
        connection.readTimeout = 12000
        connection.requestMethod = "GET"

        val reader = BufferedReader(InputStreamReader(connection.inputStream))
        val response = reader.readText()
        reader.close()

        val rootNode = JSONObject(response)
        val sourceType = rootNode.optString("sourceType")
        // If remote server returns framework showcase instead of TodoApp, use standalone local TodoApp!
        if (sourceType == "ShowcaseApp") {
          runOnUiThread { renderLocalTree() }
          return@thread
        }

        runOnUiThread {
          val rootView = renderWidget(rootNode)
          rootView.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
          )
          setContentView(rootView)
        }

      } catch (e: Exception) {
        runOnUiThread {
          renderLocalTree()
        }
      }
    }
  }

  private fun sendAction(id: String, index: Int? = null, value: Any? = null) {
    if (!USE_REMOTE_SERVER) {
      handleLocalAction(id, value)
      return
    }

    thread {
      try {
        val cleanBaseUrl = BASE_URL.trimEnd('/')
        val url = URL("$cleanBaseUrl/action")
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 8000
        connection.readTimeout = 12000
        connection.requestMethod = "POST"
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/json")

        val json = JSONObject()
        json.put("id", id)
        if (index != null) {
          json.put("index", index)
        }
        if (value != null) {
          json.put("value", value)
        }

        val os = connection.outputStream
        os.write(json.toString().toByteArray())
        os.close()

        val responseCode = connection.responseCode
        if (responseCode == 200) {
          val reader = BufferedReader(InputStreamReader(connection.inputStream))
          val response = reader.readText()
          reader.close()
          
          val rootNode = JSONObject(response)
          runOnUiThread {
            val rootView = renderWidget(rootNode)
            rootView.layoutParams = ViewGroup.LayoutParams(
              ViewGroup.LayoutParams.MATCH_PARENT,
              ViewGroup.LayoutParams.MATCH_PARENT
            )
            setContentView(rootView)
          }
        } else {
          handleLocalAction(id, value)
        }
      } catch (e: Exception) {
        handleLocalAction(id, value)
      }
    }
  }

  // Recursive function to turn JSON into Android Views
  private fun renderWidget(node: JSONObject): View {
    val type = node.optString("type")
    val sourceType = node.optString("sourceType")

    return when {
      type == "Expanded" -> {
        val frame = android.widget.FrameLayout(this)
        val flex = node.optInt("flex", 1)
        frame.layoutParams = LinearLayout.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.WRAP_CONTENT,
          flex.toFloat()
        )
        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
          val childView = renderWidget(children.getJSONObject(0))
          val childParams = android.widget.FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
          )
          childView.layoutParams = childParams
          frame.addView(childView)
        }
        frame
      }
      type == "Center" -> {
        val frame = android.widget.FrameLayout(this)
        frame.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
            val childView = renderWidget(children.getJSONObject(0))
            val params = android.widget.FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            params.gravity = Gravity.CENTER
            childView.layoutParams = params
            frame.addView(childView)
        }
        frame
      }
      type == "SizedBox" -> {
        val frame = android.widget.FrameLayout(this)
        val density = resources.displayMetrics.density
        val w = if (node.has("width")) (node.getDouble("width") * density).toInt() else ViewGroup.LayoutParams.WRAP_CONTENT
        val h = if (node.has("height")) (node.getDouble("height") * density).toInt() else ViewGroup.LayoutParams.WRAP_CONTENT
        frame.layoutParams = ViewGroup.LayoutParams(w, h)
        
        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
            frame.addView(renderWidget(children.getJSONObject(0)))
        }
        frame
      }
      type == "Spacer" -> {
        val spacer = View(this)
        val flex = node.optInt("flex", 1)
        spacer.layoutParams = LinearLayout.LayoutParams(0, 0, flex.toFloat())
        spacer
      }
      type == "Text" -> {
        val textView = TextView(this)
        textView.text = node.optString("text")
        
        if (node.has("fontSize")) {
          textView.textSize = node.getDouble("fontSize").toFloat()
        } else {
          textView.textSize = 14f
        }

        val fontWeight = node.optString("fontWeight")
        if (fontWeight == "bold") {
          textView.typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        
        textView.setPadding(0, 0, 0, 0)
        
        // Adjust text color
        if (node.has("color")) {
          textView.setTextColor(node.getInt("color"))
        } else if (sourceType == "OutlinedButton" || sourceType == "TextButton" || sourceType == "ElevatedButton") {
          textView.setTextColor(Color.BLUE)
        } else if (node.optBoolean("isButton")) {
          textView.setTextColor(Color.WHITE)
        } else {
          textView.setTextColor(0xFF1E293B.toInt())
        }
        textView
      }
      type.contains("Column") || type.contains("Row") -> {
        val isCol = type.contains("Column")
        val layout = LinearLayout(this)
        layout.orientation = if (isCol) LinearLayout.VERTICAL else LinearLayout.HORIZONTAL
        if (isCol) {
          layout.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
          )
        } else {
          layout.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
          )
          layout.gravity = Gravity.CENTER_VERTICAL
        }
        
        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            val childNode = children.getJSONObject(i)
            val childView = renderWidget(childNode)
            if (childNode.optString("type") == "Expanded") {
              val flex = childNode.optInt("flex", 1)
              if (isCol) {
                childView.layoutParams = LinearLayout.LayoutParams(
                  ViewGroup.LayoutParams.MATCH_PARENT,
                  0,
                  flex.toFloat()
                )
              } else {
                childView.layoutParams = LinearLayout.LayoutParams(
                  0,
                  ViewGroup.LayoutParams.WRAP_CONTENT,
                  flex.toFloat()
                )
              }
            }
            layout.addView(childView)
          }
        }
        layout
      }
      type == "SegmentedButton" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        layout.gravity = Gravity.CENTER
        layout.background = android.graphics.drawable.GradientDrawable().apply {
          setStroke(2, Color.GRAY)
          cornerRadius = 16f
        }
        val segments = node.optJSONArray("segments")
        val selectedIndex = node.optInt("selectedIndex", 0)
        val id = node.optString("id")
        
        if (segments != null) {
          for (i in 0 until segments.length()) {
            val label = TextView(this)
            label.text = segments.getString(i)
            label.setPadding(32, 16, 32, 16)
            if (i == selectedIndex) {
              label.setBackgroundColor(0xFFEADDFF.toInt())
            }
            val index = i
            label.setOnClickListener {
              if (id.isNotEmpty()) sendAction(id, index)
            }
            layout.addView(label)
          }
        }
        layout
      }
      type.contains("Container") || type.contains("Button") || node.optBoolean("isButton") -> {
        val container = android.widget.FrameLayout(this)
        val isButtonClickable = node.optBoolean("isButton") || type.contains("Button")

        // Material 3 Styling based on sourceType
        val background = android.graphics.drawable.GradientDrawable()
        background.shape = android.graphics.drawable.GradientDrawable.RECTANGLE
        background.cornerRadius = 12f

        when (sourceType) {
          "FilledTonalButton" -> background.setColor(0xFFEADDFF.toInt())
          "FloatingActionButton" -> {
            background.setColor(0xFFD0BCFF.toInt())
            background.cornerRadius = 32f
          }
          "ElevatedButton" -> {
            background.setColor(Color.WHITE)
            container.elevation = 8f
          }
          "OutlinedButton" -> {
            background.setColor(Color.TRANSPARENT)
            background.setStroke(2, Color.GRAY)
          }
          "TextButton" -> background.setColor(Color.TRANSPARENT)
          else -> {
            if (node.has("color")) {
              background.setColor(node.getInt("color"))
            } else if (isButtonClickable) {
              background.setColor(Color.BLUE)
            } else {
              background.setColor(0xFFEEEEEE.toInt())
            }
          }
        }
        container.background = background

        // Layout Params
        val density = resources.displayMetrics.density
        val width = if (node.has("width")) (node.getDouble("width") * density).toInt() else if (isButtonClickable) ViewGroup.LayoutParams.WRAP_CONTENT else ViewGroup.LayoutParams.MATCH_PARENT
        val height = if (node.has("height")) (node.getDouble("height") * density).toInt() else if (isButtonClickable) ViewGroup.LayoutParams.WRAP_CONTENT else ViewGroup.LayoutParams.MATCH_PARENT
        container.layoutParams = ViewGroup.MarginLayoutParams(width, height)

        // Padding
        val pLeft = (node.optDouble("padding_left", if (isButtonClickable) 16.0 else 0.0) * density).toInt()
        val pTop = (node.optDouble("padding_top", if (isButtonClickable) 12.0 else 0.0) * density).toInt()
        val pRight = (node.optDouble("padding_right", if (isButtonClickable) 16.0 else 0.0) * density).toInt()
        val pBottom = (node.optDouble("padding_bottom", if (isButtonClickable) 12.0 else 0.0) * density).toInt()
        container.setPadding(pLeft, pTop, pRight, pBottom)

        // Render child
        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
          val childView = renderWidget(children.getJSONObject(0))
          val params = android.widget.FrameLayout.LayoutParams(
            if (isButtonClickable) ViewGroup.LayoutParams.WRAP_CONTENT else ViewGroup.LayoutParams.MATCH_PARENT,
            if (isButtonClickable) ViewGroup.LayoutParams.WRAP_CONTENT else ViewGroup.LayoutParams.MATCH_PARENT
          )
          if (isButtonClickable) {
            params.gravity = Gravity.CENTER
          }
          childView.layoutParams = params
          container.addView(childView)
        }

        if (isButtonClickable) {
          container.setOnClickListener {
            container.alpha = 0.5f
            container.postDelayed({ container.alpha = 1.0f }, 100)
            val id = node.optString("id")
            if (id.isNotEmpty()) {
              if (id == "btn_submit_task") {
                val et = currentFocus as? android.widget.EditText
                if (et != null && et.text.isNotEmpty()) {
                  sendAction("tf_new_task", value = et.text.toString())
                  container.postDelayed({ sendAction(id) }, 100)
                  return@setOnClickListener
                }
              }
              sendAction(id)
            }
          }
        }
        container
      }
      type == "RemoteWidget" -> {
        val root = android.widget.FrameLayout(this)
        val loading = TextView(this)
        loading.text = "Loading Remote..."
        root.addView(loading)
        
        var urlStr = node.optString("url")
        if (urlStr.contains("localhost:8080") || urlStr.contains("127.0.0.1:8080")) {
          urlStr = urlStr.replace("http://localhost:8080", BASE_URL.trimEnd('/'))
                         .replace("http://127.0.0.1:8080", BASE_URL.trimEnd('/'))
        }
        if (urlStr.isNotEmpty()) {
          thread {
            try {
              val url = URL(urlStr)
              val conn = url.openConnection() as HttpURLConnection
              conn.connectTimeout = 10000
              conn.readTimeout = 15000
              val reader = BufferedReader(InputStreamReader(conn.inputStream))
              val resp = reader.readText()
              val remoteJson = JSONObject(resp)
              runOnUiThread {
                root.removeAllViews()
                root.addView(renderWidget(remoteJson))
              }
            } catch (e: Exception) {
              runOnUiThread { loading.text = "Error: ${e.message}" }
            }
          }
        }
        root
      }
      type == "NavigationBar" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        layout.gravity = Gravity.CENTER
        layout.setBackgroundColor(0xFFF3EDF7.toInt())
        val density = resources.displayMetrics.density
        layout.setPadding(0, (8 * density).toInt(), 0, (8 * density).toInt())
        
        val destinations = node.optJSONArray("destinations")
        val selectedIndex = node.optInt("selectedIndex", 0)
        val navBarId = node.optString("id")
        
        if (destinations != null) {
          for (i in 0 until destinations.length()) {
            val dest = destinations.getJSONObject(i)
            val itemLayout = LinearLayout(this)
            itemLayout.orientation = LinearLayout.VERTICAL
            itemLayout.gravity = Gravity.CENTER
            val params = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f)
            itemLayout.layoutParams = params
            
            val pill = View(this)
            val pillParams = LinearLayout.LayoutParams((64 * density).toInt(), (32 * density).toInt())
            pill.layoutParams = pillParams
            if (i == selectedIndex) {
              val shape = android.graphics.drawable.GradientDrawable()
              shape.cornerRadius = 16 * density
              shape.setColor(0xFFE8DEF8.toInt())
              pill.background = shape
            }
            itemLayout.addView(pill)
            
            val label = TextView(this)
            label.text = dest.optString("label")
            label.textSize = 12f
            label.gravity = Gravity.CENTER
            itemLayout.addView(label)
            
            // ✅ FIX: Add click listener
            val index = i
            itemLayout.setOnClickListener {
              if (navBarId.isNotEmpty()) sendAction(navBarId, index)
            }
            
            layout.addView(itemLayout)
          }
        }
        layout
      }
      type == "AppBar" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        layout.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        layout.setBackgroundColor(0xFF4F46E5.toInt())
        val density = resources.displayMetrics.density
        
        val titleView = TextView(this)
        titleView.text = if (node.has("title")) node.optString("title") else "Neon Task Studio"
        titleView.setTextColor(Color.WHITE)
        
        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
            val firstChild = children.getJSONObject(0)
            if (firstChild.optString("type").contains("Text")) {
                titleView.text = firstChild.optString("text")
            }
        }
        
        titleView.textSize = 20f
        titleView.gravity = Gravity.CENTER_VERTICAL
        titleView.setPadding((16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt())
        titleView.typeface = android.graphics.Typeface.DEFAULT_BOLD
        titleView.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f)
        layout.addView(titleView)

        val actions = node.optJSONArray("actions")
        if (actions != null && actions.length() > 0) {
          val actionNode = actions.getJSONObject(0)
          val label = actionNode.optString("label", "")
          val actionView = TextView(this)
          actionView.text = "$label tasks left"
          actionView.setTextColor(Color.WHITE)
          actionView.textSize = 14f
          actionView.setPadding(0, 0, (16 * density).toInt(), 0)
          actionView.gravity = Gravity.CENTER_VERTICAL
          layout.addView(actionView)
        }
        layout
      }
      type == "TabBar" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        val tabs = node.optJSONArray("tabs")
        val selectedIndex = node.optInt("selectedIndex", 0)
        
        if (tabs != null) {
          for (i in 0 until tabs.length()) {
            val tab = tabs.getJSONObject(i)
            val tabTitle = TextView(this)
            tabTitle.text = tab.optString("text")
            tabTitle.setPadding(32, 16, 32, 16)
            tabTitle.gravity = Gravity.CENTER
            if (i == selectedIndex) {
              tabTitle.setTextColor(Color.BLUE)
              tabTitle.paintFlags = tabTitle.paintFlags or android.graphics.Paint.UNDERLINE_TEXT_FLAG
            }
            
            val index = i
            val tabId = node.optString("id")
            tabTitle.setOnClickListener {
              if (tabId.isNotEmpty()) sendAction(tabId, index)
            }
            
            layout.addView(tabTitle)
          }
        }
        layout
      }
      type == "NavigationDrawer" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setBackgroundColor(0xFFF7F2FA.toInt())
        val density = resources.displayMetrics.density
        layout.setPadding((12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt())
        
        val children = node.optJSONArray("children")
        val drawerId = node.optString("id")
        if (children != null) {
          for (i in 0 until children.length()) {
            val dest = children.getJSONObject(i)
            val btn = TextView(this)
            btn.text = dest.optString("label")
            btn.setPadding(32, 16, 32, 16)
            val index = i
            btn.setOnClickListener {
              if (drawerId.isNotEmpty()) sendAction(drawerId, index)
            }
            layout.addView(btn)
          }
        }
        layout
      }
      type == "NavigationRail" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setBackgroundColor(0xFFF3EDF7.toInt())
        val density = resources.displayMetrics.density
        layout.setPadding((8 * density).toInt(), 0, (8 * density).toInt(), 0)
        
        val destinations = node.optJSONArray("destinations")
        val selectedIndex = node.optInt("selectedIndex", 0)
        
        if (destinations != null) {
          for (i in 0 until destinations.length()) {
            val dest = destinations.getJSONObject(i)
            val itemLayout = LinearLayout(this)
            itemLayout.orientation = LinearLayout.VERTICAL
            itemLayout.gravity = Gravity.CENTER
            itemLayout.setPadding(0, (20 * density).toInt(), 0, (20 * density).toInt())
            
            val pill = View(this)
            val pillParams = LinearLayout.LayoutParams((56 * density).toInt(), (32 * density).toInt())
            pill.layoutParams = pillParams
            if (i == selectedIndex) {
              val shape = android.graphics.drawable.GradientDrawable()
              shape.cornerRadius = 16 * density
              shape.setColor(0xFFE8DEF8.toInt())
              pill.background = shape
            }
            itemLayout.addView(pill)
            
            val label = TextView(this)
            label.text = dest.optString("label")
            label.textSize = 12f
            label.gravity = Gravity.CENTER
            itemLayout.addView(label)
            
            val index = i
            val railId = node.optString("id")
            itemLayout.setOnClickListener {
              if (railId.isNotEmpty()) sendAction(railId, index)
            }
            layout.addView(itemLayout)
          }
        }
        layout
      }
      // ✅ NEW: Switch Support
      type == "Switch" -> {
        val switch = android.widget.Switch(this)
        switch.isChecked = node.optBoolean("value", false)
        val switchId = node.optString("id")
        switch.setOnCheckedChangeListener { _, isChecked ->
          if (switchId.isNotEmpty()) sendAction(switchId, value = isChecked)
        }
        switch
      }
      // ✅ NEW: Checkbox Support
      type == "Checkbox" -> {
        val checkbox = android.widget.CheckBox(this)
        checkbox.isChecked = node.optBoolean("value", false)
        val checkboxId = node.optString("id")
        checkbox.setOnCheckedChangeListener { _, isChecked ->
          if (checkboxId.isNotEmpty()) sendAction(checkboxId, value = isChecked)
        }
        checkbox
      }
      // ✅ NEW: Radio Support
      type == "Radio" -> {
        val radio = android.widget.RadioButton(this)
        radio.isChecked = node.optBoolean("selected", false)
        val radioId = node.optString("id")
        radio.setOnClickListener {
          if (radioId.isNotEmpty()) sendAction(radioId)
        }
        radio
      }
      // ✅ NEW: Slider Support
      type == "Slider" -> {
        val slider = android.widget.SeekBar(this)
        val min = node.optDouble("min", 0.0)
        val max = node.optDouble("max", 1.0)
        val value = node.optDouble("value", 0.5)
        
        slider.max = 100 // Use 0-100 range
        slider.progress = ((value - min) / (max - min) * 100).toInt()
        
        val sliderId = node.optString("id")
        slider.setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
          override fun onProgressChanged(seekBar: android.widget.SeekBar?, progress: Int, fromUser: Boolean) {
            if (fromUser && sliderId.isNotEmpty()) {
              val normalizedValue = min + (progress / 100.0) * (max - min)
              sendAction(sliderId, value = normalizedValue)
            }
          }
          override fun onStartTrackingTouch(seekBar: android.widget.SeekBar?) {}
          override fun onStopTrackingTouch(seekBar: android.widget.SeekBar?) {}
        })
        slider
      }
      // ✅ NEW: Chip Support (ActionChip, FilterChip, etc.)
      type == "ActionChip" || type == "FilterChip" || type == "ChoiceChip" || type == "InputChip" -> {
        val chip = TextView(this)
        val density = resources.displayMetrics.density
        chip.setPadding((12 * density).toInt(), (6 * density).toInt(), (12 * density).toInt(), (6 * density).toInt())
        chip.textSize = 13f
        
        // Get label from node or children
        if (node.has("label")) {
          chip.text = node.optString("label")
        } else {
          val children = node.optJSONArray("children")
          if (children != null && children.length() > 0) {
            val firstChild = children.getJSONObject(0)
            if (firstChild.optString("type").contains("Text")) {
              chip.text = firstChild.optString("text")
            }
          }
        }
        
        // Style based on type
        val background = android.graphics.drawable.GradientDrawable()
        background.cornerRadius = 16 * density
        
        val isSelected = node.optBoolean("selected", false)
        if (type == "FilterChip") {
          if (isSelected) {
            background.setColor(0xFF4F46E5.toInt())
            chip.setTextColor(Color.WHITE)
          } else {
            background.setColor(0xFFE2E8F0.toInt())
            chip.setTextColor(0xFF1E293B.toInt())
          }
        } else {
          background.setColor(0xFFEEEEEE.toInt())
          chip.setTextColor(Color.BLACK)
        }
        
        chip.background = background
        
        val chipId = node.optString("id")
        chip.setOnClickListener {
          if (chipId.isNotEmpty()) {
            if (type == "FilterChip") {
              sendAction(chipId, value = !isSelected)
            } else {
              sendAction(chipId)
            }
          }
        }
        chip
      }
      type == "Card" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        val density = resources.displayMetrics.density
        val variant = node.optString("variant", "elevated")
        val borderRadius = node.optDouble("borderRadius", 14.0)

        layout.layoutParams = LinearLayout.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
          bottomMargin = (12 * density).toInt()
        }

        val background = android.graphics.drawable.GradientDrawable()
        background.cornerRadius = (borderRadius * density).toFloat()

        if (node.has("color")) {
          background.setColor(node.getInt("color"))
        } else {
          when (variant) {
            "elevated" -> {
              background.setColor(Color.WHITE)
              layout.elevation = 4 * density
            }
            "filled" -> {
              background.setColor(0xFFE8DEF8.toInt())
            }
            "outlined" -> {
              background.setColor(Color.WHITE)
              background.setStroke(2, Color.GRAY)
            }
            else -> background.setColor(Color.WHITE)
          }
        }
        layout.background = background
        layout.clipToOutline = true

        val pLeft = (node.optDouble("padding_left", 16.0) * density).toInt()
        val pTop = (node.optDouble("padding_top", 16.0) * density).toInt()
        val pRight = (node.optDouble("padding_right", 16.0) * density).toInt()
        val pBottom = (node.optDouble("padding_bottom", 16.0) * density).toInt()
        layout.setPadding(pLeft, pTop, pRight, pBottom)

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            layout.addView(renderWidget(children.getJSONObject(i)))
          }
        }
        layout
      }
      type == "Dialog" -> {
        val container = android.widget.FrameLayout(this)
        val visible = node.optBoolean("visible", false)
        val dialogId = node.optString("id")

        if (visible) {
          val builder = android.app.AlertDialog.Builder(this)
          val title = node.optString("title", "")
          val contentText = node.optString("contentText", "")
          if (title.isNotEmpty()) builder.setTitle(title)
          if (contentText.isNotEmpty()) builder.setMessage(contentText)

          val actions = node.optJSONArray("dialogActions")
          if (actions != null && actions.length() > 0) {
            if (actions.length() >= 1) {
              val action0 = actions.getJSONObject(0)
              builder.setPositiveButton(action0.optString("label", "OK")) { dialog, _ ->
                val key = action0.optString("key", "")
                if (dialogId.isNotEmpty()) sendAction(dialogId, value = key)
                dialog.dismiss()
              }
            }
            if (actions.length() >= 2) {
              val action1 = actions.getJSONObject(1)
              builder.setNegativeButton(action1.optString("label", "Cancel")) { dialog, _ ->
                val key = action1.optString("key", "")
                if (dialogId.isNotEmpty()) sendAction(dialogId, value = key)
                dialog.dismiss()
              }
            }
            if (actions.length() >= 3) {
              val action2 = actions.getJSONObject(2)
              builder.setNeutralButton(action2.optString("label", "")) { dialog, _ ->
                val key = action2.optString("key", "")
                if (dialogId.isNotEmpty()) sendAction(dialogId, value = key)
                dialog.dismiss()
              }
            }
          } else {
            builder.setPositiveButton("OK") { dialog, _ -> dialog.dismiss() }
          }

          builder.show()
        }

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            container.addView(renderWidget(children.getJSONObject(i)))
          }
        }
        container
      }
      type == "BottomSheet" -> {
        val container = android.widget.FrameLayout(this)
        val visible = node.optBoolean("visible", false)
        val showDragHandle = node.optBoolean("showDragHandle", true)
        val sheetId = node.optString("id")

        if (visible) {
          val dialog = android.app.Dialog(this)
          val sheetLayout = LinearLayout(this)
          sheetLayout.orientation = LinearLayout.VERTICAL
          val density = resources.displayMetrics.density
          sheetLayout.setPadding((16 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), (16 * density).toInt())
          sheetLayout.setBackgroundColor(0xFFFFFBFE.toInt())

          if (showDragHandle) {
            val handle = View(this)
            val handleParams = LinearLayout.LayoutParams((32 * density).toInt(), (4 * density).toInt())
            handleParams.gravity = Gravity.CENTER_HORIZONTAL
            handleParams.topMargin = (8 * density).toInt()
            handleParams.bottomMargin = (8 * density).toInt()
            handle.layoutParams = handleParams
            val handleBg = android.graphics.drawable.GradientDrawable()
            handleBg.cornerRadius = 2 * density
            handleBg.setColor(Color.GRAY)
            handle.background = handleBg
            sheetLayout.addView(handle)
          }

          val children = node.optJSONArray("children")
          if (children != null) {
            for (i in 0 until children.length()) {
              sheetLayout.addView(renderWidget(children.getJSONObject(i)))
            }
          }

          dialog.setContentView(sheetLayout)
          dialog.window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
          dialog.window?.setGravity(Gravity.BOTTOM)
          dialog.setOnDismissListener {
            if (sheetId.isNotEmpty()) sendAction(sheetId, value = "dismiss")
          }
          dialog.show()
        }
        container
      }
      type == "TextField" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.layoutParams = LinearLayout.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.WRAP_CONTENT
        )
        val density = resources.displayMetrics.density
        val variant = node.optString("variant", "filled")
        val fieldId = node.optString("id")

        val labelText = node.optString("labelText", "")
        if (labelText.isNotEmpty()) {
          val label = TextView(this)
          label.text = labelText
          label.textSize = 12f
          label.setTextColor(Color.DKGRAY)
          label.setPadding(0, 0, 0, (4 * density).toInt())
          layout.addView(label)
        }

        val editText = android.widget.EditText(this)
        editText.layoutParams = LinearLayout.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.WRAP_CONTENT
        )
        editText.setText(node.optString("value", ""))
        editText.hint = node.optString("hintText", "What needs to be done?")
        editText.setTextColor(0xFF1E293B.toInt())
        editText.setHintTextColor(0xFF94A3B8.toInt())
        val maxLines = node.optInt("maxLines", 1)
        editText.maxLines = maxLines
        editText.isSingleLine = maxLines == 1
        if (node.optBoolean("obscureText", false)) {
          editText.inputType = android.text.InputType.TYPE_CLASS_TEXT or android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD
        }

        val bg = android.graphics.drawable.GradientDrawable()
        bg.setColor(0xFFF8FAFC.toInt())
        bg.setStroke((1 * density).toInt(), 0xFFCBD5E1.toInt())
        bg.cornerRadius = 8 * density
        editText.background = bg
        editText.setPadding((12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt())

        editText.addTextChangedListener(object : android.text.TextWatcher {
          override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
          override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
            val textVal = s?.toString() ?: ""
            if (fieldId == "tf_new_task") {
              newTaskTitle = textVal
            }
          }
          override fun afterTextChanged(s: android.text.Editable?) {}
        })

        editText.setOnEditorActionListener { _, _, _ ->
          val currentText = editText.text.toString()
          if (fieldId == "tf_new_task") {
            newTaskTitle = currentText
            sendAction("btn_submit_task")
            true
          } else {
            if (fieldId.isNotEmpty()) sendAction(fieldId, value = currentText)
            false
          }
        }
        layout.addView(editText)

        val errorText = node.optString("errorText", "")
        val helperText = node.optString("helperText", "")
        if (errorText.isNotEmpty()) {
          val error = TextView(this)
          error.text = errorText
          error.textSize = 12f
          error.setTextColor(Color.RED)
          error.setPadding(0, (4 * density).toInt(), 0, 0)
          layout.addView(error)
        } else if (helperText.isNotEmpty()) {
          val helper = TextView(this)
          helper.text = helperText
          helper.textSize = 12f
          helper.setTextColor(Color.GRAY)
          helper.setPadding(0, (4 * density).toInt(), 0, 0)
          layout.addView(helper)
        }
        layout
      }
      type == "SearchBar" -> {
        val editText = android.widget.EditText(this)
        val density = resources.displayMetrics.density
        editText.hint = node.optString("hintText", "Search")
        editText.setText(node.optString("value", ""))
        editText.setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())

        val bg = android.graphics.drawable.GradientDrawable()
        bg.cornerRadius = 28 * density
        bg.setColor(0xFFE8E8E8.toInt())
        editText.background = bg

        val searchId = node.optString("id")
        editText.addTextChangedListener(object : android.text.TextWatcher {
          override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
          override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
          override fun afterTextChanged(s: android.text.Editable?) {
            if (searchId.isNotEmpty()) sendAction(searchId, value = s.toString())
          }
        })
        editText
      }
      type == "SearchAnchor" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        val density = resources.displayMetrics.density
        val searchId = node.optString("id")
        val expanded = node.optBoolean("expanded", false)

        val searchBar = android.widget.EditText(this)
        searchBar.hint = node.optString("hintText", "Search")
        searchBar.setText(node.optString("value", ""))
        searchBar.setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
        val bg = android.graphics.drawable.GradientDrawable()
        bg.cornerRadius = 28 * density
        bg.setColor(0xFFE8E8E8.toInt())
        searchBar.background = bg

        searchBar.addTextChangedListener(object : android.text.TextWatcher {
          override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
          override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
          override fun afterTextChanged(s: android.text.Editable?) {
            if (searchId.isNotEmpty()) sendAction(searchId, value = s.toString())
          }
        })
        layout.addView(searchBar)

        if (expanded) {
          val suggestions = node.optJSONArray("suggestions")
          if (suggestions != null) {
            for (i in 0 until suggestions.length()) {
              val suggestion = suggestions.getJSONObject(i)
              val item = TextView(this)
              item.text = suggestion.optString("text", "")
              item.setPadding((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (12 * density).toInt())
              item.textSize = 16f
              val idx = i
              item.setOnClickListener {
                if (searchId.isNotEmpty()) sendAction(searchId, idx, suggestion.optString("text", ""))
              }
              layout.addView(item)
            }
          }
        }
        layout
      }
      type == "MenuAnchor" -> {
        val container = android.widget.FrameLayout(this)
        val menuId = node.optString("id")
        val expanded = node.optBoolean("expanded", false)

        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
          val childView = renderWidget(children.getJSONObject(0))
          container.addView(childView)
        }

        if (expanded) {
          val menuItems = node.optJSONArray("menuItems")
          if (menuItems != null) {
            container.post {
              val popup = android.widget.PopupMenu(this, container)
              for (i in 0 until menuItems.length()) {
                val menuItem = menuItems.getJSONObject(i)
                val label = menuItem.optString("label", "Item $i")
                val enabled = menuItem.optBoolean("enabled", true)
                val item = popup.menu.add(0, i, i, label)
                item.isEnabled = enabled
              }
              popup.setOnMenuItemClickListener { item ->
                if (menuId.isNotEmpty()) sendAction(menuId, item.itemId)
                true
              }
              popup.show()
            }
          }
        }
        container
      }
      type == "MenuBar" -> {
        val scrollView = android.widget.HorizontalScrollView(this)
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        layout.gravity = Gravity.CENTER_VERTICAL
        val density = resources.displayMetrics.density
        val menuId = node.optString("id")
        val selectedIndex = node.optInt("selectedIndex", -1)

        val menuItems = node.optJSONArray("menuItems")
        if (menuItems != null) {
          for (i in 0 until menuItems.length()) {
            val menuItem = menuItems.getJSONObject(i)
            val btn = TextView(this)
            btn.text = menuItem.optString("label", "Item $i")
            btn.setPadding((16 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), (8 * density).toInt())
            btn.textSize = 14f
            val enabled = menuItem.optBoolean("enabled", true)
            btn.isEnabled = enabled

            if (i == selectedIndex) {
              btn.setBackgroundColor(0xFFEADDFF.toInt())
              btn.setTextColor(Color.BLACK)
            } else {
              btn.setTextColor(if (enabled) Color.BLACK else Color.GRAY)
            }

            val idx = i
            btn.setOnClickListener {
              if (menuId.isNotEmpty()) sendAction(menuId, idx)
            }
            layout.addView(btn)
          }
        }
        scrollView.addView(layout)
        scrollView
      }
      // ✅ NEW: Badge Support
      type == "Badge" -> {
        val badge = TextView(this)
        badge.text = node.optString("label", "")
        badge.setBackgroundColor(Color.RED)
        badge.setTextColor(Color.WHITE)
        badge.textSize = 12f
        badge.gravity = Gravity.CENTER
        val density = resources.displayMetrics.density
        badge.setPadding((8 * density).toInt(), (4 * density).toInt(), (8 * density).toInt(), (4 * density).toInt())
        
        val background = android.graphics.drawable.GradientDrawable()
        background.cornerRadius = 10 * density
        background.setColor(Color.RED)
        badge.background = background
        
        badge.layoutParams = ViewGroup.LayoutParams((20 * density).toInt(), (20 * density).toInt())
        badge
      }
      type == "ListTile" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.HORIZONTAL
        layout.gravity = Gravity.CENTER_VERTICAL
        val density = resources.displayMetrics.density
        val dense = node.optBoolean("dense", false)
        val selected = node.optBoolean("selected", false)
        val enabled = node.optBoolean("enabled", true)
        val tileId = node.optString("id")

        val verticalPad = if (dense) (4 * density).toInt() else (8 * density).toInt()
        layout.setPadding((16 * density).toInt(), verticalPad, (16 * density).toInt(), verticalPad)

        if (selected) {
          layout.setBackgroundColor(0xFFE8DEF8.toInt())
        }

        val leading = node.optJSONObject("leading")
        if (leading != null) {
          val leadingView = TextView(this)
          leadingView.text = leading.optString("text", "")
          leadingView.textSize = 14f
          leadingView.setPadding(0, 0, (16 * density).toInt(), 0)
          leadingView.setTextColor(if (enabled) Color.DKGRAY else Color.LTGRAY)
          layout.addView(leadingView)
        }

        val textColumn = LinearLayout(this)
        textColumn.orientation = LinearLayout.VERTICAL
        textColumn.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f)

        val title = node.optString("title", "")
        if (title.isNotEmpty()) {
          val titleView = TextView(this)
          titleView.text = title
          titleView.textSize = if (dense) 14f else 16f
          titleView.setTextColor(if (enabled) Color.BLACK else Color.GRAY)
          textColumn.addView(titleView)
        }

        val subtitle = node.optString("subtitle", "")
        if (subtitle.isNotEmpty()) {
          val subtitleView = TextView(this)
          subtitleView.text = subtitle
          subtitleView.textSize = if (dense) 12f else 14f
          subtitleView.setTextColor(Color.GRAY)
          textColumn.addView(subtitleView)
        }
        layout.addView(textColumn)

        val trailing = node.optJSONObject("trailing")
        if (trailing != null) {
          val trailingView = TextView(this)
          trailingView.text = trailing.optString("text", "")
          trailingView.textSize = 14f
          trailingView.setPadding((16 * density).toInt(), 0, 0, 0)
          trailingView.setTextColor(if (enabled) Color.DKGRAY else Color.LTGRAY)
          layout.addView(trailingView)
        }

        if (enabled && tileId.isNotEmpty()) {
          layout.setOnClickListener { sendAction(tileId) }
        }
        layout.isEnabled = enabled
        layout
      }
      type == "LinearProgressIndicator" -> {
        val container = LinearLayout(this)
        container.orientation = LinearLayout.VERTICAL
        val density = resources.displayMetrics.density
        val indeterminate = node.optBoolean("indeterminate", false)
        val minHeight = node.optDouble("minHeight", 4.0)
        val borderRadius = node.optDouble("borderRadius", 0.0)

        val progressBar = android.widget.ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal)
        progressBar.isIndeterminate = indeterminate
        if (!indeterminate && node.has("value")) {
          val value = node.optDouble("value", 0.0)
          progressBar.max = 1000
          progressBar.progress = (value * 1000).toInt()
        }

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, (minHeight * density).toInt())
        progressBar.layoutParams = params

        if (node.has("color")) {
          progressBar.progressTintList = android.content.res.ColorStateList.valueOf(node.getInt("color"))
        }
        if (node.has("backgroundColor")) {
          progressBar.progressBackgroundTintList = android.content.res.ColorStateList.valueOf(node.getInt("backgroundColor"))
        }

        container.addView(progressBar)
        container
      }
      type == "CircularProgressIndicator" -> {
        val density = resources.displayMetrics.density
        val indeterminate = node.optBoolean("indeterminate", false)
        val size = node.optDouble("size", 48.0)

        val progressBar = if (indeterminate) {
          android.widget.ProgressBar(this)
        } else {
          android.widget.ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            isIndeterminate = false
            max = 1000
            if (node.has("value")) {
              progress = (node.optDouble("value", 0.0) * 1000).toInt()
            }
          }
        }

        val sizePixels = (size * density).toInt()
        progressBar.layoutParams = ViewGroup.LayoutParams(sizePixels, sizePixels)

        if (node.has("color")) {
          progressBar.indeterminateTintList = android.content.res.ColorStateList.valueOf(node.getInt("color"))
          progressBar.progressTintList = android.content.res.ColorStateList.valueOf(node.getInt("color"))
        }

        progressBar
      }
      type == "Tooltip" -> {
        val container = android.widget.FrameLayout(this)
        val message = node.optString("message", "")

        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
          val childView = renderWidget(children.getJSONObject(0))
          if (message.isNotEmpty()) {
            childView.setOnLongClickListener {
              android.widget.Toast.makeText(this, message, android.widget.Toast.LENGTH_SHORT).show()
              true
            }
            childView.tooltipText = message
          }
          container.addView(childView)
        }
        container
      }
      type == "SnackBar" -> {
        val container = android.widget.FrameLayout(this)
        val visible = node.optBoolean("visible", false)
        val snackId = node.optString("id")

        if (visible) {
          val density = resources.displayMetrics.density
          val behavior = node.optString("behavior", "fixed")
          val contentText = node.optString("contentText", "")
          val actionLabel = node.optString("actionLabel", "")
          val showCloseIcon = node.optBoolean("showCloseIcon", false)

          val snackLayout = LinearLayout(this)
          snackLayout.orientation = LinearLayout.HORIZONTAL
          snackLayout.gravity = Gravity.CENTER_VERTICAL
          snackLayout.setBackgroundColor(0xFF323232.toInt())
          snackLayout.setPadding((16 * density).toInt(), (14 * density).toInt(), (16 * density).toInt(), (14 * density).toInt())

          if (behavior == "floating") {
            val bg = android.graphics.drawable.GradientDrawable()
            bg.cornerRadius = 8 * density
            bg.setColor(0xFF323232.toInt())
            snackLayout.background = bg
            val marginParams = ViewGroup.MarginLayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            marginParams.setMargins((8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt())
            snackLayout.layoutParams = marginParams
          }

          val contentView = TextView(this)
          contentView.text = contentText
          contentView.setTextColor(Color.WHITE)
          contentView.textSize = 14f
          contentView.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f)
          snackLayout.addView(contentView)

          if (actionLabel.isNotEmpty()) {
            val actionButton = TextView(this)
            actionButton.text = actionLabel
            actionButton.setTextColor(0xFFBB86FC.toInt())
            actionButton.textSize = 14f
            actionButton.setPadding((8 * density).toInt(), 0, (8 * density).toInt(), 0)
            actionButton.setOnClickListener {
              if (snackId.isNotEmpty()) sendAction(snackId, value = "action")
            }
            snackLayout.addView(actionButton)
          }

          if (showCloseIcon) {
            val closeButton = TextView(this)
            closeButton.text = "✕"
            closeButton.setTextColor(Color.WHITE)
            closeButton.textSize = 14f
            closeButton.setPadding((8 * density).toInt(), 0, 0, 0)
            closeButton.setOnClickListener {
              if (snackId.isNotEmpty()) sendAction(snackId, value = "dismiss")
            }
            snackLayout.addView(closeButton)
          }

          val snackParams = android.widget.FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
          snackParams.gravity = Gravity.BOTTOM
          snackLayout.layoutParams = snackParams
          container.addView(snackLayout)
        }
        container
      }
      type == "SingleChildScrollView" -> {
        val scrollDirection = node.optString("scrollDirection", "vertical")
        val reverse = node.optBoolean("reverse", false)

        val scrollView: ViewGroup = if (scrollDirection == "horizontal") {
          android.widget.HorizontalScrollView(this).apply {
            isFillViewport = true
            layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
          }
        } else {
          ScrollView(this).apply {
            isFillViewport = true
            layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
          }
        }

        val children = node.optJSONArray("children")
        if (children != null && children.length() > 0) {
          val childView = renderWidget(children.getJSONObject(0))
          childView.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
          scrollView.addView(childView)
        }

        if (reverse) {
          scrollView.rotation = 180f
        }
        scrollView
      }
      type == "ListView" -> {
        val scrollDirection = node.optString("scrollDirection", "vertical")
        val reverse = node.optBoolean("reverse", false)
        val shrinkWrap = node.optBoolean("shrinkWrap", false)

        val layout = LinearLayout(this)
        layout.orientation = if (scrollDirection == "horizontal") LinearLayout.HORIZONTAL else LinearLayout.VERTICAL

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            layout.addView(renderWidget(children.getJSONObject(i)))
          }
        }

        if (reverse) {
          layout.rotation = 180f
        }

        if (shrinkWrap) {
          layout.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
          layout
        } else {
          val scrollView: ViewGroup = if (scrollDirection == "horizontal") {
            android.widget.HorizontalScrollView(this)
          } else {
            ScrollView(this)
          }
          scrollView.addView(layout)
          scrollView
        }
      }
      type == "CustomScrollView" -> {
        val scrollDirection = node.optString("scrollDirection", "vertical")
        val reverse = node.optBoolean("reverse", false)

        val layout = LinearLayout(this)
        layout.orientation = if (scrollDirection == "horizontal") LinearLayout.HORIZONTAL else LinearLayout.VERTICAL

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            layout.addView(renderWidget(children.getJSONObject(i)))
          }
        }

        val scrollView: ViewGroup = if (scrollDirection == "horizontal") {
          android.widget.HorizontalScrollView(this)
        } else {
          ScrollView(this)
        }

        if (reverse) {
          scrollView.rotation = 180f
        }

        scrollView.addView(layout)
        scrollView
      }
      type == "SliverList" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            layout.addView(renderWidget(children.getJSONObject(i)))
          }
        }
        layout
      }
      type == "SliverAppBar" -> {
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        val density = resources.displayMetrics.density
        val title = node.optString("title", "")
        val expandedHeight = node.optDouble("expandedHeight", 200.0)
        val pinned = node.optBoolean("pinned", false)

        val bg = android.graphics.drawable.GradientDrawable()
        bg.setColor(0xFF6750A4.toInt())
        layout.background = bg

        val heightPixels = (expandedHeight * density).toInt()
        layout.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, heightPixels)
        layout.gravity = Gravity.BOTTOM

        val titleView = TextView(this)
        titleView.text = title
        titleView.textSize = 24f
        titleView.setTextColor(Color.WHITE)
        titleView.typeface = android.graphics.Typeface.DEFAULT_BOLD
        titleView.setPadding((16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt())
        val titleParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        titleParams.gravity = Gravity.BOTTOM
        titleView.layoutParams = titleParams

        layout.addView(titleView)

        val children = node.optJSONArray("children")
        if (children != null) {
          for (i in 0 until children.length()) {
            layout.addView(renderWidget(children.getJSONObject(i)))
          }
        }
        layout
      }
      else -> {
        val fallback = TextView(this)
        fallback.text = "[Unknown Widget: $type]"
        fallback.setTextColor(Color.RED)
        fallback
      }
    }
  }
}
