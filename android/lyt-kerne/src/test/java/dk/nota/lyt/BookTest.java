package dk.nota.lyt;

import java.io.ByteArrayInputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.util.List;

import junit.framework.TestCase;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import dk.nota.lyt.parser.BookParser;
import dk.nota.lyt.parser.GsonBookParser;

public class BookTest extends TestCase {
	
	private Book book;
	private Book bunker137;
	private BookParser parser = new GsonBookParser();
	private Gson gson = new GsonBuilder().setPrettyPrinting().create();

	private static final String URL_1 = "http://m.e17.dk/DodpFiles/10066850/36016/1_Bognummer_36016__HC_.mp3";
	private static final String URL_2 = "http://m.e17.dk/DodpFiles/10066850/36016/2_Oplysninger_om_denne.mp3";
	private static final String URL_3 = "http://m.e17.dk/DodpFiles/10066850/36016/3_Grantret.mp3";
		
	private static final String NAME_1 = "Bognummer 36016 - H.C. Andersen: Grantræet";
	private static final String NAME_2 = "Oplysninger om denne udgave af bogen";
	private static final String NAME_3 = "Grantræet";
			
	
	protected void setUp() throws Exception {
		InputStream input = getClass().getClassLoader().getResourceAsStream("book.json");
		assertNotNull(input);
		book = parser.parse(input);
		assertNotNull(book);
		close(input);
		input = getClass().getClassLoader().getResourceAsStream("37027.json");
		assertNotNull(input);
		bunker137 = parser.parse(input);
		assertNotNull(bunker137);
		close(input);
	}
	
