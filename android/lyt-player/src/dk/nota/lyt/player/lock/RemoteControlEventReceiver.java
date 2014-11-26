package dk.nota.lyt.player.lock;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.view.KeyEvent;
import dk.nota.lyt.player.PlayerApplication;

public class RemoteControlEventReceiver extends BroadcastReceiver {

	@Override
	public void onReceive(Context context, Intent intent) {
		KeyEvent keyEvent = intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT);
		
		if (keyEvent.getAction() != KeyEvent.ACTION_UP) return;
		
		switch (keyEvent.getKeyCode()) {
			case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
				if (PlayerApplication.getInstance().getPlayer().isPlaying()) {
					PlayerApplication.getInstance().getPlayer().stop(false);
				} else {
					PlayerApplication.getInstance().getPlayer().play();
				}
				break;
			case KeyEvent.KEYCODE_MEDIA_NEXT:
				PlayerApplication.getInstance().getPlayer().next();
				break;
			case KeyEvent.KEYCODE_MEDIA_PREVIOUS:
				PlayerApplication.getInstance().getPlayer().previous();
				break;
		}
	}
}
