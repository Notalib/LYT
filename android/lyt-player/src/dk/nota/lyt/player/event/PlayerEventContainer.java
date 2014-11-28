package dk.nota.lyt.player.event;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import dk.nota.lyt.Book;

public class PlayerEventContainer implements OnPlayerEvent {
	
	private List<OnPlayerEvent> mEventListeners = new ArrayList<>();

	public void addEventListener(OnPlayerEvent listener) {
		this.mEventListeners.add(listener);
	}
	
	public void removeEventListener(OnPlayerEvent listener) {
		mEventListeners.remove(listener);
	}


	@Override
	public void onTimeUpdate(Book book, BigDecimal position) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onTimeUpdate(book, position);
		}
	}

	@Override
	public void onChapterChange(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onChapterChange(book);
		}
	}

	@Override
	public void onPlay(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onPlay(book);
		}
	}

	@Override
	public void onStop(Book book, boolean fullStop) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onStop(book, fullStop);
		}
	}

	@Override
	public void onEnd(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onEnd(book);
		}
	}

	@Override
	public void onPlayFailed(Book book, String reason) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onPlayFailed(book, reason);
		}
	}

	@Override
	public void onDownloadStarted(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onDownloadStarted(book);
		}
	}

	@Override
	public void onDownloadProgress(Book book, BigDecimal percentage) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onDownloadProgress(book, percentage);
		}
	}

	@Override
	public void onDownloadCancelled(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onDownloadCancelled(book);
		}
	}

	@Override
	public void onDownloadFailed(Book book, String reason) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onDownloadFailed(book, reason);
		}
	}

	@Override
	public void onDownloadCompleted(Book book) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onDownloadCompleted(book);
		}
	}

	@Override
	public void onConnectivityChanged(boolean online) {
		for (OnPlayerEvent listener : mEventListeners) {
			listener.onConnectivityChanged(online);
		}
	}
}
