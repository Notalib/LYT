using System;
using System.Collections.Generic;
using System.IO;

namespace NOTA.MP3
{
    /// <summary>
    ///  Extracts frame information from MP3 files. Proof of concept for NOTA. November 10th 2014.
    /// 
    ///  Information about MP3 file format available at:
    ///    http://www.datavoyage.com/mpgscript/mpeghdr.htm
    /// </summary>
    public struct Frame
    {
        public long ByteOffset, ByteLength;
        public double TimeOffset, TimeDuration;
        
        public void WriteJSON(TextWriter output)
        {
            output.Write("{{\"byteOffset\": {0}, \"timeOffset\": {1:0.000000}, \"byteLength\": {2}, \"timeDuration\": {3:0.000000} }}",
                             ByteOffset, TimeOffset, ByteOffset, TimeDuration);
        }

        static public void WriteJSON(TextWriter output, IEnumerable<Frame> frames)
        {
            output.Write("[");

            bool firstLine = true;
            foreach (Frame frame in frames)
            {
                if (!firstLine)
                {
                    output.WriteLine(",");
                    output.Write(" ");
                }
                firstLine = false;
                frame.WriteJSON(output);
            }

            output.WriteLine("]");
        }
    } 

    public class Extracter
    {
        private readonly FileStream input;
        private readonly ErrorHandler errorHandler;
        private readonly double maxFrameSeconds;
        private readonly int maxFrameBytes;

        private long byteOffset = 0;
        private double msecOffset = 0;

        public delegate void ErrorHandler(string reason);

        private void registerDecodeProblem(string reason)
        {
            errorHandler(reason);
        }

        /// <summary>
        ///  returns whether we should keep on reading
        /// </summary>
        private bool readNextFrame()
        {
            byte[] header = new byte[4];
            int numRead = input.Read(header, 0, 4);
            if (numRead == 0)
            {
                // silently stop at end of file
                return false;
            }

            if (numRead != 4)
            {
                registerDecodeProblem("Missing 4 bytes frame header");
                return false;
            }

            if (header[0] != 0xff || (header[1] & 0xE0) != 0xE0)
            {
                registerDecodeProblem("Expected 11 first bits to be set");
                return false;
            }

            int audioVersionId = (header[1] & 0x18) >> 3;
            int audioVersion;
            switch (audioVersionId)
            {
                case 0:
                    audioVersion = 3; // actually means 2.5, but we want to stick to integers
                    break;
                case 2:
                    audioVersion = 2;
                    break;
                case 3:
                    audioVersion = 1;
                    break;
                default: // also catches case 1:
                    registerDecodeProblem("Unknown audio version ID");
                    return false;
            }

            int layerVersionId = (header[1] & 0x06) >> 1;
            int layerVersion;
            switch (layerVersionId)
            {
                case 1:
                    layerVersion = 3; // mp3
                    break;
                case 2:
                    layerVersion = 2;
                    break;
                case 3:
                    layerVersion = 1;
                    break;
                default: // also catches case 0:
                    registerDecodeProblem("Unknown layer description");
                    return false;
            }

            int bitrateIndex = (header[2] & 0xf0) >> 4;
            int[] bitrateLookup = new[] {
            // bits	   V1,L1   V1,L2    V1,L3  V2,L1  V2, L2 & L3
            /* 0000 */	 0,	      0,	  0,	  0,	  0,
            /* 0001 */	 32,     32,	 32,	 32,	  8,
            /* 0010 */	 64,     48,     40,	 48,	 16,
            /* 0011 */	96,	     56,	 48,	 56,	 24,
            /* 0100 */	128,	 64,	 56,	 64,	 32,
            /* 0101 */	160,	 80,	 64,	 80,	 40,
            /* 0110 */	192,	 96,	 80,	 96,	 48,
            /* 0111 */	224,	112,	 96,	112,	 56,
            /* 1000 */	256,	128,	112,	128,	 64,
            /* 1001 */	288,	160,	128,	144,	 80,
            /* 1010 */	320,	192,	160,	160,	 96,
            /* 1011 */	352,	224,	192,	176,	112,
            /* 1100 */	384,	256,	224,	192,	128,
            /* 1101 */	416,	320,	256,	224,    144,
            /* 1110 */	448,	384,	320,	256,	160,
            /* 1111 */	-1,	-1,	-1,	-1,	-1
            };

            int column;
            if (audioVersion == 1) column = layerVersion - 1;
            else if (layerVersion == 1) column = 3;
            else column = 4;

            int bitRate = bitrateLookup[5 * bitrateIndex + column] * 1000;
            if (bitRate < 0)
            {
                registerDecodeProblem("Bad bitrate index: " + bitrateIndex);
                return false;
            }
            if (bitRate == 0)
            {
                registerDecodeProblem("Free bitrate not supported");
                return false;
            }

            // Sampling rate frequency index (values are in Hz)
            //  bits	 MPEG1	MPEG2	MPEG2.5
            int[] sampleRateLookup = new[] {
             /* 00 */	44100,	22050,	11025,
             /* 01 */	48000,	24000,	12000,
             /* 10 */	32000,	16000,	 8000,
             /* 11 */	   -1,     -1,     -1
             };
            int sampleRateIndex = (header[2] & 0x0C) >> 2;
            column = audioVersion - 1;
            int sampleRate = sampleRateLookup[3 * sampleRateIndex + column];
            if (sampleRate <= 0)
            {
                registerDecodeProblem("Invalid sample rate index: " + sampleRateIndex);
                return false;
            }

            int padding = (header[2] & 0x2) >> 1;
            int frameLengthInBytes, samplesPerFrame;
            if (layerVersion == 1)
            {
                samplesPerFrame = 384;
                frameLengthInBytes = (12 * bitRate / sampleRate + padding) * 4;
            }
            else
            {
                samplesPerFrame = 1152;
                frameLengthInBytes = 144 * bitRate / sampleRate + padding;
            }

            double duration = (double)samplesPerFrame / sampleRate;

            //Console.WriteLine("Frame is mp{0} with bitrate={1}, samplerate={2}, bytelength = {3}, secsLength={4}",
            //                  layerVersion, bitRate, sampleRate, frameLengthInBytes, seconds);

            // skip past these frames
            byte[] ignore = new byte[frameLengthInBytes - 4];
            numRead = input.Read(ignore, 0, ignore.Length);
            if (numRead != ignore.Length)
            {
                registerDecodeProblem("Problem reading frame content");
                return false;
            }

            byteOffset += frameLengthInBytes;
            msecOffset += 1000.0 * duration;

            return true;
        }

