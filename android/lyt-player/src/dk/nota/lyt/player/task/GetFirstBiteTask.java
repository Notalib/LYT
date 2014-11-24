package dk.nota.lyt.player.task;

import java.io.IOException;
import java.io.OutputStream;
import java.math.BigDecimal;

import android.content.Context;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.SoundBite;
import dk.nota.lyt.SoundFragment;
import dk.nota.lyt.player.PlayerApplication;
import dk.nota.lyt.player.service.BookService;
import dk.nota.lyt.player.service.MP3Fragment;
import dk.nota.lyt.player.service.MP3Service;

public class GetFirstBiteTask extends AbstractTask<Book, SoundBite> {
	
	private static final String TAG = GetFirstBiteTask.class.getSimpleName();
			
	
	private MP3Service mp3Service = PlayerApplication.getInstance().getMP3Service();
	private BookService bookService = PlayerApplication.getInstance().getBookService();

	@Override
	SoundBite doInBackground(Book...books) {
		
		if (books == null || books.length == 0) {
			throw new IllegalStateException("No book specified");
		}
		Book book = books[0];
		
		SoundFragment fragment = book.getCurrentFragment();
		SoundBite bite = fragment.getBite(book.getPosition());
		
		if (bite == null) {
			SoundBite hole = fragment.getHole(book.getPosition());
			BigDecimal start = fragment.getOffset(book.getPosition());
			BigDecimal calculatedEnd = start.add(new BigDecimal(30));
			MP3Fragment mp3 = mp3Service.getFragment(fragment.getUrl(), fragment.getOffset(book.getPosition()), calculatedEnd.compareTo(hole.getEnd()) <= 0 ? calculatedEnd : hole.getEnd());
			bite = new SoundBite(mp3.getStart(), mp3.getEnd());
			OutputStream output = null;
			try {
				output = PlayerApplication.getInstance().openFileOutput(bite.getFilename(), Context.MODE_PRIVATE);
				output.write(mp3.getBytes());
				fragment.addBite(bite);
				Log.i(TAG, String.format("Got first bite: %s. Bite: %s-%s", fragment.getUrl(), bite.getStart().toString(), bite.getEnd().toString()));
				bookService.updateBook(book);
			} catch (IOException e) {
				Log.e(TAG, "Unable to save mp3 fragment.", e);
				throw new IllegalStateException("Unable to save fragment", e);
			} finally {
				close(output);
			}
		}
		return bite;
	}

}
