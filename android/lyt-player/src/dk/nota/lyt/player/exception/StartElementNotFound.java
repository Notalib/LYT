package dk.nota.lyt.player.exception;

public class StartElementNotFound extends RuntimeException {

	private static final long serialVersionUID = 6668472059380253516L;

	public StartElementNotFound(String detailMessage) {
		super(detailMessage);
	}

}
