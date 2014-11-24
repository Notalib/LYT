package dk.nota.lyt.player.service;

import dk.nota.lyt.Book;
import dk.nota.lyt.BookInfo;

public interface BookService {

	Book getBook(String libraryId);
	Book setBook(String bookJSON);
	void updateBook(Book book);
	BookInfo[] getBookInfo();
	void clearBook(String bookId);
	void clearBookCache(String bookId);
}
