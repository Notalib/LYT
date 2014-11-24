package dk.nota.lyt;

import java.math.BigDecimal;
import java.util.UUID;

import lombok.Data;

/**
 * The position within the URL. Not the entire book
 * @author flemming
 *
 */
@Data
public class SoundBite {
	
	private String filename;
	private BigDecimal start;
	private BigDecimal end;
	
	public SoundBite() {}
	
	public SoundBite(BigDecimal start, BigDecimal end) {
		if (start == null || end == null) {
			throw new IllegalStateException("Both start and end must be specified");
		}
		if (end.compareTo(start) <= 0) {
			throw new IllegalStateException("End must be after start");
		}
		this.start = start;
		this.end = end;
		this.filename = UUID.randomUUID().toString();
	}
	
	public BigDecimal getRemainder(BigDecimal offset) {
		return end.subtract(offset);
	}
	
	public BigDecimal getDuration() {
		return end.subtract(start);
	}
}
