package dk.nota.lyt.player;

import android.app.IntentService;
import android.content.Intent;
import android.util.Log;

public class PlayerCommands extends IntentService {
	
	public static enum Command {
		PLAY, PAUSE, STOP;
	}

	public PlayerCommands() {
		super("playCommand");
	}

	@Override
	protected void onHandleIntent(Intent intent) {
		switch (Command.valueOf(intent.getAction())) {
		case PLAY:
			PlayerApplication.getInstance().getPlayer().play();
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

}
