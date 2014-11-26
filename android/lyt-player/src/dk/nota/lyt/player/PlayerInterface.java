package dk.nota.lyt.player;

import org.json.JSONException;

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

	private BookPlayer player;

	/** Instantiate the interface and set the context */
	PlayerInterface(BookPlayer player) {
		this.player = player;
	}

	@JavascriptInterface
	public void play(String bookId, String position) {
		player.play(bookId, position);
	}
	
	@JavascriptInterface
	public boolean isPlaying() {
		return player.isPlaying();
	}
	
	@JavascriptInterface
	public void stop() {
		player.stop();
	}
	
	@JavascriptInterface
	public void pause() {
		player.stop();
	}
	
	@JavascriptInterface
	public void setBook(String bookJSON) {
		player.setBook(bookJSON);
	}
	
	@JavascriptInterface
	public String getBook(String bookId) {
		return gson.toJson(PlayerApplication.getInstance().getBookService().getBook(bookId));
	}
	
	@JavascriptInterface
	public String getBooks() throws JSONException {
		return gson.toJson(player.getBooks());
	}
	
	void clearBookCache(String bookId) {
		player.clearBookCache(bookId);
	}
	
	@JavascriptInterface
	public void clearBook(String bookId) {
		player.clearBook(bookId);
	}
	
	@JavascriptInterface
	public void cacheBook(String bookId) {
		player.cacheBook(bookId);
	}
}