        /// <summary>
        ///  Skip past ID3 in somewhat hackish fashing by looking for 0xff (8 consecutive bits set)
        /// </summary>
        private void skipID3()
        {
            while (true)
            {
                int c = input.ReadByte();
                if (c == -1) break; // EOF
                if (c == 0xff)
                {
                    // we get start of mp3 frame, and need to unread the given byte
                    input.Seek(-1, SeekOrigin.Current);
                    return;
                }

                byteOffset += 1;
            }
        }

        /// <summary>
        ///  Extract all frames from stream stopping on first error and joining frames
        ///  together as long as they are below the limits in seconds and bytes. 
        ///  Settings these limits to zero will return un-joined frames and 
        ///  50 frames per second is not unheard of.
        /// </summary>
        private IEnumerable<Frame> work()
        {
            skipID3();

            // keep reading until we are out of frames
            bool keepGoing = true;
            while (keepGoing)
            {
                long byteOffsetBefore = byteOffset;
                double timeOffsetBefore = msecOffset;

                while (keepGoing)
                {
                    keepGoing = readNextFrame();
                    double secsGone = 0.001 * (msecOffset - timeOffsetBefore);
                    long bytesSeen = byteOffset - byteOffsetBefore;

                    // we break when we have passed at least 10 seconds or at least 100 KBytes
                    if (secsGone >= maxFrameSeconds || bytesSeen >= maxFrameBytes) break;
                }

                // we only output if we actually passed some data
                if (byteOffsetBefore == byteOffset) continue;

                Frame frame = new Frame
                                  {
                                      ByteOffset = byteOffsetBefore,
                                      TimeOffset = 0.001*timeOffsetBefore,
                                      ByteLength = byteOffset - byteOffsetBefore,
                                      TimeDuration = 0.001*(msecOffset - timeOffsetBefore)
                                  };
                yield return frame;
            }
        }

        private Extracter(FileStream input, double maxFrameSeconds, int maxFrameBytes,
                          ErrorHandler errorHandler)
        {
            this.input = input;
            this.maxFrameSeconds = maxFrameSeconds;
            this.maxFrameBytes = maxFrameBytes;
            this.errorHandler = errorHandler;
        }

        public static IEnumerable<Frame> ProcessStream(FileStream input, double maxFrameSeconds, int maxFrameBytes,
                                                       ErrorHandler errorHandler)
        {
            Extracter extracter = new Extracter(input, maxFrameSeconds, maxFrameBytes, errorHandler);
            return extracter.work();
        }

        public static IEnumerable<Frame> ProcessFile(string filename, double maxFrameSeconds, int maxFrameBytes, 
                                                    ErrorHandler errorHandler)
        {
            FileStream input = new FileStream(filename, FileMode.Open, FileAccess.Read);
            return ProcessStream(input, maxFrameSeconds, maxFrameBytes, errorHandler);
        }
    }
    
    class AnalyseMP3
    {
        private static void processFile(string inputFilename, TextWriter output)
        {
            const int maxFrameSeconds = 10, maxFrameKBytes = 100;
            var frames = Extracter.ProcessFile(inputFilename, maxFrameSeconds, 1024 * maxFrameKBytes,
                reason =>
                {
                     Console.Error.WriteLine("Unable to process {0}: {1}", inputFilename, reason);
                     Environment.Exit(1);
                });
            Frame.WriteJSON(output, frames);
        }

        private static void processFilename(string filename)
        {
            // determine filename for output file, where extension is .json
            string outputFilename = filename;
            int index = outputFilename.LastIndexOf('.');
            if(index >= 0)
            {
                outputFilename = outputFilename.Substring(0, index) + ".json";
            }

            using (StreamWriter output = File.CreateText(outputFilename))
            {
                processFile(filename, output);
            }
        }

        static void Main(string[] args)
        {
            if(args.Length == 0)
            {             
                Console.Error.WriteLine("Must be called with filenames to mp3 files.");
                return;
            }


            foreach (string filename in args)
            {
                processFilename(filename);  
            }
        }
    }
}
