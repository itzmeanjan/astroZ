package com.example.itzmeanjan.nasa_apod

import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.ConnectivityManager
import android.net.Uri
import android.os.AsyncTask
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.room.Room
import com.google.android.gms.ads.*
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import kotlin.Exception

class MainActivity : FlutterActivity() {

    private var methodChannel: MethodChannel? = null // methodChannel is required, to communicate with flutter
    private var eventChannel: EventChannel? = null
    private var permissionCallBack: PermissionCallBack? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        MobileAds.initialize(this, "ca-app-pub-3940256099942544~3347511713") // test Application ID for Ad
        val linearLayout = LinearLayout(this) // linearLayout created to hold adView
        linearLayout.gravity = Gravity.BOTTOM
        linearLayout.orientation = LinearLayout.VERTICAL
        linearLayout.setPadding(0, 0, 0, 0)
        val adView = AdView(this) // adView created
        adView.adUnitId = "ca-app-pub-3940256099942544/6300978111" // test Ad unit ID
        adView.adSize = AdSize.BANNER
        adView.setPadding(0, 0, 0, 0)
        var adRequest: AdRequest? // declaration of AdRequest
        methodChannel = MethodChannel(flutterView, "nasa_apod_method") // *** methodChannel needs to be created by same name on both flutter level and platform level
        methodChannel?.setMethodCallHandler { methodCall, result ->
            // platform level method call handler
            // listens to invocation and responds back
            when (methodCall.method) {
                "getFromLocal" -> { // tries to fetch a record from local sql database, by `date`
                    val db = Room.databaseBuilder(applicationContext, APODDatabase::class.java, "nasa_apod.db").build() // builds database, if not already and connects to it
                    val apodGetDataByDateCallBack = object : APODGetDataByDateCallBack { // callback to handle completion of database query
                        override fun sendData(apodData: APODData?) { // invocation of this method leads to sending of queried data back to flutter level code
                            db.close() // first closing database is highly required, other wise it might lead to leaking of data kind of issues
                            result.success( // this method sends data back as query result
                                    if (apodData != null)
                                        mapOf( // if found something in database
                                                "date" to apodData.date,
                                                "copyright" to apodData.copyright,
                                                "explanation" to apodData.explanation,
                                                "hdurl" to apodData.hdUrl,
                                                "media_type" to apodData.mediaType,
                                                "title" to apodData.title,
                                                "url" to apodData.url
                                        )
                                    else // well if nothing is found, return a blank map
                                        mapOf()
                            )
                        }
                    }
                    val apodGetDataByDateTask = APODGetDataByDateTask(db.getAPODDao(), apodGetDataByDateCallBack)
                    apodGetDataByDateTask.execute(methodCall.argument<String>("date"))
                }
                "storeInDB" -> {
                    val db = Room.databaseBuilder(applicationContext, APODDatabase::class.java, "nasa_apod.db").build()
                    val apodStoreDataCallBack = object : APODStoreDataCallBack {
                        override fun success() {
                            db.close()
                            result.success(1)
                        }

                        override fun failure() {
                            db.close()
                            result.success(0)
                        }
                    }
                    val apodStoreDataTask = APODStoreDataTask(db.getAPODDao(), apodStoreDataCallBack)
                    apodStoreDataTask.execute(*methodCall.argument<List<Map<String, String>>>("data")!!.map {
                        APODData(it.getValue("date"), it["copyright"] ?: "NA", it["explanation"]
                                ?: "NA", it["hdurl"]
                                ?: "NA", it.getValue("media_type"), it.getValue("title"), it.getValue("url"))
                    }.toTypedArray())
                }
                "loadBannerAd" -> {
                    eventChannel = EventChannel(flutterView, "nasa_apod_event")
                    result.success(1)
                    eventChannel?.setStreamHandler(
                            object : EventChannel.StreamHandler {
                                override fun onCancel(p0: Any?) {
                                }

                                override fun onListen(p0: Any?, eventSink: EventChannel.EventSink?) {
                                    adView.adListener = object : AdListener() {
                                        override fun onAdFailedToLoad(errorCode: Int) {
                                            super.onAdFailedToLoad(errorCode)
                                            eventSink?.success("failed")
                                        }

                                        override fun onAdLeftApplication() {
                                            super.onAdLeftApplication()
                                            eventSink?.success("leftApp")
                                        }

                                        override fun onAdLoaded() {
                                            super.onAdLoaded()
                                            eventSink?.success("loaded")
                                        }

                                        override fun onAdOpened() {
                                            super.onAdOpened()
                                            eventSink?.success("opened")
                                        }

                                        override fun onAdClosed() {
                                            super.onAdClosed()
                                            eventSink?.success("closed")
                                            eventSink?.endOfStream()
                                        }
                                    }
                                }
                            }
                    )
                    adRequest = AdRequest.Builder().build()
                    linearLayout.addView(adView, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
                    addContentView(linearLayout, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
                    adView.loadAd(adRequest)
                }
                "closeBannerAd" -> {
                    adRequest = null
                    linearLayout.removeView(adView)
                    (linearLayout.parent as ViewGroup).removeView(linearLayout)
                    eventChannel = null
                    result.success(1)
                }
                "isConnected" -> {
                    val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val activeNetworkInfo = connectivityManager.activeNetworkInfo
                    result.success(
                            activeNetworkInfo?.isConnected ?: false
                    )
                }
                "isPermissionAvailable" -> {
                    result.success(ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED)
                }
                "requestPermission" -> {
                    permissionCallBack = object : PermissionCallBack {
                        override fun denied() {
                            result.success(false)
                        }

                        override fun granted() {
                            result.success(true)
                        }
                    }
                    ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE), 999)
                }
                "getTargetPath" -> {
                    result.success(File(Environment.getExternalStorageDirectory().absolutePath).absolutePath)
                }
                "shareImage" -> {
                    val intent = Intent(Intent.ACTION_SEND)
                    intent.type = methodCall.argument<String>("type")
                    intent.putExtra(Intent.EXTRA_STREAM, Uri.parse(methodCall.argument<String>("imagePath")))
                    startActivity(Intent.createChooser(intent, "Share Image"))
                    result.success(true)
                }
                "shareText" -> {
                    val intent = Intent(Intent.ACTION_SEND)
                    intent.type = methodCall.argument<String>("type")
                    intent.putExtra(Intent.EXTRA_TEXT, methodCall.argument<String>("text"))
                    startActivity(Intent.createChooser(intent, "Share"))
                    result.success(true)
                }
                "setWallPaper" -> {
                    result.success(
                            try {
                                val wallpaperManager = getSystemService(Context.WALLPAPER_SERVICE) as WallpaperManager
                                if (Build.VERSION.SDK_INT >= 24)
                                    wallpaperManager.setBitmap(BitmapFactory.decodeFile(methodCall.argument<String>("imagePath")), null, true, WallpaperManager.FLAG_SYSTEM)
                                else
                                    wallpaperManager.setBitmap(BitmapFactory.decodeFile(methodCall.argument<String>("imagePath")))
                                true
                            } catch (e: Exception) {
                                false
                            }
                    )
                }
                "openInTargetApp" -> {
                    result.success(
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(methodCall.argument<String>("url"))))
                                true
                            } catch (e: Exception) {
                                false
                            }
                    )
                }
                "showToast" -> {
                    Toast.makeText(applicationContext, methodCall.argument<String>("msg"), if (methodCall.argument<String>("duration") == "short") Toast.LENGTH_SHORT
                    else
                        Toast.LENGTH_LONG).show()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class APODStoreDataTask(private val apodDao: APODDao, private val apodStoreDataCallBack: APODStoreDataCallBack) : AsyncTask<APODData, Void, Int>() {
    override fun doInBackground(vararg params: APODData): Int {
        return try {
            apodDao.insertAll(*params)
            1
        } catch (e: Exception) {
            0
        }
    }

    override fun onPostExecute(result: Int?) {
        super.onPostExecute(result)
        if (result == 1)
            apodStoreDataCallBack.success()
        else
            apodStoreDataCallBack.failure()
    }
}

interface APODStoreDataCallBack {
    fun success()
    fun failure()
}


class APODGetDataByDateTask(private val apodDao: APODDao, private val apodGetDataByDateCallBack: APODGetDataByDateCallBack) : AsyncTask<String, Void, APODData>() {
    override fun doInBackground(vararg params: String?): APODData? {
        return try {
            apodDao.getByDate(params[0]!!)
        } catch (e: Exception) {
            null
        }
    }

    override fun onPostExecute(result: APODData?) {
        super.onPostExecute(result)
        apodGetDataByDateCallBack.sendData(result)
    }
}

interface APODGetDataByDateCallBack {
    fun sendData(apodData: APODData?)
}

interface PermissionCallBack {
    fun granted()
    fun denied()
}