	private void close(Closeable closeable) {
		if (closeable == null) return;
		
		try {
			closeable.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	
	public void testBook() {
		assertEquals("Grantræet", book.getTitle());
		assertEquals("36016", book.getId());
		assertEquals(3, book.getPlaylist().length);
		assertEquals(3, book.getNavigation().length);
		assertEquals(BigDecimal.ZERO, book.getPosition());
		assertFalse(book.isDownloaded());
		assertEquals(BigDecimal.ZERO, book.getInfo().getOffset());
		assertFalse(book.getInfo().isDownloaded());
	}
	
	public void testBookStartPosition() {
		assertEquals(BigDecimal.ZERO, book.getPlaylist()[0].getBookStartPosition());
		assertEquals(new BigDecimal("12.30367346938784"), book.getPlaylist()[1].getBookStartPosition());
		assertEquals(new BigDecimal("45.19183673469428"), book.getPlaylist()[2].getBookStartPosition());
	}
	
	public void testFindingFirstFragment() {
		assertEquals(URL_1, book.getFragment(BigDecimal.ZERO).getUrl());
		assertEquals(URL_1, book.getFragment(new BigDecimal(12)).getUrl());
		assertEquals(URL_1, book.getFragment(new BigDecimal("12.30367346938783")).getUrl());
	}
	
	public void testFindingSecondFragment() {
		assertEquals(URL_2, book.getFragment(new BigDecimal("12.30367346938784")).getUrl());
		assertEquals(URL_2, book.getFragment(new BigDecimal(35)).getUrl());
		assertEquals(URL_2, book.getFragment(new BigDecimal("45.19183673469427")).getUrl());
	}
	
	public void testFindingThirdFragment() {
		assertEquals(URL_3, book.getFragment(new BigDecimal("45.19183673469428")).getUrl());
		assertEquals(URL_3, book.getFragment(new BigDecimal(1101)).getUrl());
		assertEquals(URL_3, book.getFragment(new BigDecimal("1402.64571428441310")).getUrl());
		assertNull(URL_3, book.getFragment(new BigDecimal("1402.64571428441311")));
		book.setPosition(new BigDecimal("45.19183673469428"));
		assertEquals(URL_3, book.getCurrentFragment().getUrl());
	}
	
	public void testFindFirstSection() {
		assertEquals(NAME_1, book.getSection(BigDecimal.ZERO).getName());
		assertEquals(NAME_1, book.getSection(new BigDecimal(12)).getName());
		assertEquals(NAME_1, book.getSection(new BigDecimal("12.30367346938783")).getName());
	}

	public void testFindingSecondSection() {
		assertEquals(NAME_2, book.getSection(new BigDecimal("12.30367346938784")).getName());
		assertEquals(NAME_2, book.getSection(new BigDecimal(35)).getName());
		assertEquals(NAME_2, book.getSection(new BigDecimal("45.19183673469427")).getName());
	}
	
	public void testFindingThirdSection() {
		assertEquals(NAME_3, book.getSection(new BigDecimal("45.19183673469428")).getName());
		assertEquals(NAME_3, book.getSection(new BigDecimal(1101)).getName());
		assertEquals(NAME_3, book.getSection(new BigDecimal("1409.64571428441310")).getName());
		assertEquals(NAME_3, book.getSection(new BigDecimal("1409.64571428441311")).getName());
		assertEquals(NAME_3, book.getSection(new BigDecimal("14091243123")).getName());
	}
	
	public void testFragmentOffset() {
		SoundFragment fragment = book.getFragment(BigDecimal.ZERO);
		assertEquals(0, fragment.getOffset(BigDecimal.ZERO).compareTo(BigDecimal.ZERO));
		assertEquals(0, fragment.getOffset(new BigDecimal(12)).compareTo(new BigDecimal(12)));
		assertEquals(0, fragment.getOffset(new BigDecimal("12.30367346938783")).compareTo(new BigDecimal("12.30367346938783")));
		
		BigDecimal base2 = new BigDecimal("12.30367346938784");
		fragment = book.getFragment(base2);
		assertEquals(0, fragment.getOffset(base2).compareTo(BigDecimal.ZERO));
		assertEquals(0, fragment.getOffset(new BigDecimal(35)).compareTo(new BigDecimal(35).subtract(base2)));
		assertEquals(0, fragment.getOffset(new BigDecimal("45.19183673469427")).compareTo(new BigDecimal("45.19183673469427").subtract(base2)));
		assertEquals(0, fragment.getPosition(BigDecimal.ZERO).compareTo(base2));
		
		BigDecimal base3 = new BigDecimal("45.19183673469428");
		fragment = book.getFragment(base3);
		assertEquals(0, fragment.getOffset(base3).compareTo(new BigDecimal(7)));
		assertEquals(0, fragment.getOffset(new BigDecimal(1101)).compareTo((new BigDecimal(1101).subtract(base3)).add(new BigDecimal(7))));
		assertEquals(0, fragment.getPosition(new BigDecimal(7)).compareTo(base3));
	}
	
	public void testFragmentAlignment() {
		BigDecimal base3 = new BigDecimal("45.19183673469428");
		BigDecimal length = new BigDecimal("1364.45387754971883");
		BigDecimal start = new BigDecimal(7);
		BigDecimal alignment = new BigDecimal("0.066");
		BigDecimal newEnd = length.subtract(alignment);
		SoundFragment fragment = book.getFragment(base3);
		assertEquals(base3.add(length).subtract(start), fragment.getBookEndPosition());
		fragment.setEnd(length.subtract(alignment));
		assertNotSame(base3.add(length).subtract(start), fragment.getBookEndPosition());
		fragment.setEnd(length);
		assertEquals(base3.add(length).subtract(start), fragment.getBookEndPosition());
		fragment.setNewEnd(newEnd);
		assertEquals(base3.add(length).subtract(start), fragment.getBookEndPosition());
		fragment.setEnd(length);
		newEnd = length.add(alignment);
		fragment.setNewEnd(newEnd);
		assertEquals(base3.add(length).subtract(start), fragment.getBookEndPosition());
//		assertEquals(0, fragment.getOffset(new BigDecimal(1101)).compareTo((new BigDecimal(1101).subtract(base3)).add(new BigDecimal(7))));
//		assertEquals(0, fragment.getPosition(new BigDecimal(7)).compareTo(base3));
	}
	
	public void testLookupSoundBites() {
		SoundBite bite = new SoundBite(BigDecimal.ZERO, new BigDecimal(12));

		SoundFragment fragment = book.getFragment(BigDecimal.ZERO);
		fragment.addBite(bite);
		
		bite = fragment.getBite(BigDecimal.ZERO);
		assertNotNull(bite);
		BigDecimal offset = fragment.getOffset(BigDecimal.ZERO); 
		assertEquals(0, bite.getRemainder(offset).compareTo(new BigDecimal(12)));
		offset = fragment.getOffset(new BigDecimal(5));
		assertEquals(0, bite.getRemainder(offset).compareTo(new BigDecimal(7)));
		assertNull(fragment.getBite(new BigDecimal("12.01")));
		
		fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		bite = new SoundBite(new BigDecimal(20), new BigDecimal(100));
		fragment.addBite(bite);
		
		bite = fragment.getBite(BigDecimal.ZERO);
		assertNull(bite);
		// Since there is a start of 7 in the last playlist element, 20 really means that the soundbite is 13 seonds into the last fragment.
		bite = fragment.getBite(new BigDecimal("58.19183673469427"));
		assertNull(bite);
		bite = fragment.getBite(new BigDecimal("58.19183673469428"));
		offset = fragment.getOffset(new BigDecimal("58.19183673469428")); 
		assertNotNull(bite);
		assertEquals(0, bite.getRemainder(offset).compareTo(new BigDecimal(80)));
		offset = fragment.getOffset(new BigDecimal("137.19183673469428")); 
		assertEquals(0, bite.getRemainder(offset).compareTo(new BigDecimal(1)));

		bite = fragment.getBite(new BigDecimal("138.19183673469428"));
		assertNull(bite);		
	}
	
	public void testLookupSoundbiteThatStartsBeforeStartOffset() {
		BigDecimal position = new BigDecimal("45.19183673469428");
		SoundFragment fragment = book.getFragment(position);
		SoundBite bite = new SoundBite(new BigDecimal("6.667"), new BigDecimal(100));
		fragment.addBite(bite);
		
		bite = fragment.getBite(position);
		assertNotNull(bite);
		assertEquals(0, fragment.getOffset(position).compareTo(new BigDecimal(7)));
		assertEquals(0, bite.getRemainder(fragment.getOffset(position)).compareTo(new BigDecimal(100).subtract(new BigDecimal(7))));
		
	}
	
	public void testLookup3Holes() {
		SoundFragment fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		SoundBite bite = new SoundBite(new BigDecimal(20), new BigDecimal(100));
		fragment.addBite(bite);
		bite = new SoundBite(new BigDecimal(790), new BigDecimal(1101));
		fragment.addBite(bite);
		
		assertNotNull(fragment.getHoles());
		assertEquals(3, fragment.getHoles().size());
		assertEquals(0, fragment.getHoles().get(0).getStart().compareTo(new BigDecimal(7)));
		assertEquals(0, fragment.getHoles().get(0).getEnd().compareTo(new BigDecimal(20)));
		assertEquals(0, fragment.getHoles().get(1).getStart().compareTo(new BigDecimal(100)));
		assertEquals(0, fragment.getHoles().get(1).getEnd().compareTo(new BigDecimal(790)));
		assertEquals(0, fragment.getHoles().get(2).getStart().compareTo(new BigDecimal(1101)));
		assertEquals(0, fragment.getHoles().get(2).getEnd().compareTo(new BigDecimal("1364.45387754971883")));

		BigDecimal base = new BigDecimal("45.19183673469428");
		assertEquals(0, fragment.getHole(base).getStart().compareTo(new BigDecimal(7)));
		assertEquals(0, fragment.getHole(base).getEnd().compareTo(new BigDecimal(20)));

		assertEquals(0, fragment.getHole(base.add(new BigDecimal(100))).getStart().compareTo(new BigDecimal(100)));
		assertEquals(0, fragment.getHole(base.add(new BigDecimal(100))).getEnd().compareTo(new BigDecimal(790)));

		assertEquals(0, fragment.getHole(base.add(new BigDecimal(1101))).getStart().compareTo(new BigDecimal(1101)));
		assertEquals(0, fragment.getHole(base.add(new BigDecimal(1101))).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
		
		assertNull(fragment.getHole(base.add(new BigDecimal(20-7))));
		assertNull(fragment.getHole(base.add(new BigDecimal(790-7))));

		List<SoundBite> holes = fragment.getHoles(base.add(new BigDecimal(13)));
		assertEquals(0, holes.get(0).getStart().compareTo(new BigDecimal(100)));
		assertEquals(0, holes.get(0).getEnd().compareTo(new BigDecimal(790)));
		assertEquals(0, holes.get(1).getStart().compareTo(new BigDecimal(1101)));
		assertEquals(0, holes.get(1).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
		holes = fragment.getHoles(base.add(new BigDecimal(783)));
		assertEquals(0, holes.get(0).getStart().compareTo(new BigDecimal(1101)));
		assertEquals(0, holes.get(0).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
		
		holes = fragment.getHoles(base.add(new BigDecimal(1094)));
		assertEquals(0, holes.get(0).getStart().compareTo(new BigDecimal(1101)));
		assertEquals(0, holes.get(0).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
	}
	
	public void testLookup1FromStartHoles() {
		SoundFragment fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		SoundBite bite = new SoundBite(new BigDecimal(7), new BigDecimal(100));
		fragment.addBite(bite);
		
		assertNotNull(fragment.getHoles());
		assertEquals(1, fragment.getHoles().size());
		assertEquals(0, fragment.getHoles().get(0).getStart().compareTo(new BigDecimal(100)));
		assertEquals(0, fragment.getHoles().get(0).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
	}
	
	public void testLookup1FromEndHoles() {
		BigDecimal position = new BigDecimal("45.19183673469428");
		SoundFragment fragment = book.getFragment(position);
		SoundBite bite = new SoundBite(new BigDecimal(37), new BigDecimal("1364.45387754971883"));
		fragment.addBite(bite);
		
		assertNotNull(fragment.getHoles());
		assertEquals(1, fragment.getHoles().size());
		assertEquals(0, fragment.getHoles().get(0).getStart().compareTo(new BigDecimal(7)));
		assertEquals(0, fragment.getHoles().get(0).getEnd().compareTo(new BigDecimal(37)));
		assertFalse(fragment.isDownloaded());
		assertNotNull(fragment.getHole(position));
		assertEquals(0, fragment.getHole(position).getStart().compareTo(new BigDecimal(7)));
		assertEquals(0, fragment.getHole(position).getEnd().compareTo(new BigDecimal(37)));

	}
	
	public void testLookupNoHoles() {
		BigDecimal position = new BigDecimal("45.19183673469428");
		SoundFragment fragment = book.getFragment(position);
		SoundBite bite = new SoundBite(new BigDecimal(7), new BigDecimal("1364.45387754971883"));
		fragment.addBite(bite);
		
		assertNotNull(fragment.getHoles());
		assertEquals(0, fragment.getHoles().size());
		assertTrue(fragment.isDownloaded());
		assertNull(fragment.getHole(position));
	}
	
	public void testLookupNoHolesInBook() {
		SoundFragment fragment = book.getFragment(BigDecimal.ZERO);
		SoundBite bite = new SoundBite(BigDecimal.ZERO, new BigDecimal("12.30367346938784"));
		fragment.addBite(bite);
		BigDecimal base2 = new BigDecimal("12.30367346938784");
		fragment = book.getFragment(base2);
		bite = new SoundBite(BigDecimal.ZERO, new BigDecimal("32.88816326530644"));
		fragment.addBite(bite);
		fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		bite = new SoundBite(new BigDecimal(7), new BigDecimal("1364.45387754971883"));
		fragment.addBite(bite);
		
		assertTrue(book.isDownloaded());
	}
	
	public void testLookupHolesTwoAdjacentBites() {
		SoundFragment fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		SoundBite bite = new SoundBite(new BigDecimal(7), new BigDecimal(100));
		fragment.addBite(bite);
		bite = new SoundBite(new BigDecimal(100), new BigDecimal(200));
		fragment.addBite(bite);
		assertEquals(new BigDecimal(100), bite.getDuration());
		
		assertNotNull(fragment.getHoles());
		assertEquals(1, fragment.getHoles().size());
		assertEquals(0, fragment.getHoles().get(0).getStart().compareTo(new BigDecimal(200)));
		assertEquals(0, fragment.getHoles().get(0).getEnd().compareTo(new BigDecimal("1364.45387754971883")));		
	}
	
	public void testLookupWhereBiteStartsBefore() {
		SoundFragment fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		SoundBite bite = new SoundBite(new BigDecimal("6.674"), new BigDecimal("100"));
		fragment.addBite(bite);
		
		assertNotNull(fragment.getHoles());
		assertEquals(1, fragment.getHoles().size());
		assertEquals(0, fragment.getHoles().get(0).getStart().compareTo(new BigDecimal("100")));
		assertEquals(0, fragment.getHoles().get(0).getEnd().compareTo(new BigDecimal("1364.45387754971883")));
	}
	
	public void testSaveAndRestore() {
		SoundFragment fragment = book.getFragment(new BigDecimal("45.19183673469428"));
		SoundBite bite = new SoundBite(new BigDecimal("6.674"), new BigDecimal("100"));
		fragment.addBite(bite);
		
		String json = gson.toJson(book);
		ByteArrayInputStream input = new ByteArrayInputStream(json.getBytes());
		Book newBook = parser.parse(input);
		assertEquals(book, newBook);
		for(int i = 0; i < book.getPlaylist().length; i++) {
			assertEquals(book.getPlaylist()[i], newBook.getPlaylist()[i]);
			for (int j = 0; j < book.getPlaylist()[i].getBites().size(); j++) {
				assertEquals(book.getPlaylist()[i].getBites().get(j), newBook.getPlaylist()[i].getBites().get(j));
			}
		}
		for(int i = 0; i < book.getNavigation().length; i++) {
			assertEquals(book.getNavigation()[i], newBook.getNavigation()[i]);
		}
		bite = new SoundBite(new BigDecimal("100"), new BigDecimal("212"));
		newBook.getFragment(new BigDecimal("45.19183673469428")).addBite(bite);		
		assertNotSame(book, newBook);
	}
	
	public void testThatPlaylistsAreMerged() {
		assertNotSame(1808, bunker137.getPlaylist().length);
		SoundFragment fragment = bunker137.getFragment(new BigDecimal("5.198"));
		assertEquals("http://localhost:9000/DodpFiles/20353/37027/02_Om_denne_udgave.mp3", fragment.getUrl());
		assertEquals(BigDecimal.ZERO, fragment.getStart());
		assertEquals(new BigDecimal("30.798"), fragment.getEnd());
		fragment = bunker137.getFragment(new BigDecimal("67.382"));
		assertEquals("http://localhost:9000/DodpFiles/20353/37027/05_Kapitel_1.mp3", fragment.getUrl());
		assertEquals(BigDecimal.ZERO, fragment.getStart());
		assertEquals(new BigDecimal("2223.526"), fragment.getEnd());
		
	}
}
