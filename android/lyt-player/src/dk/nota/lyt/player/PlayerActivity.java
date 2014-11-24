package dk.nota.lyt.player;

import java.io.FileInputStream;
import java.io.IOException;
import java.math.BigDecimal;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.ConnectivityManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MenuItem.OnMenuItemClickListener;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import dk.nota.lyt.Book;
import dk.nota.lyt.BookInfo;
import dk.nota.lyt.SoundBite;
import dk.nota.lyt.SoundFragment;
import dk.nota.lyt.player.PlayerInterface.Callback;
import dk.nota.lyt.player.task.AbstractTask;
import dk.nota.lyt.player.task.GetBookTask;
import dk.nota.lyt.player.task.StreamBiteTask;
import dk.nota.player.R;
import dk.nota.utils.MediaPlayer;
import dk.nota.utils.WorkerThread;

@SuppressLint("SetJavaScriptEnabled")
public class PlayerActivity extends Activity implements Callback, OnCompletionListener, DownloadThread.Callback {
	
	private static BigDecimal THOUSAND = new BigDecimal(1000);
	private MediaPlayer mCurrentPlayer;
	private MediaPlayer mNextPlayer;
	private BroadcastReceiver mNetworkStateReceiver;
	private NextPlayerThread mNextPlayerThread;
	private StreamingThread mStreamingThread;
	private DownloadThread mDownloaderThread;
	private ProgressThread mProgressThread;
	private Book mBook;
	private BigDecimal mCurrentEnd;
	private WebView mWebView;

