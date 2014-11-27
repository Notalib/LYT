package dk.nota.lyt.player;

import java.io.FileInputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.media.AudioManager.OnAudioFocusChangeListener;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.ConnectivityManager;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.BookInfo;
import dk.nota.lyt.Section;
import dk.nota.lyt.SoundBite;
import dk.nota.lyt.SoundFragment;
import dk.nota.lyt.player.task.AbstractTask;
import dk.nota.lyt.player.task.GetBookTask;
import dk.nota.lyt.player.task.StreamBiteTask;
import dk.nota.utils.MediaPlayer;
import dk.nota.utils.WorkerThread;

public class BookPlayer implements DownloadThread.Callback, OnCompletionListener, OnAudioFocusChangeListener {

	public interface EventListener {
		void onEvent(Event event, Book book, Object... params);
	}

	private static Object LOCK = new Object();
	private static BigDecimal THOUSAND = new BigDecimal(1000);

	private NextPlayerThread mNextPlayerThread;
	private StreamingThread mStreamingThread;
	private DownloadThread mDownloaderThread;
	private ProgressThread mProgressThread;
	
	private MediaPlayer mCurrentPlayer;
	private MediaPlayer mNextPlayer;

	private BroadcastReceiver mNetworkStateReceiver;

	private boolean playing = false;
	private Book mBook;
	private BigDecimal mCurrentEnd;
	private List<EventListener> mEventListeners = new ArrayList<>();

	private AudioManager mAudioManager;

	private boolean mOnline;
	private boolean mResumeOnGain;

	BookPlayer() {
		mNextPlayerThread = new NextPlayerThread();
		mNextPlayerThread.start();
		mStreamingThread = new StreamingThread();
		mStreamingThread.start();
		mDownloaderThread = new DownloadThread(this);
		mDownloaderThread.start();
		mProgressThread = new ProgressThread();
		mProgressThread.start();

		listenToConnectivity();
		mAudioManager = (AudioManager) PlayerApplication.getInstance().getSystemService(Context.AUDIO_SERVICE);
	}

	void onDestroy() {
		unlistenToConnectivity();
		mNextPlayerThread.shutdown();
		mStreamingThread.shutdown();
		mDownloaderThread.shutdown();
		stop();
	}

	void addEventListener(EventListener listener) {
		this.mEventListeners.add(listener);
	}
	
	void removeEventListener(EventListener listener) {
		mEventListeners.remove(listener);
	}

	public void setBook(String bookJSON) {
		PlayerApplication.getInstance().getBookService().setBook(bookJSON);
	}

	public void clearBook(String bookId) {
		PlayerApplication.getInstance().getBookService().clearBook(bookId);
	}

	public void clearBookCache(String bookId) {
		PlayerApplication.getInstance().getBookService().clearBookCache(bookId);
	}

	public BookInfo[] getBooks() {
		return PlayerApplication.getInstance().getBookService().getBookInfo();
	}
	
	public void play() {
		if (mBook == null) {
			Log.w(PlayerApplication.TAG, "No book has been previously set.");
			return;
		}
		play(mBook.getId(), mBook.getPosition());
	}

	public void play(final String bookId, final String positionText) {
		final BigDecimal position = new BigDecimal(positionText);
		play(bookId, position);
	}

	public boolean isPlaying() {
		try {
			return playing && mCurrentPlayer != null && mCurrentPlayer.isPlaying();
		} catch (Exception ignore) {
		}
		return false;
	}

	public void cacheBook(String bookId) {
		Book book = PlayerApplication.getInstance().getBookService().getBook(bookId);
		if (book != null) {
			mDownloaderThread.addBook(book);
		}
	}

	public void stop() {
		stop(true);
	}
	
	public void shutdown() {
		stop(true);
		fireEvent(Event.PLAY_STOP, mBook.getId(), Boolean.TRUE);
	}
	
	public void stop(boolean fullStop) {
		synchronized (LOCK) {
			playing = false;
			if (mCurrentPlayer != null) {
				mCurrentPlayer.stop();
				updateBookPosition();
				mCurrentPlayer.release();
				mCurrentPlayer = null;
			}
			if (mNextPlayer != null) {
				mNextPlayer.release();
				mNextPlayer = null;
			}
			if (mBook != null) {
				fireEvent(Event.PLAY_STOP, mBook.getId());
				PlayerApplication.getInstance().getBookService().updateBook(mBook);
			}
			if (fullStop) {
				mAudioManager.abandonAudioFocus(this);
			}
		}
	}

	public void next() {
		Section nextSection = mBook.nextSection(mBook.getPosition());
		String bookId = mBook.getId();
		stop(false);
		play(bookId, nextSection.getOffset().toString());
	}

	public void previous() {
		Section previousSection = mBook.previousSection(mBook.getPosition());
		String bookId = mBook.getId();
		stop(false);
		play(bookId, previousSection.getOffset().toString());
	}
	
