package dk.nota.lyt.player.service;

import java.math.BigDecimal;

public interface MP3Service {

	 MP3Fragment getFragment(String url, BigDecimal start, BigDecimal end);
}
