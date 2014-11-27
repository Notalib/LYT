package dk.nota.lyt.player.task;

import java.io.Closeable;
import java.io.IOException;
import java.io.OutputStream;
import java.math.BigDecimal;

import android.content.Context;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.SoundBite;
import dk.nota.lyt.SoundFragment;
import dk.nota.lyt.player.PlayerApplication;
import dk.nota.lyt.player.exception.StartElementNotFound;
import dk.nota.lyt.player.service.BookService;
import dk.nota.lyt.player.service.MP3Fragment;
import dk.nota.lyt.player.service.MP3Service;

public class StreamBiteTask {
	
	private static final String LOCK = StreamBiteTask.class.getSimpleName() + ".lock";
			
	
	public static class StreamBite {
		SoundBite bite;
		BigDecimal position;
		private StreamBite(SoundBite bite, BigDecimal position) {
			this.bite = bite;
			this.position = position;
		}
		public SoundBite getBite() {
			return bite;
		}
		public BigDecimal getPosition() {
			return position;
		}
	}
	
	public interface OnProgress {
		void onProgress(BigDecimal position);
	}
	
	private static final String TAG = StreamBiteTask.class.getSimpleName();
			
	private static final int MAX_STREAM_TIME = 60 * 20;
	private static final int SUFFICIENT_CACHE = MAX_STREAM_TIME - (60 * 5);
	private static final BigDecimal SMALL_CHUNCK = new BigDecimal(30);
	private static final BigDecimal BIG_CHUNCK = new BigDecimal(60);
	
	private MP3Service mp3Service = PlayerApplication.getInstance().getMP3Service();
	private BookService bookService = PlayerApplication.getInstance().getBookService();
	
	private boolean eject = false;
	private OnProgress callback;
	
	public StreamBiteTask() {
		
	}
	
	public StreamBiteTask(OnProgress callback) {
		this.callback = callback;
	}
	
	public void eject() {
		eject = true;
	}

	public SoundBite doCaching(Book book, BigDecimal currentPosition, long expectedCompletion) {
		StreamBite bite = doCaching(book, currentPosition, expectedCompletion, false);
		return bite != null ? bite.bite : null;
	}
	
	public StreamBite doDownload(Book book) {
		return doCaching(book, null, -1, true);
	}
	private StreamBite doCaching(Book book, BigDecimal currentPosition, long expectedCompletion, boolean downloadAll) {
		
		SoundBite bite = null;
		SoundFragment fragment = null;
		Log.i(TAG, Thread.currentThread().getName() + " wants lock");
		synchronized (LOCK) {
			Log.i(TAG, Thread.currentThread().getName() + " got lock");
			eject = false;
			
			if (book == null) {
				throw new IllegalStateException("No book specified");
			}
			
			fragment = getFragment(book);
			if (fragment == null) return null;
	
			OutputStream output = null;
			SoundBite hole = fragment.getHoles(downloadAll ? BigDecimal.ZERO : book.getPosition()).get(0);
			
			BigDecimal position = book.getPosition().add(currentPosition == null ? BigDecimal.ZERO : currentPosition);
			BigDecimal cachedSeconds = fragment.getPosition(hole.getStart()).subtract(position);
			if (cachedSeconds.intValue() > SUFFICIENT_CACHE && downloadAll == false) {
				Log.i(TAG, String.format("Sufficient cache (%s seconds). Not downloading anymore", cachedSeconds));
				return null;
			}
			Log.i(TAG, Thread.currentThread().getName() + " is starting caching of " + fragment.getUrl()+ " from: " + hole.getStart());
			
			boolean failed = false;
			int totalTime = 0;
			try {
				do {
					BigDecimal start = bite == null ? hole.getStart() : bite.getEnd();
					BigDecimal calculatedEnd = start.add(downloadAll ? BIG_CHUNCK : SMALL_CHUNCK);
					try {
						MP3Fragment mp3 = mp3Service.getFragment(fragment.getUrl(), start, calculatedEnd.compareTo(hole.getEnd()) <= 0 ? calculatedEnd : hole.getEnd());
						totalTime += mp3.getDuration();
						if (bite == null) {
							bite = new SoundBite(mp3.getStart(), mp3.getEnd()); 
							output = PlayerApplication.getInstance().openFileOutput(bite.getFilename(), Context.MODE_PRIVATE);
						} else {
							bite.setEnd(mp3.getEnd());
						}
						if (callback != null) callback.onProgress(fragment.getPosition(bite.getEnd()));
						output.write(mp3.getBytes());
					} catch(StartElementNotFound e) {
						Log.w(TAG, String.format("playlist and json not aligned. Wrong by: %s", hole.getEnd().subtract(bite.getEnd())));
						hole.setEnd(bite.getEnd());
						fragment.setNewEnd(bite.getEnd());
					}
				} while(eject == false && totalTime < MAX_STREAM_TIME && hole.getEnd().compareTo(bite.getEnd()) != 0 && (System.currentTimeMillis() < expectedCompletion - 10000 || downloadAll));
			} catch (Exception e) {
				Log.e(TAG, "Error occured with " + Thread.currentThread().getName() + " thread", e);
				failed = true;
				return null;
			} finally {
				if (failed == false || (bite != null && bite.getDuration().compareTo(SMALL_CHUNCK) >= 0)) {
					fragment.addBite(bite);
					Log.i(TAG, String.format(Thread.currentThread().getName() + " cached: %s. Bite: %s-%s of %s", fragment.getUrl(), bite.getStart().toString(), bite.getEnd().toString(), fragment.getEnd().toString()));
					bookService.updateBook(book);
				} else {
					if (bite != null && bite.getFilename() != null) {
						PlayerApplication.getInstance().deleteFile(bite.getFilename());
					}
				}
				close(output);
			}
		}
		return new StreamBite(bite, fragment.getPosition(bite.getEnd()));
	}
	
	private void close(Closeable closeable) {
		if (closeable == null) return;
		
		try {
			closeable.close();
		} catch (IOException e) {
			Log.w(TAG, "Unable to close stream", e);
		}
	}
		
	private SoundFragment getFragment(Book book) {
		SoundFragment fragment = book.getCurrentFragment();
		while(fragment != null && fragment.isDownloaded()) {
			fragment = book.getFragment(fragment.getBookEndPosition());
		}
		return fragment;
	}
}
