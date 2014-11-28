package dk.nota.lyt.player;

import android.app.IntentService;
import android.app.NotificationManager;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import dk.nota.lyt.Book;

public class PlayerCommands extends IntentService {

	private static final String NOTIFICATION_ID = "notificationId";
	private static final String BOOK_ID = "bookId";

	public static enum Command {
		PLAY, PLAY_DOWNLOADED, CANCEL_DOWNLOADED, PAUSE, STOP;
	}

	public PlayerCommands() {
		super("playCommand");
	}

	@Override
	protected void onHandleIntent(Intent intent) {
		NotificationManager manager = (NotificationManager) PlayerApplication.getInstance().getSystemService(PlayerActivity.NOTIFICATION_SERVICE);
		Book book = null;
		switch (Command.valueOf(intent.getAction())) {
		case PLAY:
			PlayerApplication.getInstance().getPlayer().play();
			break;
		case PLAY_DOWNLOADED:
			manager.cancel(intent.getExtras().getInt(NOTIFICATION_ID));
			book = PlayerApplication.getInstance().getBookService().getBook(intent.getStringExtra(BOOK_ID));
			PlayerApplication.getInstance().getPlayer().play(book.getId(), book.getPosition().toString());
			break;
		case CANCEL_DOWNLOADED:
			manager.cancel(intent.getExtras().getInt(NOTIFICATION_ID));
			book = PlayerApplication.getInstance().getBookService().getBook(intent.getStringExtra(BOOK_ID));
			PlayerApplication.getInstance().getPlayer().downloadCancelled(book);
			break;
		case PAUSE:
			PlayerApplication.getInstance().getPlayer().stop(false);
			break;
		case STOP:
			Intent newIntent = new Intent(PlayerApplication.getInstance(), PlayerActivity.class);
			newIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			newIntent.putExtra("shutdown", true);
			PlayerApplication.getInstance().startActivity(newIntent);
			break;
		default:
			Log.w(PlayerApplication.TAG, "Unknown command: " + intent.getAction());
			break;
		}
	}
	
	public static Intent getPlayDownloadedIntent(Book book, int notificationId) {
		Intent playIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		playIntent.setAction(PlayerCommands.Command.PLAY_DOWNLOADED.name());
		Bundle extras = new Bundle();
		extras.putString(BOOK_ID, book.getId());
		extras.putInt(NOTIFICATION_ID, notificationId);
		playIntent.putExtras(extras);
		return playIntent;
	}
	public static Intent getCancelDownloadedIntent(Book book, int notificationId) {
		Intent playIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		playIntent.setAction(PlayerCommands.Command.CANCEL_DOWNLOADED.name());
		Bundle extras = new Bundle();
		extras.putString(BOOK_ID, book.getId());
		extras.putInt(NOTIFICATION_ID, notificationId);
		playIntent.putExtras(extras);
		return playIntent;
	}
	
	public static Intent getPlayIntent(Book book) {
		Intent playIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		playIntent.setAction(PlayerCommands.Command.PLAY.name());
		playIntent.putExtra(BOOK_ID, book.getId());
		return playIntent;
	}

}
