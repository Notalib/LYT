package dk.nota.lyt.player.task;

import dk.nota.lyt.Book;
import dk.nota.lyt.player.PlayerApplication;

public class GetBookTask extends AbstractTask<String, Book> {

	@Override
	Book doInBackground(String... libraryIds) {
		return PlayerApplication.getInstance().getBookService().getBook(libraryIds[0]);
	}
}
