package dk.nota.lyt;

import java.math.BigDecimal;

import lombok.Data;

/**
 * A condensed version of a book
 * @author flemming
 */
@Data
public class BookInfo {
	
	private String id;
	private BigDecimal offset;
	private boolean downloaded;
}
