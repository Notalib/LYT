package dk.nota.lyt.player.service;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.math.BigDecimal;

public class MP3Fragment {

	private ByteArrayOutputStream output;
	private BigDecimal start;
	private BigDecimal end;
	
	MP3Fragment(BigDecimal start, BigDecimal end) {
		output = new ByteArrayOutputStream();
		this.start = start;
		this.end = end;
	}
	
	OutputStream getOutputStream() {
		return output;
	}

	public byte[] getBytes() {
		return output.toByteArray();
	}
	public BigDecimal getStart() {
		return start;
	}
	public BigDecimal getEnd() {
		return end;
	}
	
	public int getDuration() {
		return end.subtract(start).intValue();
	}
}
