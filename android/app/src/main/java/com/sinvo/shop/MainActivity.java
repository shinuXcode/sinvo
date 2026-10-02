package com.sinvo.shop;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.InputStream;
import java.util.Locale;

public class MainActivity extends Activity {
  @Override public void onCreate(Bundle b) {
    super.onCreate(b);
    WebView w = new WebView(this);
    WebSettings s = w.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setDatabaseEnabled(true);
    s.setAllowFileAccess(false);
    s.setAllowContentAccess(false);

    w.setWebViewClient(new WebViewClient() {
      @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
        String url = request.getUrl().toString();
        String prefix = "https://sinvo.local/";
        if (!url.startsWith(prefix)) return super.shouldInterceptRequest(view, request);
        String path = url.substring(prefix.length());
        if (path.isEmpty()) path = "web/index.html";
        if (!path.startsWith("web/")) path = "web/" + path;
        try {
          InputStream in = getAssets().open(path);
          String mime = mime(path);
          return new WebResourceResponse(mime, "UTF-8", in);
        } catch (Exception e) {
          return new WebResourceResponse("text/plain", "UTF-8", null);
        }
      }
    });

    w.loadUrl("https://sinvo.local/web/index.html");
    setContentView(w);
  }

  private String mime(String path) {
    String p = path.toLowerCase(Locale.US);
    if (p.endsWith(".js") || p.endsWith(".mjs")) return "application/javascript";
    if (p.endsWith(".css")) return "text/css";
    if (p.endsWith(".json")) return "application/json";
    if (p.endsWith(".svg")) return "image/svg+xml";
    if (p.endsWith(".png")) return "image/png";
    if (p.endsWith(".jpg") || p.endsWith(".jpeg")) return "image/jpeg";
    if (p.endsWith(".woff2")) return "font/woff2";
    if (p.endsWith(".woff")) return "font/woff";
    return "text/html";
  }
}
