package dk.nota.lyt;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import lombok.Data;

@Data
public class SoundFragment {
	
	private String url;
	private BigDecimal start;
	private BigDecimal end;
	
	private BigDecimal bookStartPosition;
	private BigDecimal alignment = BigDecimal.ZERO;
	
	private List<SoundBite> bites = new ArrayList<>();
	
	public BigDecimal getBookEndPosition() {
		return bookStartPosition.add(end.subtract(start)).add(alignment);
	}
	
	public void addBite(SoundBite bite) {
		bites.add(bite);
	}
	
	public BigDecimal getOffset(BigDecimal position) {
		return start.add(position.subtract(bookStartPosition));
	}
	
	public BigDecimal getPosition(BigDecimal offset) {
		return offset.add(bookStartPosition).subtract(start);
	}
	
	/**
	 * The position within the book
	 */
	public SoundBite getBite(BigDecimal position) {
		
		BigDecimal offset = getOffset(position);
		
		for (int i = 0; i < bites.size(); i++) {
			SoundBite bite = bites.get(i);
			if (bite.getStart().compareTo(offset) <= 0 && bite.getEnd().compareTo(offset) > 0) {
				return bite;
			}
		}
		return null;
	}
	
	public List<SoundBite> getHoles() {
		Collections.sort(bites, new BiteComparator());
		List<SoundBite> holes = new ArrayList<>();
		SoundBite hole = new SoundBite();
		hole.setStart(getStart());
		for (SoundBite bite : bites) {
			if (bite.getStart().compareTo(hole.getStart()) <= 0) {
				hole.setStart(bite.getEnd());
			} else if (bite.getStart().compareTo(hole.getStart()) > 0) {
				hole.setEnd(bite.getStart());
				holes.add(hole);
				hole = new SoundBite();
				hole.setStart(bite.getEnd());
			}
		}
		if (bites.isEmpty() || bites.get(bites.size()-1).getEnd().compareTo(end) < 0 ) {
			hole.setEnd(end);
			holes.add(hole);
		}
		return holes;
	}
	
	public SoundBite getHole(BigDecimal position) {
		List<SoundBite> holes = getHoles();
		BigDecimal offset = getOffset(position);
		for (SoundBite hole : holes) {
			if (hole.getStart().compareTo(offset) <= 0 && hole.getEnd().compareTo(offset) > 0) {
				return hole;
			}
		}
		return null;
	}
	
	public List<SoundBite> getHoles(BigDecimal position) {
		List<SoundBite> holes = getHoles();
		List<SoundBite> result = new ArrayList<>();
		BigDecimal offset = getOffset(position);
		for (SoundBite hole : holes) {
			if (hole.getEnd().compareTo(offset) > 0) {
				result.add(hole);
			}
		}
		return result;
	}
	
	public boolean isDownloaded() {
		return getHoles().size() == 0;
	}
	
	public void setNewEnd(BigDecimal newEnd) {
		alignment = end.subtract(newEnd);
		end = newEnd;
	}

	private static class BiteComparator implements Comparator<SoundBite> {

		@Override
		public int compare(SoundBite o1, SoundBite o2) {
			return o1.getStart().compareTo(o2.getStart());
		}
		
	}
}
