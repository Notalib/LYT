package dk.nota.lyt.player;

public enum Event {
	PLAY_TIME_UPDATE("play-time-update"),
	PLAY_STOP("play-stop"),
	PLAY_END("play-end"),
	PLAY_FAILED("play-failed"),
	DOWNLOAD_PROGRESS("download-progress"),
	DOWNLOAD_FAILED("download-failed"),
	DOWNLOAD_COMPLETED("download-completed");
	
	private String eventName;
	
	Event(String name) {
		this.eventName = "'"+name+"'";
	}
	
	String eventName() {
		return eventName;
	}
	
}
