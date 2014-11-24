package dk.nota.lyt.player.service;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.math.BigDecimal;

import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import dk.nota.lyt.player.PlayerApplication;
import dk.nota.lyt.player.exception.StartElementNotFound;

public class PhonyMP3Service implements MP3Service {
	
	private static final String TAG = MP3Service.class.getSimpleName();
			
	
	private Gson gson = new GsonBuilder().create();
	private DefaultHttpClient client = new DefaultHttpClient();

	/**
	 * Params are as following: url, start, end
	 */
	@Override
	public MP3Fragment getFragment(String url, BigDecimal start, BigDecimal end) {
		String filename = url.substring(url.lastIndexOf('/')+1).replace(".mp3", ".json"); 
		
		InputStream input = null;
		OutputStream output = null;
		try {
			input = PlayerApplication.getInstance().getAssets().open("bunkerjson/"+filename);
			MP3File mp3 = new MP3File(url, gson.fromJson(new InputStreamReader(input), MP3Info[].class));
			MP3Info infoStart = mp3.findStartElement(start);
			MP3Info infoEnd = mp3.findEndElement(end);
			
			HttpGet get = new HttpGet(url);
			get.addHeader("Accept", "audio/mpeg3");
			get.addHeader("X-Time-Range", String.format("%s-%s", start.toString(), end.toString()));
			get.addHeader("Range", String.format("bytes=%d-%d", infoStart.byteOffset, (infoEnd.byteOffset+infoEnd.byteLength)));
			
			HttpResponse response = client.execute(get);
			if (response.getStatusLine().getStatusCode() >= 200 && response.getStatusLine().getStatusCode() < 300) {
				MP3Fragment fragment = new MP3Fragment(infoStart.timeOffset, infoEnd.timeOffset.add(infoEnd.timeDuration));
				response.getEntity().writeTo(fragment.getOutputStream());
				return fragment;
			} else {
				Log.w(TAG, "Unable to read mp3 segment");
				Log.w(TAG, response.getStatusLine().getReasonPhrase());
				throw new IllegalStateException();
			}
		} catch (StartElementNotFound e) {
			throw e;
		} catch (Exception e) {
			Log.w(TAG, "Unable to read json file", e);
			throw new IllegalStateException("Unable to read data from network");
		} finally {
			close(input);
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

	
	//"byteOffset": 1673, "timeOffset": 0, "byteLength": 102817, "timeDuration": 4.264
	
	private static class MP3File {
		
		private MP3Info[] infoes;
		private String url;
		
		MP3File(String url, MP3Info[] infoes) {
			this.infoes = infoes;
			this.url = url;
		}
		
		MP3Info findStartElement(BigDecimal start) {
			for (MP3Info info : infoes) {
				if (info.timeOffset.compareTo(start) <= 0 && info.timeOffset.add(info.timeDuration).compareTo(start) > 0) {
					return info;
				}
			}
			throw new StartElementNotFound(String.format("Did not find start element in url: %s. Start defined as: %s", url, start.toString()));
		}
		
		MP3Info findEndElement(BigDecimal end) {
			for (MP3Info info : infoes) {
				if (info.timeOffset.compareTo(end) < 0 && info.timeOffset.add(info.timeDuration).compareTo(end) >= 0) {
					return info;
				}
			}
			throw new IllegalStateException(String.format("Did not find end element in url: %s. End defined as: %s", url, end.toString()));
		}
	}
	
	
	private static class MP3Info {
		public int byteOffset;
		public int byteLength;
		public BigDecimal timeOffset;
		public BigDecimal timeDuration;
	}
}
