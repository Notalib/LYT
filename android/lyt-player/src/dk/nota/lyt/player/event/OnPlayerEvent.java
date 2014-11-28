package dk.nota.lyt.player.event;

import java.math.BigDecimal;

import dk.nota.lyt.Book;

public interface OnPlayerEvent {
	
	void onTimeUpdate(Book book, BigDecimal position);
	void onChapterChange(Book book);
	void onPlay(Book book);
	void onStop(Book book, boolean fullStop);
	void onEnd(Book book);
	void onPlayFailed(Book book, String reason);
	
	void onDownloadStarted(Book book);
	void onDownloadProgress(Book book, BigDecimal percentage);
	void onDownloadCancelled(Book book);
	void onDownloadFailed(Book book, String reason);
	void onDownloadCompleted(Book book);
	
	void onConnectivityChanged(boolean online);
}
