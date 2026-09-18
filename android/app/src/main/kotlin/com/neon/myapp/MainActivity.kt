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
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : Activity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // Show a "Loading" screen initially
    val loadingText = TextView(this)
    loadingText.text = "Connecting to Neon Engine..."
    loadingText.gravity = Gravity.CENTER
    loadingText.textSize = 20f
    setContentView(loadingText)

    // Start fetching UI from Dart
    fetchUiTree()
  }

  companion object {
    private const val BASE_URL = "https://custom-frameworks-neon-framework.iix8qf.easypanel.host"
  }

  private fun fetchUiTree() {
    thread {
      try {
        val cleanBaseUrl = BASE_URL.trimEnd('/')
        val url = URL("$cleanBaseUrl/api/tree")
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 10000
        connection.readTimeout = 15000
        connection.requestMethod = "GET"

        val reader = BufferedReader(InputStreamReader(connection.inputStream))
        val response = reader.readText()
        reader.close()

        // Parse JSON
        val rootNode = JSONObject(response)

        // Render on Main Thread
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
          val errorView = TextView(this)
          errorView.text = "Error connecting to Neon host:\n${e.message}\n\nHost: $BASE_URL"
          errorView.setTextColor(Color.RED)
          setContentView(errorView)
        }
      }
    }
  }

  private fun sendAction(id: String, index: Int? = null, value: Any? = null) {
    thread {
      try {
        val cleanBaseUrl = BASE_URL.trimEnd('/')
        val url = URL("$cleanBaseUrl/action")
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 10000
        connection.readTimeout = 15000
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
          // Read the response JSON (contains updated widget tree)
          val reader = BufferedReader(InputStreamReader(connection.inputStream))
          val response = reader.readText()
          reader.close()
          
          // Parse and re-render the updated tree
          val rootNode = JSONObject(response)
          runOnUiThread {
            val rootView = renderWidget(rootNode)
            rootView.layoutParams = ViewGroup.LayoutParams(
              ViewGroup.LayoutParams.MATCH_PARENT,
              ViewGroup.LayoutParams.MATCH_PARENT
            )
            setContentView(rootView)
          }
        }
      } catch (e: Exception) {
        e.printStackTrace()
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
      type.contains("Text") -> {
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

        editText.setOnEditorActionListener { _, _, _ ->
          if (fieldId.isNotEmpty()) sendAction(fieldId, value = editText.text.toString())
          false
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
