package dk.nota.lyt.player.task;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import android.annotation.SuppressLint;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import dk.nota.lyt.Book;
import dk.nota.lyt.player.PlayerApplication;

public class LoadNotificationBookCoverTask extends AbstractTask<Book, Bitmap> {

	@SuppressLint("DefaultLocale")
	@Override
	Bitmap doInBackground(Book... params) {
		return getBitmapFromURL(String.format("http://bookcover.e17.dk/%s_w160.jpg", params[0].getId()));
	}
	
	static Bitmap getBitmapFromURL(String src) {
	    try {
	        URL url = new URL(src);
	        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
	        connection.setDoInput(true);
	        connection.connect();
	        InputStream input = connection.getInputStream();
	        Bitmap myBitmap = BitmapFactory.decodeStream(input);
	        return myBitmap;
	    } catch (IOException e) {
	    	Log.w(PlayerApplication.TAG, "Unable to load book cover");
	        return null;
	    }
	}

}
