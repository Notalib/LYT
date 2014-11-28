package dk.nota.lyt.player;

public enum Event {
	PLAY_TIME_UPDATE("play-time-update"),
	PLAY_CHAPTER_CHANGE("play-chapter-change"),
	PLAY_PLAY("play-play"),
	PLAY_STOP("play-stop"),
	PLAY_END("play-end"),
	PLAY_FAILED("play-failed"),
	DOWNLOAD_STARTED("download-started"),
	DOWNLOAD_PROGRESS("download-progress"),
	DOWNLOAD_CANCELLED("download-cancelled"),
	DOWNLOAD_FAILED("download-failed"),
	DOWNLOAD_COMPLETED("download-completed"),
	CONNECTIVITY_CHANGED("connectivity-change");
	
	private String eventName;
	
	Event(String name) {
		this.eventName = "'"+name+"'";
	}
	
	String eventName() {
		return eventName;
	}
	
}