	boolean mOnline;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_player);
		
		mWebView = (WebView) findViewById(R.id.webview);
		WebSettings webSettings = mWebView.getSettings();
		webSettings.setJavaScriptEnabled(true);
		webSettings.setAllowFileAccess(true);
		webSettings.setBuiltInZoomControls(false);
		webSettings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.SINGLE_COLUMN);
		webSettings.setDomStorageEnabled(true);
		mWebView.addJavascriptInterface(new PlayerInterface(this), "playerJS");
		mWebView.setWebChromeClient(new WebChromeClient());
		mWebView.loadUrl("http://192.168.0.18:8000/player.html");
		if(PlayerApplication.getInstance().isProduction() == false && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
		    WebView.setWebContentsDebuggingEnabled(true);
		}		
		mNextPlayerThread = new NextPlayerThread();
		mNextPlayerThread.start();
		mStreamingThread = new StreamingThread();
		mStreamingThread.start();
		mDownloaderThread = new DownloadThread(this);
		mDownloaderThread.start();
		mProgressThread = new ProgressThread();
		mProgressThread.start();
		
		listenToConnectivity();	
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
	protected void onDestroy() {
		super.onDestroy();
		unlistenToConnectivity();
		mNextPlayerThread.shutdown();
		mStreamingThread.shutdown();
		mDownloaderThread.shutdown();
	}
	
	@Override
	public void setBook(String bookJSON) {
		PlayerApplication.getInstance().getBookService().setBook(bookJSON);
	}
	
	@Override
	public void clearBook(String bookId) {
		PlayerApplication.getInstance().getBookService().clearBook(bookId);
	}
	
	@Override
	public void clearBookCache(String bookId) {
		PlayerApplication.getInstance().getBookService().clearBookCache(bookId);
	}
	
	@Override
	public BookInfo[] getBooks() {
		return PlayerApplication.getInstance().getBookService().getBookInfo();
	}
	
	@Override
	public void play(final String bookId, final String positionText) {
		Log.i(PlayerApplication.TAG, String.format("Starting play of book: %s,  Position: %s", bookId, positionText));
		final BigDecimal position = new BigDecimal(positionText);
		new GetBookTask().execute(new AbstractTask.SimpleTaskListener<Book>() {

			@Override
			public void success(final Book book) {
				mStreamingThread.task.eject();
				mBook = book;
				book.setPosition(position);
				mCurrentEnd = book.getCurrentFragment().getStart();
				if (isPlaying()) {
					stop();
				}
				synchronized (mNextPlayerThread) {
					mNextPlayerThread.notify();
				}
				synchronized (mStreamingThread) {
					mStreamingThread.notify();
				}
			}
		}, bookId);
	}
	
	
	
	@Override
	public void cacheBook(String bookId) {
		Book book = PlayerApplication.getInstance().getBookService().getBook(bookId);
		if (book != null) {
			mDownloaderThread.addBook(book);
		}
	}
	
	@Override
	public boolean isPlaying() {
		return mCurrentPlayer != null && mCurrentPlayer.isPlaying();
	}
	
	@Override
	public void stop() {
		if(mCurrentPlayer != null) {
			mCurrentPlayer.stop();
			mCurrentPlayer.release();
			mCurrentPlayer = null;
			mNextPlayer = null;
		}
	}

	@Override
	public void onCompletion(android.media.MediaPlayer mp) {
		if (mp != mCurrentPlayer) {
			throw new IllegalStateException("How did that happen?!");
		}
		mBook.setPosition(mCurrentPlayer.getEnd());
		Log.i(PlayerApplication.TAG, "New book position: " + mBook.getPosition());
		mCurrentPlayer = mNextPlayer;
		mNextPlayer = null;
		if (mCurrentPlayer != null) {
			mCurrentPlayer.setOnCompletionListener(this);
		}
		synchronized (mNextPlayerThread) {
			mNextPlayerThread.notify();
		}
	}

	private void listenToConnectivity() {
		mNetworkStateReceiver = new BroadcastReceiver() {

		    @Override
		    public void onReceive(Context context, Intent intent) {
		    	mOnline = intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY, false) == false;
		    	Log.i(PlayerApplication.TAG, mOnline ? "Device is online" : "Device is offline");
		    	if (mOnline) {
		    		synchronized (mStreamingThread) {
		    			mStreamingThread.notify();
		    		}
		    	}
		    }
		};
		IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);        
		registerReceiver(mNetworkStateReceiver, filter);
	}
	
	private void unlistenToConnectivity() {
		PlayerApplication.getInstance().unregisterReceiver(mNetworkStateReceiver);
	}

	private void startPlayer(SoundBite bite, BigDecimal end) {
		int seekTo = mBook.getCurrentFragment().getOffset(mBook.getPosition()).multiply(THOUSAND).intValue();
		try {
			mCurrentPlayer = new MediaPlayer(end.subtract(bite.getDuration()), end);
			setDataSource(mCurrentPlayer, bite);
			mCurrentPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
			mCurrentPlayer.prepare();
			mCurrentPlayer.seekTo(seekTo);
			mCurrentPlayer.setOnCompletionListener(PlayerActivity.this);
			mCurrentPlayer.start();
			synchronized (mProgressThread) {
				mProgressThread.notify();
			}
		} catch (Exception e) {
		}
		
	}
		
	private long getExpectedCompletion() {
		BigDecimal remainingPlaytime = mCurrentEnd.multiply(THOUSAND).subtract(mBook.getPosition().multiply(THOUSAND));
		Log.w(PlayerApplication.TAG, "Current end: " + mCurrentEnd + " Position: " + mBook.getPosition());
		Log.i(PlayerApplication.TAG, "Expected completion " +  remainingPlaytime.divide(THOUSAND)  + " seconds");
		return remainingPlaytime.longValue() + System.currentTimeMillis();
	}
	
	private void setDataSource(MediaPlayer player, SoundBite bite) {
		FileInputStream stream = null;
		try {
			stream = openFileInput(bite.getFilename());
			player.setDataSource(stream.getFD());
		} catch (IOException e) {
			Log.e(PlayerApplication.TAG, "Unable to open bite filename: " + bite.getFilename(), e);
		} finally {
			if (stream != null) {
				try {
					stream.close();
				} catch (IOException e) {
					Log.e(PlayerApplication.TAG, "Unable to close bite: " + bite.getFilename(), e);
				}
			}
		}
	}
	
	private class ProgressThread extends WorkerThread {
		public ProgressThread() {
			super("Progress");
		}
		
		@Override
		public void run() {
			while (running()) {
				if (isPlaying() == false) {
					waitUp("No book is playing. Going to sleep");
				} else {
					BigDecimal currentPosition = mCurrentPlayer.getCurrentPosition() > 0 ? new BigDecimal(mCurrentPlayer.getCurrentPosition()).divide(THOUSAND) : BigDecimal.ZERO;
					mBook.setPosition(mCurrentPlayer.getStart().add(currentPosition));
					fireEvent(Event.TIME_UPDATE, mBook.getId(), mBook.getPosition().toString());
				}
				waitUp(100);
			}
		}
	}
	
	private class StreamingThread extends WorkerThread {

		private long FIVE_MINUTES = 1000 * 60 * 5;
		private StreamBiteTask task = new StreamBiteTask();
		private boolean mBusy = false;
		
		public StreamingThread() {
			super("Streamer");
		}

		@Override
		public void run() {
			while(running()) {
				if (mBook == null) {
					waitUp("Sleeping since no book has been set");
				}
				if (mBook != null && mOnline) {
					SoundBite bite = null;
					do {
						if (mOnline == false) {
							waitUp("Not online. Going to sleep");
						}
						mDownloaderThread.giveWay();
						mBusy = true;
						BigDecimal currentPosition = isPlaying() ? new BigDecimal(mCurrentPlayer.getCurrentPosition()).divide(THOUSAND) : BigDecimal.ZERO ;
						bite = task.doCaching(mBook, currentPosition, getExpectedCompletion());
						synchronized (mNextPlayerThread) {
							mNextPlayerThread.notify();
						}
					} while(bite != null);
					mBusy = false;
					synchronized (mDownloaderThread) {
						mDownloaderThread.notify();
					}
					waitUp(FIVE_MINUTES, "Streaming has noting to do. Going to sleep");
				}
			}
		}
		
		boolean isStreaming() {
			return mBusy;
		}
	}
	
	private class NextPlayerThread extends WorkerThread {
		
		public NextPlayerThread() {
			super("NextPlayer");
		}
		
		@Override
		public void run() {
			while (running()) {
				if (mNextPlayer != null) {
					waitUp("Falling a sleep as next bite already prepared");
				}
				if (mBook == null) {
					waitUp("No book to play. Going to sleep");
				} else {
					SoundFragment fragment = mBook.getFragment(mCurrentEnd);
					SoundBite bite = fragment.getBite(mCurrentEnd);
					if (bite == null) {
						waitUp("Falling a sleep as no bite is available");
					} else if (mNextPlayer == null){
						Log.i(PlayerApplication.TAG, "Next player will be from fragment url: " + fragment.getUrl());
						try {
							Log.i(PlayerApplication.TAG, String.format("In fragment: %s-%s of %s In book: %s-%s",
									bite.getStart(), bite.getEnd(), fragment.getEnd(),
									fragment.getPosition(bite.getStart()), fragment.getPosition(bite.getEnd())));
							mCurrentEnd = mCurrentEnd.add(bite.getDuration());
							if (bite.getEnd().compareTo(fragment.getEnd()) == 0) {
								Log.i(PlayerApplication.TAG, "Last bite. Adjusting current end with: " + fragment.getBookEndPosition().subtract(fragment.getBookStartPosition().add(fragment.getEnd())));
								mCurrentEnd = fragment.getBookEndPosition();
							}
							if (isPlaying()) {
								mNextPlayer = new MediaPlayer(mCurrentEnd.subtract(bite.getDuration()), mCurrentEnd);
								setDataSource(mNextPlayer, bite);
								mNextPlayer.prepare();
								mCurrentPlayer.setNextMediaPlayer(mNextPlayer);
							} else {
								startPlayer(bite, mCurrentEnd);
							}
						} catch (Exception e) {
							Log.e(PlayerApplication.TAG, "Unable to queue the next player", e);
						}
					}				
				}
			}
		}
	}

	@Override
	public void downloadFailed(Book book, String reason) {
		fireEvent(Event.DOWNLOAD_FAILED, book.getId(), reason);
	}
	
	@Override
	public void downloadCompleted(Book book) {
		fireEvent(Event.DOWNLOAD_COMPLETED, book.getId());
	}
	
	@Override
	public void downloadProgress(Book book, BigDecimal percentage) {
		fireEvent(Event.DOWNLOAD_PROGRESS, percentage.toString());
	}
	
	@Override
	public boolean isBusy() {
		return mStreamingThread.isStreaming();
	}
	
	public void fireEvent(Event event, String ... params) {
		StringBuilder parameters = new StringBuilder();
		for (String param : params) {
			parameters.append(",").append(param);
		}
		mWebView.evaluateJavascript(String.format("lytHandleEvent(%s %s)", event.eventName(), parameters.toString()), null);
	}
}
