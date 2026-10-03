package com.sinvo.shop;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.print.PrintManager;
import android.print.PrintAttributes;
import android.os.Bundle;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.ValueCallback;
import android.net.Uri;
import android.webkit.JavascriptInterface;
import android.provider.OpenableColumns;
import android.util.Base64;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Locale;

public class MainActivity extends Activity {
  private WebView webView;
  private ValueCallback<Uri[]> fileCallback;
  private String nativeImportMode = "add";
  @Override public void onCreate(Bundle b) {
    super.onCreate(b);
    WebView w = new WebView(this);
    webView = w;
    WebSettings s = w.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setDatabaseEnabled(true);
    s.setAllowFileAccess(false);
    s.setAllowContentAccess(true);

    w.addJavascriptInterface(new PrintBridge(), "SinvoAndroid");

    w.setWebChromeClient(new WebChromeClient() {
      @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
        if (fileCallback != null) fileCallback.onReceiveValue(null);
        fileCallback = callback;
        try {
          Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
          intent.addCategory(Intent.CATEGORY_OPENABLE);
          intent.setType("*/*");
          intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"text/csv","text/plain","application/json","application/octet-stream"});
          intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
          startActivityForResult(intent, 42);
          return true;
        } catch (Exception e) {
          fileCallback = null;
          return false;
        }
      }
    });

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

  @Override protected void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (requestCode == 42 && fileCallback != null) {
      Uri[] result = WebChromeClient.FileChooserParams.parseResult(resultCode, data);
      fileCallback.onReceiveValue(result);
      fileCallback = null;
      return;
    }
    if (requestCode == 43) {
      if (resultCode != RESULT_OK || data == null || data.getData() == null) {
        sendNativeImportResult(null, null);
        return;
      }
      Uri uri = data.getData();
      try {
        getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
      } catch (Exception ignored) {}
      try {
        String name = getDisplayName(uri);
        byte[] bytes = readUri(uri);
        String base64 = Base64.encodeToString(bytes, Base64.NO_WRAP);
        sendNativeImportResult(name, base64);
      } catch (Exception e) {
        sendNativeImportResult(null, null);
      }
    }
  }

  private String getDisplayName(Uri uri) {
    String name = null;
    try (android.database.Cursor cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
      if (cursor != null && cursor.moveToFirst()) name = cursor.getString(0);
    }
    return name == null || name.trim().isEmpty() ? "price-list.csv" : name;
  }

  private byte[] readUri(Uri uri) throws Exception {
    try (InputStream in = getContentResolver().openInputStream(uri); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
      if (in == null) throw new Exception("Unable to open selected file");
      byte[] buffer = new byte[8192];
      int n;
      while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
      return out.toByteArray();
    }
  }

  private void sendNativeImportResult(String name, String base64) {
    final String mode = nativeImportMode;
    final String safeName = name == null ? "null" : org.json.JSONObject.quote(name);
    final String safeBase64 = base64 == null ? "null" : org.json.JSONObject.quote(base64);
    runOnUiThread(() -> {
      if (webView == null) return;
      webView.evaluateJavascript("window.SinvoAndroidFileSelected && window.SinvoAndroidFileSelected(" + org.json.JSONObject.quote(mode) + "," + safeName + "," + safeBase64 + ")", null);
    });
  }

  public class PrintBridge {
    @JavascriptInterface public void pickPriceListFile(String mode) {
      nativeImportMode = "replace".equals(mode) ? "replace" : "add";
      try {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"text/csv","text/plain","application/json","application/octet-stream"});
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        startActivityForResult(intent, 43);
      } catch (Exception e) {
        sendNativeImportResult(null, null);
      }
    }

    @JavascriptInterface public void printBill(String html) {
      runOnUiThread(() -> {
        WebView printWeb = new WebView(MainActivity.this);
        printWeb.getSettings().setJavaScriptEnabled(false);
        printWeb.setWebViewClient(new WebViewClient() {
          @Override public void onPageFinished(WebView view, String url) {
            PrintManager pm = (PrintManager) getSystemService(Context.PRINT_SERVICE);
            pm.print("Sinvo Bill", view.createPrintDocumentAdapter("Sinvo Bill"), new PrintAttributes.Builder().build());
          }
        });
        printWeb.loadDataWithBaseURL("https://sinvo.local/", html, "text/html", "UTF-8", null);
      });
    }
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
