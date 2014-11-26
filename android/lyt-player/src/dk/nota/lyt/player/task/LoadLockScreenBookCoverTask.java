package dk.nota.lyt.player.task;

import android.annotation.SuppressLint;
import android.graphics.Bitmap;
import dk.nota.lyt.Book;

public class LoadLockScreenBookCoverTask extends AbstractTask<Book, Bitmap> {

	@SuppressLint("DefaultLocale")
	@Override
	Bitmap doInBackground(Book... params) {
		return LoadNotificationBookCoverTask.getBitmapFromURL(String.format("http://bookcover.e17.dk/%s_w540.jpg", params[0].getId()));
	}
}
