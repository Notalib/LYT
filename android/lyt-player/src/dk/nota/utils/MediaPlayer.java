package dk.nota.utils;

import java.math.BigDecimal;


public class MediaPlayer extends android.media.MediaPlayer {
	
	private BigDecimal start;

	private BigDecimal end;
	
	public MediaPlayer(BigDecimal start, BigDecimal end) {
		super();
		this.start = start;
		this.end = end;
	}
	
	public BigDecimal getStart() {
		return start;
	}

	public BigDecimal getEnd() {
		return end;
	}
}
