package dk.nota.lyt.player;

import org.json.JSONException;

import android.content.Context;
import android.webkit.JavascriptInterface;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import dk.nota.lyt.BookInfo;

public class PlayerInterface {

//	private final static String TAG = PlayerInterface.class.getName();
	private Gson gson = new GsonBuilder().create();
	
	interface Callback {
		void play(String bookId, String offset);
		void stop();
		
		boolean isPlaying();
		
		void setBook(String bookJSON);
		void clearBook(String bookId);
		void cacheBook(String bookId);
		BookInfo[] getBooks();
		void clearBookCache(String bookId);
	}

	private Callback callback;

	/** Instantiate the interface and set the context */
	PlayerInterface(Context c) {
		callback = (Callback) c;
	}

	@JavascriptInterface
	public void play(String bookId, String position) {
		callback.play(bookId, position);
	}
	
	@JavascriptInterface
	public boolean isPlaying() {
		return callback.isPlaying();
	}
	
	@JavascriptInterface
	public void stop() {
		callback.stop();
	}
	
	@JavascriptInterface
	public void setBook(String bookJSON) {
		callback.setBook(bookJSON);
	}
	
	@JavascriptInterface
	public String getBook(String bookId) {
		return gson.toJson(PlayerApplication.getInstance().getBookService().getBook(bookId));
	}
	
	@JavascriptInterface
	public String getBooks() throws JSONException {
		return gson.toJson(callback.getBooks());
	}
	
	void clearBookCache(String bookId) {
		callback.clearBookCache(bookId);
	}
	
	@JavascriptInterface
	public void clearBook(String bookId) {
		callback.clearBook(bookId);
	}
	
	@JavascriptInterface
	public void cacheBook(String bookId) {
		callback.cacheBook(bookId);
	}
}
