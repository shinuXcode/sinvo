package com.sinvo.shop;
import android.app.Activity;import android.os.Bundle;import android.webkit.WebSettings;import android.webkit.WebView;import android.webkit.WebViewClient;
public class MainActivity extends Activity{
 public void onCreate(Bundle b){super.onCreate(b);WebView w=new WebView(this);w.setWebViewClient(new WebViewClient());WebSettings s=w.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setAllowFileAccess(true);s.setAllowContentAccess(true);w.loadUrl("file:///android_asset/web/index.html");setContentView(w);}
}