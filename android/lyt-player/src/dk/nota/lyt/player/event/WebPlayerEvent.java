package dk.nota.lyt.player.event;

import java.math.BigDecimal;

import android.app.Activity;
import android.util.Log;
import android.webkit.WebView;
import dk.nota.lyt.Book;
import dk.nota.lyt.player.PlayerApplication;

public class WebPlayerEvent implements OnPlayerEvent{
	
	enum Event {
		PLAY_TIME_UPDATE("play-time-update"),
		PLAY_CHAPTER_CHANGE("play-chapter-change"),
		PLAY_PLAY("play-play"),
		PLAY_STOP("play-stop"),
		PLAY_END("play-end"),
		PLAY_FAILED("play-failed"),
		DOWNLOAD_STARTED("download-started"),
		DOWNLOAD_PROGRESS("download-progress"),
		DOWNLOAD_CANCELLED("download-cancelled"),
		DOWNLOAD_FAILED("download-failed"),
		DOWNLOAD_COMPLETED("download-completed"),
		CONNECTIVITY_CHANGED("connectivity-change");

		private String eventName;

		String eventName() {
			return eventName;
		}
		
		Event(String name) {
			this.eventName = "'"+name+"'";
		}
	}
	
	private WebView mWebView;
	private Activity mActivity;

	public WebPlayerEvent(WebView webView) {
		this.mWebView = webView;
		mActivity = (Activity) webView.getContext();
	}

	@Override
	public void onTimeUpdate(Book book, BigDecimal position) {
		fireEvent(Event.PLAY_TIME_UPDATE, book, position);
	}

	@Override
	public void onChapterChange(Book book) {
		fireEvent(Event.PLAY_CHAPTER_CHANGE, book);
		
	}

	@Override
	public void onPlay(Book book) {
	}

	@Override
	public void onStop(Book book, boolean fullStop) {
		fireEvent(Event.PLAY_STOP, book);
		
	}

	@Override
	public void onEnd(Book book) {
		fireEvent(Event.PLAY_END, book);
	}

	@Override
	public void onPlayFailed(Book book, String reason) {
		fireEvent(Event.PLAY_FAILED, book, reason);
	}

	@Override
	public void onDownloadStarted(Book book) {
		fireEvent(Event.DOWNLOAD_STARTED, book);
		
	}

	@Override
	public void onDownloadProgress(Book book, BigDecimal percentage) {
		fireEvent(Event.DOWNLOAD_PROGRESS, book, percentage);
		
	}

	@Override
	public void onDownloadCancelled(Book book) {
		fireEvent(Event.DOWNLOAD_CANCELLED, book);
	}

	@Override
	public void onDownloadFailed(Book book, String reason) {
		fireEvent(Event.DOWNLOAD_FAILED, book, reason);
	}

	@Override
	public void onDownloadCompleted(Book book) {
		fireEvent(Event.DOWNLOAD_COMPLETED, book);
	}

	@Override
	public void onConnectivityChanged(boolean online) {
		fireEvent(Event.CONNECTIVITY_CHANGED, null, online);
		
	}
	
	public void fireEvent(final Event event, final Book book, final Object... params) {
		
		mActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				StringBuilder parameters = new StringBuilder();
				if (book != null) {
					parameters.append(",").append("'").append(book.getId()).append("'");
				}
				for (Object param : params) {
					parameters.append(",");
					if (param instanceof String) {
						parameters.append("'").append(param).append("'");
					} else {
						parameters.append(param);
					}
				}
				mWebView.evaluateJavascript(String.format("lytHandleEvent(%s %s)", event.eventName(), parameters.toString()), null);
			}
		});
	}

}
