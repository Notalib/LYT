package dk.nota.lyt.player.task;

import dk.nota.lyt.Book;
import dk.nota.lyt.player.PlayerApplication;

public class SetBookTask extends AbstractTask<String, Book> {

	@Override
	Book doInBackground(String... params) {
		return PlayerApplication.getInstance().getBookService().setBook(params[0]);
	}
}
