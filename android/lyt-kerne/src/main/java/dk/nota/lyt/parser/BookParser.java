package dk.nota.lyt.parser;

import java.io.InputStream;

import dk.nota.lyt.Book;

public interface BookParser {

	Book parse(InputStream bookStream);
	Book parse(String json);
	
	String stringify(Book book);
}
