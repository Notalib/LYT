package dk.nota.lyt.player.task;

import java.io.Closeable;
import java.io.IOException;

import android.os.AsyncTask;
import android.util.Log;

@SuppressWarnings("unchecked")
public abstract class AbstractTask<Params, Result> {

	public static interface TaskListener<Result> {

		abstract void success(Result result);

		abstract void done();

		abstract void failure(Exception e);

		abstract void networkFailure();
	}

	private static final String TAG = "FLEMMING";
	private static boolean isRunning;

	abstract Result doInBackground(Params... params);

	public void execute(final TaskListener<Result> listener, Params... params) {

		if (listener == null) throw new IllegalStateException("No listener specified");

		new AsyncTask<Params, Void, Result>() {

			Exception exception;

			@Override
			protected void onPreExecute() {
				isRunning = true;
			}

			@Override
			protected Result doInBackground(Params... params) {
				Result r = null;
				try {
					r = AbstractTask.this.doInBackground(params);
				} catch (Exception e) {
					Log.w(TAG, "Unable to fetch in background", e);
					exception = e;
				}
//				synchronized (PlayerApplication.getInstance()) {
//					if (PlayerApplication.getInstance().isInBackGround()) {
//						try {
//							Log.i(TAG, "Making the task wait");
//							PlayerApplication.getInstance().wait();
//						} catch (InterruptedException e) {
//							Log.e(TAG, "Task was interrupted", e);
//						}
//					}
//				}
				return r;
			}

			@Override
			protected void onPostExecute(Result result) {
				if (exception == null) {
					listener.success(result);
				} else {
					listener.failure(exception);
				}
				isRunning = false;
				listener.done();
			}
		}.execute(params);
	}
	
	protected void close(Closeable closeable) {
		if (closeable == null) return;
		
		try {
			closeable.close();
		} catch (IOException e) {
			Log.w(TAG, "Unable to close stream", e);
		}
	}

	public static boolean isRunning() {
		return isRunning;
	}	
	
	public abstract static class SimpleTaskListener<Result> implements TaskListener<Result> {

		@Override
		public void done() {
		}

		@Override
		public void failure(Exception e) {
		}

		@Override
		public void networkFailure() {
		}
	}
}
