package dk.nota.utils;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public final class HashUtils {

	
	public static byte[] getMd5HashValue(String input) {
		try {
			MessageDigest digester = MessageDigest.getInstance("MD5");
			return digester.digest(input.getBytes());
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException("MD5 algorithm does not exist on this device");
		}
	}
	public static String getSHA1HashValue(String input){
		try {
			MessageDigest digester = MessageDigest.getInstance("SHA1");
			return new String(digester.digest(input.getBytes()));
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException("SHA1 algorithm does not exist on this device");
		}
	}
}
