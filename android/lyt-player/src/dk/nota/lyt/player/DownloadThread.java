package dk.nota.lyt.player;

import java.math.BigDecimal;
import java.util.Stack;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.player.task.StreamBiteTask;
import dk.nota.player.R;
import dk.nota.utils.WorkerThread;

class DownloadThread extends WorkerThread {

	interface Callback {
		void downloadCompleted(Book book);
		void downloadFailed(Book book, String reason);
		void downloadProgress(Book book, BigDecimal precentage);
		boolean isBusy();
	}
	
	private static final int NOTIFICATION_ID = 42;  
	private static final BigDecimal ONE_HUNDRED = new BigDecimal(100);		
	
	private Callback mCallback;
	private Book mCurrentBook;
	private boolean mOnline;
	private StreamBiteTask mStreamer = new StreamBiteTask();
	private Notification.Builder mBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_ic_action_download);
	private NotificationManager mNotifyMgr = (NotificationManager) PlayerApplication.getInstance().getSystemService(PlayerActivity.NOTIFICATION_SERVICE);
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
				Log.i(PlayerApplication.TAG, "Starting download of:" + mCurrentBook.getTitle());
				notifyDownloadStart();
				StreamBiteTask.StreamBite bite = null;
				try {
					do {
						if (mOnline == false) {
							waitUp("Not online. Going to sleep");
						} else if (mCallback.isBusy()) {
							waitUp("Something is going on. Going to sleep");
						} else {
							bite = mStreamer.doDownload(mCurrentBook);
							notifyDownloadProgress(bite);
						}
					} while(mOnline == false || bite != null);
					Log.i(PlayerApplication.TAG, "Done downloading " + mCurrentBook.getTitle());
					notifyDownloadCompletion();
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
	
	private void notifyDownloadStart() {
		mBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.download_title, mCurrentBook.getTitle(), mCurrentBook.getAuthor()))
			    .setContentText(PlayerApplication.getInstance().getString(R.string.download_in_progress))
			    .setContentIntent(getPendingIntent())
			    .setOngoing(true)
				.setProgress(mCurrentBook.getEnd().intValue(), 0, false);
		mNotifyMgr.notify(NOTIFICATION_ID, mBuilder.build());
	}
	
	private void notifyDownloadProgress(StreamBiteTask.StreamBite bite) {
		if (bite != null) {
			mCallback.downloadProgress(mCurrentBook, bite.getPosition().divide(mCurrentBook.getEnd()).multiply(ONE_HUNDRED));
			mBuilder.setProgress(mCurrentBook.getEnd().intValue(), bite.getPosition().intValue(), false);
			mNotifyMgr.notify(NOTIFICATION_ID, mBuilder.build());
		}
	}

	private void notifyDownloadCompletion() {
		mBuilder.setOngoing(false)
			.setAutoCancel(true)
			.setContentText(PlayerApplication.getInstance().getString(R.string.download_completed))
			.setProgress(0, 0, false);
		mNotifyMgr.notify(NOTIFICATION_ID, mBuilder.build());
	}
	
	private PendingIntent getPendingIntent() {
		Intent resultIntent = new Intent(PlayerApplication.getInstance(), PlayerActivity.class);
		// Because clicking the notification opens the only activity
		// no need to create an artificial back stack.
		return PendingIntent.getActivity(
		    PlayerApplication.getInstance(),
		    0,
		    resultIntent,
		    PendingIntent.FLAG_UPDATE_CURRENT
		);
	}

}