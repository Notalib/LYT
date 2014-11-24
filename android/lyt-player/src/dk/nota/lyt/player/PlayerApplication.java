package dk.nota.lyt.player;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import android.app.Application;
import android.content.pm.ApplicationInfo;
import android.util.Log;
import dk.nota.lyt.player.service.BookService;
import dk.nota.lyt.player.service.FileBookService;
import dk.nota.lyt.player.service.MP3Service;
import dk.nota.lyt.player.service.PhonyMP3Service;

public class PlayerApplication extends Application {

	public final static String TAG = PlayerApplication.class.getSimpleName();

	private static PlayerApplication instance;
	private boolean testMode;
	private boolean inBackGround;
	private BookService bookService;
	private MP3Service mp3Service;

	private static DateFormat weekdayFormatter;
	private static DateFormat dateLongFormatter;
	
	@Override
	public void onCreate() {
		testMode = (0 != (getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE));
		// service = new
		// AppEngineRejsekortServiceImpl("https://mine-rejser.appspot.com");
		Locale locale = new Locale("da", "DK");
		Locale.setDefault(locale);
		weekdayFormatter = new SimpleDateFormat("EEEE", locale);
		dateLongFormatter = DateFormat.getDateInstance(DateFormat.LONG, locale);
		instance = this;
		bookService = new FileBookService();
		mp3Service = new PhonyMP3Service();
	}

	public static PlayerApplication getInstance() {
		if (instance == null) throw new IllegalStateException("Application not initialized yet");
		return instance;
	}

	public boolean isProduction() {
		return testMode == false;
	}

	public String formatWeekday(Date dateTime) {
		String weekday = weekdayFormatter.format(dateTime);
		return weekday.substring(0, 1).toUpperCase(Locale.getDefault()) + weekday.substring(1);
	}

	public String formatLongDate(Date date) {
		if (date == null) return "";
		return dateLongFormatter.format(date);
	}

	public boolean isInBackGround() {
		return inBackGround;
	}
	
	public BookService getBookService() {
		return bookService;
	}
	
	public MP3Service getMP3Service() {
		return mp3Service;
	}
	
	public void setInBackGround(boolean inBackGround) {
		this.inBackGround = inBackGround;
		if (inBackGround == false) {
			synchronized (this) {
				Log.i("FLEMMING", "Waking up tasks");
				notifyAll();
			}
		}
	}
}
