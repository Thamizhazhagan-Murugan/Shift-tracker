package com.shifttracker.shift_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget that shows the current punch status and a button to
 * clock in / out. The button triggers a Dart background callback (no app UI),
 * and the displayed text comes from data saved by the Flutter app.
 */
class ShiftWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.shift_widget).apply {
                val clockedIn = widgetData.getBoolean("clocked_in", false)

                setTextViewText(
                    R.id.widget_status,
                    widgetData.getString("status", "Clocked out"),
                )
                setTextViewText(
                    R.id.widget_today,
                    widgetData.getString("today", "Today: 0.00 h"),
                )
                setTextViewText(
                    R.id.widget_button,
                    widgetData.getString("action_label", "Punch In"),
                )
                setInt(
                    R.id.widget_button,
                    "setBackgroundResource",
                    if (clockedIn) R.drawable.widget_btn_red else R.drawable.widget_btn_green,
                )

                // Tap the button: toggle punch via the Dart background callback.
                val toggleIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("shiftwidget://toggle"),
                )
                setOnClickPendingIntent(R.id.widget_button, toggleIntent)

                // Tap anywhere else: open the app.
                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