	public void onCompletion(android.media.MediaPlayer mp) {
		if (mp != mCurrentPlayer) {
			throw new IllegalStateException("How did that happen?!");
		}
		synchronized (LOCK) {
			mBook.setPosition(mCurrentPlayer.getEnd());
			Log.i(PlayerApplication.TAG, "New book position: " + mBook.getPosition());
			MediaPlayer releaseIt = mCurrentPlayer;
			mCurrentPlayer = mNextPlayer;
			mNextPlayer = null;
			if (mCurrentPlayer != null) {
				mCurrentPlayer.setOnCompletionListener(this);
				synchronized (mProgressThread) {
					mProgressThread.notify();
				}
				fireEvent(Event.PLAY_CHAPTER_CHANGE, mBook.getId());
			}
			synchronized (mNextPlayerThread) {
				mNextPlayerThread.notify();
			}
			releaseIt.reset();
			releaseIt.release();
		}
	}

	@Override
	public void onAudioFocusChange(int focusChange) {
		if (focusChange == AudioManager.AUDIOFOCUS_GAIN && mResumeOnGain) {
			Log.w(PlayerApplication.TAG, "Focus gained");
			play();
			mResumeOnGain = false;
		} else if (isPlaying()){
			mResumeOnGain = true;
			Log.w(PlayerApplication.TAG, "Focus lost");
			stop(false);
		}
	}
	
	public void downloadCancelled(Book book) {
		fireEvent(Event.DOWNLOAD_CANCELLED, book, book.getId());
		mDownloaderThread.cancelDownload();
	}

	@Override
	public void downloadStarted(Book book) {
		fireEvent(Event.DOWNLOAD_STARTED, book, book.getId());
	}

	@Override
	public void downloadFailed(Book book, String reason) {
		fireEvent(Event.DOWNLOAD_FAILED, book, book.getId(), reason);
	}

	@Override
	public void downloadCompleted(Book book) {
		fireEvent(Event.DOWNLOAD_COMPLETED, book, book.getId());
	}

	@Override
	public void downloadProgress(Book book, BigDecimal percentage) {
		fireEvent(Event.DOWNLOAD_PROGRESS, book, book.getId(), percentage);
	}

	@Override
	public boolean isBusy() {
		return mStreamingThread.isStreaming();
	}

	private void play(final String bookId, final BigDecimal position) {
		Log.i(PlayerApplication.TAG, String.format("Starting play of book: %s,  Position: %s", bookId, position));
		new GetBookTask().execute(new AbstractTask.SimpleTaskListener<Book>() {

			@Override
			public void success(final Book book) {
				if (book != null) {
					playing = true;
					mStreamingThread.task.eject();
					mBook = book;
					book.setPosition(position);
					mCurrentEnd = book.getCurrentFragment().getBookStartPosition();
					if (isPlaying()) {
						stop();
					}
					synchronized (mNextPlayerThread) {
						mNextPlayerThread.notify();
					}
					synchronized (mStreamingThread) {
						mStreamingThread.notify();
					}
				} else {
					fireEvent(Event.PLAY_FAILED, "No book was found for id: " + bookId);
				}
			}
		}, bookId);
	}

	private void startPlayer(SoundBite bite, BigDecimal end) {
		int seekTo = mBook.getCurrentFragment().getOffset(mBook.getPosition()).subtract(bite.getStart()).multiply(THOUSAND).intValue();
		Log.i(PlayerApplication.TAG, "Creating new start, and adjusting player position to: " + seekTo);
		try {
			synchronized (LOCK) {
				int audioFocusResult = mAudioManager.requestAudioFocus(this, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);
				if (audioFocusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
					Log.w(PlayerApplication.TAG, "Unable gain audio focus. Abandon playing og book");
					return;
				}
				mCurrentPlayer = new MediaPlayer(end.subtract(bite.getDuration()), end);
				setDataSource(mCurrentPlayer, bite);
				mCurrentPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
				mCurrentPlayer.prepare();
				mCurrentPlayer.seekTo(seekTo);
				mCurrentPlayer.setOnCompletionListener(BookPlayer.this);
				mCurrentPlayer.start();
				if (seekTo > bite.getDuration().multiply(THOUSAND).longValue()) {
					Log.w(PlayerApplication.TAG, "Seeking past end! Seekto: " + seekTo + " Duration: " + bite.getDuration());
					onCompletion(mCurrentPlayer);
				}
				fireEvent(Event.PLAY_PLAY, mBook.getId());
				synchronized (mProgressThread) {
					mProgressThread.notify();
				}
			}
		} catch (Exception e) {
			Log.e(PlayerApplication.TAG, "Error occured while starting player", e);
		}

	}

	private void updateBookPosition() {
		BigDecimal currentPosition = mCurrentPlayer.getCurrentPosition() > 0 ? new BigDecimal(mCurrentPlayer.getCurrentPosition()).divide(THOUSAND) : BigDecimal.ZERO;
		mBook.setPosition(mCurrentPlayer.getStart().add(currentPosition));
	}

