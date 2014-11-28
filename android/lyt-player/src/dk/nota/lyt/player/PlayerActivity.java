package dk.nota.lyt.player;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MenuItem.OnMenuItemClickListener;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import dk.nota.lyt.player.event.OnPlayerEvent;
import dk.nota.lyt.player.event.WebPlayerEvent;
import dk.nota.player.R;

@SuppressLint("SetJavaScriptEnabled")
public class PlayerActivity extends Activity {
	
	private WebView mWebView;
	private OnPlayerEvent mEventListener;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_player);
		
		if(PlayerApplication.getInstance().isProduction() == false && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
			WebView.setWebContentsDebuggingEnabled(true);
		}		
		mWebView = (WebView) findViewById(R.id.webview);
		WebSettings webSettings = mWebView.getSettings();
		webSettings.setJavaScriptEnabled(true);
		webSettings.setAllowFileAccess(true);
		webSettings.setBuiltInZoomControls(false);
		webSettings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.SINGLE_COLUMN);
		webSettings.setDomStorageEnabled(true);
		mWebView.addJavascriptInterface(new PlayerInterface(PlayerApplication.getInstance().getPlayer()), "lytBridge");
		mWebView.setWebChromeClient(new WebChromeClient());
		mEventListener = new WebPlayerEvent(mWebView);
		mWebView.loadUrl("http://localhost:9000");
//		mWebView.loadUrl("http://test.m.e17.dk/msn/lyt-3.0_007/#/bookshelf");
//		mWebView.loadUrl("http://localhost:8000/player.html");
	}
	
	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		if (intent.getBooleanExtra("shutdown", false)) {
			PlayerApplication.getInstance().getPlayer().shutdown();
			finish();
		}
	}
	
	@Override
	protected void onResume() {
		super.onResume();
		PlayerApplication.getInstance().getPlayer().addEventListener(mEventListener);
	}
	
	@Override
	protected void onPause() {
		super.onPause();
		PlayerApplication.getInstance().getPlayer().removeEventListener(mEventListener);
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
//		PlayerApplication.getInstance().getPlayer().
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		getMenuInflater().inflate(R.menu.menu, menu);
		menu.findItem(R.id.reload).setOnMenuItemClickListener(new OnMenuItemClickListener() {
			
			@Override
			public boolean onMenuItemClick(MenuItem item) {
				mWebView.reload();
				return false;
			}
		});
		return super.onCreateOptionsMenu(menu);
	}
	
	@Override
	public void onBackPressed() {
		if (mWebView.getUrl().endsWith("/bookshelf") == false) {
			mWebView.evaluateJavascript("window.history.back()", null);
		} else {
			super.onBackPressed();
		}
	}
}
