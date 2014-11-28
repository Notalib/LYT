package dk.nota.lyt.player.event;

import java.math.BigDecimal;

import dk.nota.lyt.Book;

public class SimplePlayerListener implements OnPlayerEvent {

	@Override
	public void onTimeUpdate(Book book, BigDecimal position) {
	}

	@Override
	public void onChapterChange(Book book) {
	}

	@Override
	public void onPlay(Book book) {
	}

	@Override
	public void onStop(Book book, boolean fullStop) {
	}

	@Override
	public void onEnd(Book book) {
	}

	@Override
	public void onPlayFailed(Book book, String reason) {
	}

	@Override
	public void onDownloadStarted(Book book) {
	}

	@Override
	public void onDownloadProgress(Book book, BigDecimal percentage) {
	}

	@Override
	public void onDownloadCancelled(Book book) {
	}

	@Override
	public void onDownloadFailed(Book book, String reason) {
	}

	@Override
	public void onDownloadCompleted(Book book) {
	}

	@Override
	public void onConnectivityChanged(boolean online) {
	}
}
