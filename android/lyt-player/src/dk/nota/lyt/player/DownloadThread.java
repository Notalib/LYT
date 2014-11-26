package dk.nota.lyt.player;

import java.math.BigDecimal;
import java.util.Stack;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.player.task.StreamBiteTask;
import dk.nota.utils.WorkerThread;

class DownloadThread extends WorkerThread {

	interface Callback {
		void downloadCompleted(Book book);
		void downloadFailed(Book book, String reason);
		void downloadProgress(Book book, BigDecimal precentage);
		boolean isBusy();
	}

	private static final BigDecimal ONE_HUNDRED = new BigDecimal(100);		
	
	private Callback mCallback;
	private Book mCurrentBook;
	private boolean mOnline;
	private StreamBiteTask mStreamer = new StreamBiteTask();
	private BroadcastReceiver mNetworkStateReceiver;
	private NotificationManager mNotificationManager = new NotificationManager();
	private Stack<Book> mDownloadStack = new Stack<>();
	
	DownloadThread(Callback callback) {
		super("Downloader");
		listenToConnectivity();
		this.mCallback = callback;
	}

	public void addBook(Book book) {
		mDownloadStack.push(book);
		synchronized (this) {
			notify();
		}
	}

	@Override
	public void run() {
		while(running() || mCurrentBook != null) {
			if (mCurrentBook == null) {
				mCurrentBook = mDownloadStack.isEmpty() ? null : mDownloadStack.pop();
				if (mCurrentBook == null) waitUp("No book to download. Going to sleep");
			} else {
				Log.i(PlayerApplication.TAG, "Starting download of:" + mCurrentBook.getTitle());
				mNotificationManager.notifyDownloadStart(mCurrentBook);
				StreamBiteTask.StreamBite bite = null;
				try {
					do {
						if (mOnline == false) {
							waitUp("Not online. Going to sleep");
						} else if (mCallback.isBusy()) {
							waitUp("Something is going on. Going to sleep");
						} else {
							bite = mStreamer.doDownload(mCurrentBook);
							mCallback.downloadProgress(mCurrentBook, bite.getPosition().divide(mCurrentBook.getEnd()).multiply(ONE_HUNDRED));
							mNotificationManager.notifyDownloadProgress(mCurrentBook, bite);
						}
					} while(mOnline == false || bite != null);
					Log.i(PlayerApplication.TAG, "Done downloading " + mCurrentBook.getTitle());
					mNotificationManager.notifyDownloadCompletion();
					unlistenToConnectivity();
					mCallback.downloadCompleted(mCurrentBook);
				} catch (Exception e) {
					mCallback.downloadFailed(mCurrentBook, e.getMessage());
				}
				mCurrentBook = null;
			}
		}
	}

	/**
	 * Use this to make the download thread yield for e.g. streaming
	 */
	public void giveWay() {
		mStreamer.eject();
	}

	private void listenToConnectivity() {
		mNetworkStateReceiver = new BroadcastReceiver() {

		    @Override
		    public void onReceive(Context context, Intent intent) {
		    	mOnline = intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY, false) == false;
		    	Log.i(PlayerApplication.TAG, mOnline ? "Device is online" : "Device is offline");
		    	if (mOnline) {
		    		synchronized (this) {
		    			notify();
		    		}
		    	}
		    }
		};
		IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);        
		PlayerApplication.getInstance().registerReceiver(mNetworkStateReceiver, filter);
	}
	
	private void unlistenToConnectivity() {
		PlayerApplication.getInstance().unregisterReceiver(mNetworkStateReceiver);
	}
}