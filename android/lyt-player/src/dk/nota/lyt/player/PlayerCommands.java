package dk.nota.lyt.player;

import android.app.IntentService;
import android.content.Intent;
import android.util.Log;
import dk.nota.lyt.Book;

public class PlayerCommands extends IntentService {
	
	public static enum Command {
		PLAY, PAUSE;
	}

	public PlayerCommands() {
		super("playCommand");
	}

	private static final String BOOK_ID = "bookId";

	@Override
	protected void onHandleIntent(Intent intent) {
		switch (Command.valueOf(intent.getAction())) {
		case PLAY:
			String bookId = intent.getStringExtra(BOOK_ID);
			if (bookId != null) {
				Book book = PlayerApplication.getInstance().getBookService().getBook(bookId);
				if (book != null) {
					PlayerApplication.getInstance().getPlayer().play(bookId, book.getPosition().toString());
				}
			}
			break;
		case PAUSE:
			PlayerApplication.getInstance().getPlayer().stop(false);
			break;
		default:
			Log.w(PlayerApplication.TAG, "Unknown command: " + intent.getAction());
			break;
		}
	}

}
