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
import dk.nota.lyt.player.task.StreamBiteTask.OnProgress;
import dk.nota.utils.WorkerThread;

class DownloadThread extends WorkerThread implements OnProgress {

	interface Callback {
		void downloadStarted(Book book);
		void downloadCompleted(Book book);
		void downloadFailed(Book book, String reason);
		void downloadProgress(Book book, BigDecimal precentage);
		boolean isBusy();
	}

	private static final String TAG = DownloadThread.class.getSimpleName();
			
	private static final BigDecimal ONE_HUNDRED = new BigDecimal(100);		
	
	private Callback mCallback;
	private Book mCurrentBook;
	private boolean mOnline;
	private StreamBiteTask mStreamer = new StreamBiteTask(this);
	private BroadcastReceiver mNetworkStateReceiver;
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
				Log.i(TAG, "Starting download of:" + mCurrentBook.getTitle());
				mCallback.downloadStarted(mCurrentBook);
				StreamBiteTask.StreamBite bite = null;
				try {
					do {
						if (mOnline == false) {
							waitUp("Not online. Going to sleep");
						} else if (mCallback.isBusy()) {
							waitUp("Something is going on. Going to sleep");
						} else {
							bite = mStreamer.doDownload(mCurrentBook);
						}
					} while((mOnline == false || bite != null) && mCurrentBook != null);
					if (mCurrentBook != null) {
						Log.i(TAG, "Done downloading " + mCurrentBook.getTitle());
						mCallback.downloadCompleted(mCurrentBook);
					}
				} catch (Exception e) {
					Log.e(TAG, "Unable to download book", e);
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
	
	public void cancelDownload() {
		mStreamer.eject();
		mCurrentBook = null;
	}

	private void listenToConnectivity() {
		mNetworkStateReceiver = new BroadcastReceiver() {

		    @Override
		    public void onReceive(Context context, Intent intent) {
		    	mOnline = intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY, false) == false;
		    	Log.i(TAG, mOnline ? "Device is online" : "Device is offline");
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

	@Override
	public void onProgress(BigDecimal position) {
		if (mCurrentBook != null) {
			mCallback.downloadProgress(mCurrentBook, position.divide(mCurrentBook.getEnd(), 6, BigDecimal.ROUND_HALF_EVEN).multiply(ONE_HUNDRED));		
		}
	}
}