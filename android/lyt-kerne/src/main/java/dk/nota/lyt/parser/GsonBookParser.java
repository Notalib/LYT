package dk.nota.lyt.parser;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import lombok.Cleanup;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import dk.nota.lyt.Book;
import dk.nota.lyt.SoundFragment;

public class GsonBookParser implements BookParser {
	
	private Gson gson = new GsonBuilder().setPrettyPrinting().create();
	
	@Override
	public Book parse(String json) {
		return parse(new ByteArrayInputStream(json.getBytes()));
	}

	@Override
	public Book parse(InputStream bookStream) {
		try {
			@Cleanup Reader bookReader = getReader(bookStream);
			Book book = gson.fromJson(bookReader, Book.class);
			
			BigDecimal position = BigDecimal.ZERO;
			List<SoundFragment> mergedPlaylist = new ArrayList<>();
			SoundFragment mergeStart = null;
			for (SoundFragment fragment : book.getPlaylist()) {
				if (mergeStart == null || mergeStart.getEnd().compareTo(fragment.getStart()) != 0 || mergeStart.getUrl().equals(fragment.getUrl()) == false) {
					fragment.setBookStartPosition(position);
					mergeStart = fragment;
					mergedPlaylist.add(fragment);
				} else if(mergeStart != null) {
					mergeStart.setEnd(fragment.getEnd());
				}
				position = position.add(fragment.getEnd().subtract(fragment.getStart()).add(fragment.getAlignment()));
			}
			book.setPlaylist(mergedPlaylist.toArray(new SoundFragment[0]));
			return book;
		} catch (IOException e) {
			throw new IllegalStateException("Unable to parse book or fragments", e);
		}
	}
	
	private Reader getReader(InputStream input) {
		try {
			return new BufferedReader(new InputStreamReader(input, "UTF-8"));
		} catch (UnsupportedEncodingException e) {	
			throw new IllegalStateException("UTF-8 was not supported", e);
		}
	}
	
	@Override
	public String stringify(Book book) {
		return gson.toJson(book);
	}
}
