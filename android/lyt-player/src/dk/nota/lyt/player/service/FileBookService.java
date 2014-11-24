package dk.nota.lyt.player.service;

import java.io.Closeable;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.content.Context;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.BookInfo;
import dk.nota.lyt.SoundBite;
import dk.nota.lyt.SoundFragment;
import dk.nota.lyt.parser.BookParser;
import dk.nota.lyt.parser.GsonBookParser;
import dk.nota.lyt.player.PlayerApplication;

public class FileBookService implements BookService {

	private static final String BOOK_POSTFIX = ".book.json";

	private static final String TAG = FileBookService.class.getSimpleName();

	private BookParser parser = new GsonBookParser();
	private Map<String, Book> books = new HashMap<>();
			
	@Override
	public Book getBook(String libraryId) {
		InputStream input = null;
		try {
			if (books.containsKey(libraryId) == false)  {
				input = PlayerApplication.getInstance().openFileInput(libraryId+BOOK_POSTFIX);
				books.put(libraryId, parser.parse(input));
			}
			return books.get(libraryId);
		} catch (FileNotFoundException e) {
			Log.i(TAG, String.format("Book with id: %s was not found", libraryId));
		} finally {
			close(input);
		}
		return null;
	}
	
	/**
	 * Keep the old book
	 */
	@Override
	public Book setBook(String bookJSON) {
		Book book = parser.parse(bookJSON);
		Book existingBook = getBook(book.getId());
		if (existingBook == null) {
			books.put(book.getId(), book);
			saveBook(book);
		}
		return existingBook != null ? existingBook : book;
	}
	
	@Override
	public void updateBook(Book book) {
		saveBook(book);
	}
	
	@Override
	public void clearBook(String bookId) {
		Book book = getBook(bookId);
		if (book != null) {
			clearBookCache(bookId);
			PlayerApplication.getInstance().deleteFile(bookId+BOOK_POSTFIX);
			books.remove(bookId);
		}
	}
	
	@Override
	public void clearBookCache(String bookId) {
		Book book = getBook(bookId);
		if (book != null) {
			for (SoundFragment fragment : book.getPlaylist()) {
				for (SoundBite bite : fragment.getBites()) {
					PlayerApplication.getInstance().deleteFile(bite.getFilename());
				}
			}
		}
	}
	
	@Override
	public BookInfo[] getBookInfo() {
		String[] files = PlayerApplication.getInstance().fileList();
		List<BookInfo> info = new ArrayList<>();
		for (String file : files) {
			if (file.endsWith(BOOK_POSTFIX)) {
				InputStream input = null;
				try {
					info.add(parser.parse(input = PlayerApplication.getInstance().openFileInput(file)).getInfo());
				} catch (IOException e) {
					Log.w(PlayerApplication.TAG, "Unable to read book from file: " + file, e);
				} finally {
					close(input);
				}
			}
		}
		return info.toArray(new BookInfo[info.size()]);
	}
	
	private void saveBook(Book book) {
		OutputStream output = null;
		try {
			output = PlayerApplication.getInstance().openFileOutput(book.getId()+BOOK_POSTFIX, Context.MODE_PRIVATE);
			output.write(parser.stringify(book).getBytes());
		} catch (IOException e) {
			Log.e(PlayerApplication.TAG, "Unable to save book", e);
			throw new IllegalStateException("Unable to save book", e);
		} finally {
			close(output);
		}
	}

	private void close(Closeable closeable) {
		if (closeable == null) return;
		
		try {
			closeable.close();
		} catch (IOException e) {
			Log.w(TAG, "Unable to close stream", e);
		}
	}

}
