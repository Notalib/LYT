package dk.nota.lyt.player;

public enum Event {
	TIME_UPDATE("play-time-update"),
	END("play-end"),
	DOWNLOAD_PROGRESS("download-progress"),
	DOWNLOAD_FAILED("download-failed"),
	DOWNLOAD_COMPLETED("download-completed");
	
	private String eventName;
	
	Event(String name) {
		this.eventName = name;
	}
	
	String eventName() {
		return eventName;
	}
	
}
