package dk.nota.lyt;

import java.math.BigDecimal;

import lombok.Data;

@Data
public class Book {

	private String id;
	private String title;
	private String author;
	
	private SoundFragment[] playlist;
	private Section[] navigation;
	
	private BigDecimal position = BigDecimal.ZERO;
	
	public SoundFragment getFragment(BigDecimal position) {
		
		if (getEnd().compareTo(position) == 0) {
			return null;
		}
		for (int i = 0; i < playlist.length; i++) {
			SoundFragment fragment = playlist[i];
			if (fragment.getBookStartPosition().compareTo(position) <= 0 && fragment.getBookEndPosition().compareTo(position) > 0) {
				return fragment;
			}
		}
		throw new IllegalStateException("Could not find a fragment with book position: " + position);
	}
	
	public BigDecimal getEnd() {
		return playlist[playlist.length-1].getBookEndPosition();
	}
	
	public SoundFragment getCurrentFragment() {
		return getFragment(getPosition());
	}
	
	public Section getSection(BigDecimal currentPosition) {
		return navigation[getSectionIndex(currentPosition)];
	}
	
	public Section nextSection(BigDecimal currentPosition) {
		int index = getSectionIndex(currentPosition);
		return navigation[index+(index+1 < navigation.length ? 1 : 0)];
	}
	
	public boolean isDownloaded() {
		if (playlist == null) return false;
		
		boolean downloaded = true;
		for (SoundFragment fragment : playlist) {
			downloaded &= fragment.isDownloaded();
		}
		return downloaded;
	}
	
	public BookInfo getInfo() {
		BookInfo result = new BookInfo();
		result.setId(id);
		result.setOffset(position);
		result.setDownloaded(isDownloaded());
		return result;
	}
	
	private int getSectionIndex(BigDecimal position) {
		
		for (int i = 0; i < navigation.length; i++) {
			Section section = navigation[i];
			Section nextSection = i+1 < navigation.length ? navigation[i+1] : null;
			if (nextSection == null || (section.getOffset().compareTo(position) <= 0 && nextSection.getOffset().compareTo(position) > 0)) {
				return i;
			}
		}
		throw new IllegalStateException("Should have returned last section");
	}
	
}
