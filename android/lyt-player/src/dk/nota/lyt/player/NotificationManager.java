package dk.nota.lyt.player;

import java.math.BigDecimal;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Intent;
import android.graphics.Bitmap;
import dk.nota.lyt.Book;
import dk.nota.lyt.Section;
import dk.nota.lyt.player.BookPlayer.EventListener;
import dk.nota.lyt.player.task.AbstractTask;
import dk.nota.lyt.player.task.LoadNotificationBookCoverTask;
import dk.nota.player.R;

public class NotificationManager implements EventListener {

	private static final int NOTIFICATION_DOWNLOAD_ID = 42;  
	private static final int NOTIFICATION_PLAY_ID = 43;  
	
	private Notification.Builder mDownloadBuilder = null;
	private Notification.Builder mPlayBuilder = null;
	private Bitmap mLargeIcon;
	private Bitmap mLargeDownloadIcon;
	private android.app.NotificationManager mNotifyMgr = (android.app.NotificationManager) PlayerApplication.getInstance().getSystemService(PlayerActivity.NOTIFICATION_SERVICE);

	private void notifyDownloadStart(Book book) {
		mDownloadBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_ic_action_download);
		mDownloadBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.download_title, book.getTitle(), book.getAuthor()))
			    .setContentText(PlayerApplication.getInstance().getString(R.string.download_in_progress))
			    .setContentIntent(getLauncherIntent())
			    .setOngoing(true)
				.setProgress(book.getEnd().intValue(), 0, false);
		new LoadNotificationBookCoverTask().execute(new AbstractTask.SimpleTaskListener<Bitmap>() {
			@Override
			public void success(Bitmap result) {
				if (result != null) {
					mDownloadBuilder.setLargeIcon(mLargeDownloadIcon = result);
					mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
				}
			}
		}, book);
		Intent playIntent = PlayerCommands.getCancelDownloadedIntent(book, NOTIFICATION_DOWNLOAD_ID);
		PendingIntent piCancel = PendingIntent.getService(PlayerApplication.getInstance(), 0, playIntent, 0);
		mDownloadBuilder.addAction(R.drawable.ic_stat_av_not_interested, PlayerApplication.getInstance().getString(R.string.download_cancel), piCancel);

		mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
	}
	
	private void notifyDownloadProgress(Book book, BigDecimal percentage) {
		mDownloadBuilder.setProgress(100, percentage.intValue(), false);
		mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
	}

	private void notifyDownloadCompletion(Book book) {
		mDownloadBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_ic_action_download);
		mDownloadBuilder.setOngoing(false)
			.setAutoCancel(true)
			.setLargeIcon(mLargeDownloadIcon)
			.setContentText(PlayerApplication.getInstance().getString(R.string.download_completed))
			.setProgress(0, 0, false);

		Intent playIntent = PlayerCommands.getPlayDownloadedIntent(book, NOTIFICATION_DOWNLOAD_ID);
		PendingIntent piPlay = PendingIntent.getService(PlayerApplication.getInstance(), 0, playIntent, 0);
		mDownloadBuilder.addAction(R.drawable.ic_stat_av_play_circle_outline, PlayerApplication.getInstance().getString(R.string.play_play), piPlay);
		mNotifyMgr.notify(NOTIFICATION_DOWNLOAD_ID, mDownloadBuilder.build());
		mLargeDownloadIcon = null;
	}
	
	private void notifyPlaying(Book book) {
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
	
	private void notifyChapterChange(Book book) {
		Section section = book.getSection(book.getPosition()) ;
		String bigText = PlayerApplication.getInstance().getString(R.string.play_big_style, (section != null ? section.getTitle() : ""), book.getAuthor());
		mPlayBuilder.setContentText(section != null ? section.getTitle() : "")
			.setStyle(new Notification.BigTextStyle().bigText(bigText));
		mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
	}

	private void notifyPause(Book book) {
		Section section = book.getSection(book.getPosition()) ;
		mPlayBuilder = new Notification.Builder(PlayerApplication.getInstance()).setSmallIcon(R.drawable.ic_stat_av_pause_circle_outline);
		mPlayBuilder.setContentTitle(PlayerApplication.getInstance().getString(R.string.play_title, book.getTitle()))
			    .setContentText(section != null ? section.getTitle() : "")
			    .setContentIntent(getLauncherIntent())
			    .setLargeIcon(mLargeIcon)
			    .setOngoing(true);
		
		PendingIntent piPlay = PendingIntent.getService(PlayerApplication.getInstance(), 0, PlayerCommands.getPlayIntent(book), 0);
		
		String bigText = PlayerApplication.getInstance().getString(R.string.play_big_style, (section != null ? section.getTitle() : ""), book.getAuthor());
		addStopAction().setStyle(new Notification.BigTextStyle().bigText(bigText))
			.addAction(R.drawable.ic_stat_av_play_circle_outline, PlayerApplication.getInstance().getString(R.string.play_play), piPlay);
		mNotifyMgr.notify(NOTIFICATION_PLAY_ID, mPlayBuilder.build());
	}
	
	private void notifyBookEnd() {
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

	@Override
	public void onEvent(Event event, Book book, Object... params) {
		switch (event) {
		case PLAY_FAILED:
		case PLAY_STOP:
			notifyPause(book);
			if (Boolean.TRUE.equals(params.length > 1 ? params[1] : Boolean.FALSE)) {
				notifyBookEnd();
			}
			break;
		case PLAY_END:
			notifyBookEnd();
			break;
		case PLAY_CHAPTER_CHANGE:
			notifyChapterChange(book);
			break;
		case PLAY_PLAY:
			notifyPlaying(book);
			break;
		case DOWNLOAD_STARTED:
			notifyDownloadStart(book);
			break;
		case DOWNLOAD_PROGRESS:
			notifyDownloadProgress(book, (BigDecimal) params[1]);
			break;
		case DOWNLOAD_COMPLETED:
			notifyDownloadCompletion(book);
			break;
		default:
			break;
		}
		
	}

}
