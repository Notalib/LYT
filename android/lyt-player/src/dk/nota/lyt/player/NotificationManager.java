package dk.nota.lyt.player;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Intent;
import android.graphics.Bitmap;
import dk.nota.lyt.Book;
import dk.nota.lyt.Section;
import dk.nota.lyt.player.task.AbstractTask;
import dk.nota.lyt.player.task.LoadNotificationBookCoverTask;
import dk.nota.lyt.player.task.StreamBiteTask;
import dk.nota.player.R;

public class NotificationManager {

	private static final int NOTIFICATION_DOWNLOAD_ID = 42;  
	private static final int NOTIFICATION_PLAY_ID = 43;  
	
	private Notification.Builder mDownloadBuilder = null;
	private Notification.Builder mPlayBuilder = null;
	private Bitmap mLargeIcon;
	private android.app.NotificationManager mNotifyMgr = (android.app.NotificationManager) PlayerApplication.getInstance().getSystemService(PlayerActivity.NOTIFICATION_SERVICE);

	public void notifyDownloadStart(Book book) {
		mDownloadBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_ic_action_download);
		mDownloadBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.download_title, book.getTitle(), book.getAuthor()))
			    .setContentText(PlayerApplication.getInstance().getString(R.string.download_in_progress))
			    .setContentIntent(getLauncherIntent())
			    .setOngoing(true)
				.setProgress(book.getEnd().intValue(), 0, false);
		mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
	}
	
	public void notifyDownloadProgress(Book book, StreamBiteTask.StreamBite bite) {
		if (bite != null) {
			mDownloadBuilder.setProgress(book.getEnd().intValue(), bite.getPosition().intValue(), false);
			mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
		}
	}

	public void notifyDownloadCompletion() {
		mDownloadBuilder.setOngoing(false)
			.setAutoCancel(true)
			.setContentText(PlayerApplication.getInstance().getString(R.string.download_completed))
			.setProgress(0, 0, false);
		mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
	}
	
	public void notifyPlaying(Book book) {
		Section section = book.getSection(book.getPosition()) ;

		mPlayBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_av_play_circle_outline);
		mPlayBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.play_title, book.getTitle()))
			    .setContentText(section != null ? section.getTitle() : "")
			    .setContentIntent(getLauncherIntent())
			    .setLargeIcon(mLargeIcon)
			    .setOngoing(true);
		Intent pauseIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		pauseIntent.setAction(PlayerCommands.Command.PAUSE.name());
		PendingIntent pi = PendingIntent.getService(PlayerApplication.getInstance(), 0, pauseIntent, PendingIntent.FLAG_CANCEL_CURRENT);
		
		String bigText = PlayerApplication.getInstance().getString(R.string.play_big_style, (section != null ? section.getTitle() : ""), book.getAuthor());
		addStopAction().setStyle(new Notification.BigTextStyle().bigText(bigText))
			.addAction(R.drawable.ic_stat_av_pause_circle_outline, PlayerApplication.getInstance().getString(R.string.play_pause), pi);
		mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
		new LoadNotificationBookCoverTask().execute(new AbstractTask.SimpleTaskListener<Bitmap>() {
			@Override
			public void success(Bitmap result) {
				if (result != null) {
					mPlayBuilder.setLargeIcon(result);
					mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
				}
				mLargeIcon = result;
			}
		}, book);
	}
	
	public void notifyChapterChange(Book book) {
		Section section = book.getSection(book.getPosition()) ;
		String bigText = PlayerApplication.getInstance().getString(R.string.play_big_style, (section != null ? section.getTitle() : ""), book.getAuthor());
		mPlayBuilder.setContentText(section != null ? section.getTitle() : "")
			.setStyle(new Notification.BigTextStyle().bigText(bigText));
		mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
	}

	public void notifyPause(Book book) {
		Section section = book.getSection(book.getPosition()) ;
		mPlayBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_av_pause_circle_outline);
		mPlayBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.play_title, book.getTitle()))
			    .setContentText(section != null ? section.getTitle() : "")
			    .setContentIntent(getLauncherIntent())
			    .setLargeIcon(mLargeIcon)
			    .setOngoing(true);
		Intent playIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		playIntent.setAction(PlayerCommands.Command.PLAY.name());
		playIntent.putExtra("bookId", book.getId());
		PendingIntent piPlay = PendingIntent.getService(PlayerApplication.getInstance(), 0, playIntent, 0);
		
		String bigText = PlayerApplication.getInstance().getString(R.string.play_big_style, (section != null ? section.getTitle() : ""), book.getAuthor());
		addStopAction().setStyle(new Notification.BigTextStyle().bigText(bigText))
			.addAction(R.drawable.ic_stat_av_play_circle_outline, PlayerApplication.getInstance().getString(R.string.play_play), piPlay);
		mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
	}
	
	public void stopPlayer() {
		mNotifyMgr.cancel(NOTIFICATION_PLAY_ID);
	}
	
	private Notification.Builder addStopAction() {
		Intent playIntent = new Intent(PlayerApplication.getInstance(), PlayerCommands.class);
		playIntent.setAction(PlayerCommands.Command.STOP.name());
		PendingIntent piStop = PendingIntent.getService(PlayerApplication.getInstance(), 0, playIntent, 0);
		return mPlayBuilder.addAction(R.drawable.ic_stat_av_stop, PlayerApplication.getInstance().getString(R.string.play_stop), piStop);
	}
	
	private PendingIntent getLauncherIntent() {
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
