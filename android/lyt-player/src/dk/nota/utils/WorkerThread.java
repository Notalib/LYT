package dk.nota.utils;

import android.util.Log;
import dk.nota.lyt.player.PlayerApplication;

public class WorkerThread extends Thread {

	private boolean run = true;
	
	public WorkerThread(String name) {
		super(name);
	}

	protected void waitUp(String reason) {
		waitUp(Long.MAX_VALUE, reason);
	}
	
	protected void waitUp(long period) {
		waitUp(period, null);
	}
	protected void waitUp(long period, String reason) {
		try {
			synchronized (this) {
				if (reason != null) Log.i(PlayerApplication.TAG, reason);
				wait(period);
			}
		} catch (InterruptedException e) {
			Log.w(PlayerApplication.TAG, "Lock was interrupted");
		}			
	}
	
	protected boolean running() {
		return run;
	}
	
	public void shutdown() {
		run = false;
		synchronized (this) {
			notify();
		}
	}

}