	private long getExpectedCompletion() {
		long expectedCompletion = 0;
		SoundFragment fragment = mBook.getCurrentFragment();
		while(fragment != null && fragment.isDownloaded()) {
			fragment = mBook.getFragment(fragment.getBookEndPosition());
		}
		if (fragment == null) {
			expectedCompletion = mBook.getEnd().subtract(mBook.getPosition()).multiply(THOUSAND).longValue();
		} else {
			BigDecimal bookPosition = fragment.getPosition(fragment.getHoles().get(0).getStart());
			expectedCompletion = bookPosition.subtract(mBook.getPosition()).multiply(THOUSAND).longValue();
		}
		Log.w(PlayerApplication.TAG, "Expected completion " + expectedCompletion / 1000 + " seconds");
		return expectedCompletion + System.currentTimeMillis();
	}

	private void setDataSource(MediaPlayer player, SoundBite bite) {
		FileInputStream stream = null;
		try {
			stream = PlayerApplication.getInstance().openFileInput(bite.getFilename());
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

	private void listenToConnectivity() {
		mNetworkStateReceiver = new BroadcastReceiver() {

			@Override
			public void onReceive(Context context, Intent intent) {
				mOnline = intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY, false) == false;
				Log.i(PlayerApplication.TAG, mOnline ? "Device is online" : "Device is offline");
				fireEvent(Event.CONNECTIVITY_CHANGED, mOnline);
				if (mOnline) {
					synchronized (mStreamingThread) {
						mStreamingThread.notify();
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

	private void fireEvent(final Event event, final Object... params) {
		fireEvent(event, mBook, params);
	}
	
	private void fireEvent(final Event event, Book book, final Object... params) {
		synchronized (LOCK) {
			for (EventListener listener : mEventListeners) {
				listener.onEvent(event, book, params);
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
			while (running()) {
				if (playing == false) {
					waitUp("Sleeping since no book has been set");
				} else if (mOnline) {
					SoundBite bite = null;
					do {
						if (mOnline == false) {
							waitUp("Not online. Going to sleep");
						}
						mDownloaderThread.giveWay();
						mBusy = true;
						BigDecimal currentPosition = isPlaying() ? new BigDecimal(mCurrentPlayer.getCurrentPosition()).divide(THOUSAND) : BigDecimal.ZERO;
						bite = task.doCaching(mBook, currentPosition, getExpectedCompletion());
						synchronized (mNextPlayerThread) {
							mNextPlayerThread.notify();
						}
					} while (bite != null);
					mBusy = false;
					synchronized (mDownloaderThread) {
						mDownloaderThread.notify();
					}
					waitUp(FIVE_MINUTES, "Streaming has nothing to do. Going to sleep");
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
					waitUp("Falling a sleep as next bite is already prepared");
				}
				if (playing == false) {
					waitUp("Next player going to sleep, as we are not playing currently");
				} else {
					SoundFragment fragment = mBook.getFragment(mCurrentEnd);
					SoundBite bite = fragment != null ? fragment.getBite(mCurrentEnd) : null;
					if (bite == null) {
						waitUp("Falling a sleep as no bite is available");
					} else if (mNextPlayer == null){
						synchronized (LOCK) {
							try {
								mCurrentEnd = mCurrentEnd.add(bite.getDuration());
								Log.i(PlayerApplication.TAG, String.format("In fragment: %s-%s of %s In book: %s-%s",
										bite.getStart(), bite.getEnd(), fragment.getEnd(),
										fragment.getPosition(bite.getStart()), fragment.getPosition(bite.getEnd())));
								if (bite.getEnd().compareTo(fragment.getEnd()) == 0) {
									Log.i(PlayerApplication.TAG, "Last bite. Adjusting current end with: " + fragment.getBookEndPosition().subtract(fragment.getBookStartPosition().add(fragment.getEnd())));
									mCurrentEnd = fragment.getBookEndPosition();
								}
								if (mCurrentEnd.compareTo(mBook.getPosition()) < 0) {
									Log.w(PlayerApplication.TAG, "Bite does not contain book position. Find next bite");
									continue;
								}
								Log.i(PlayerApplication.TAG, "Next player will be from fragment url: " + fragment.getUrl());
								if (mCurrentPlayer != null) {
									mNextPlayer = new MediaPlayer(mCurrentEnd.subtract(bite.getDuration()), mCurrentEnd);
									setDataSource(mNextPlayer, bite);
									mNextPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
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
	}

	private class ProgressThread extends WorkerThread {
		public ProgressThread() {
			super("Progress");
		}

		@Override
		public void run() {
			while (running()) {
				if (playing == false) {
					waitUp("No progress as no book is playing. Going to sleep");
				} else {
					synchronized (LOCK) {
						if (isPlaying()) {
							updateBookPosition();
							fireEvent(Event.PLAY_TIME_UPDATE, mBook.getId(), mBook.getPosition());
						}
					}
				}
				waitUp(100);
			}
		}
	}

}
