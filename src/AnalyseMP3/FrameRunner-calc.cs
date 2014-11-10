using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace NOTA
{
    /// <summary>
    ///  Extracts frame information from MP3 files. Proof of concept for NOTA. November 10th 2014.
    /// 
    ///  Information about MP3 file format available at:
    ///    http://www.datavoyage.com/mpgscript/mpeghdr.htm
    /// </summary>
    class FrameRunnerCalc
    {
        private static long ByteOffset = 0;
        private static double TimeOffset = 0;

        static void registerDecodeProblem(string reason)
        {
            Console.Error.WriteLine(reason);
        }

        /// <summary>
        ///  returns whether we should keep on reading
        /// </summary>
        /// <param name="stream"></param>
        static bool readNextFrame(FileStream stream)
        {
            byte[] header = new byte[4];
            int numRead = stream.Read(header, 0, 4);
            if(numRead == 0)
            {
                // silently stop at end of file
                return false;
            }

            if (numRead != 4)
            {
                registerDecodeProblem("Missing 4 byte frame header");
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
                case 1:
                default:
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
                case 0:
                default:
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

            int bitRate = bitrateLookup[5*bitrateIndex + column] * 1000;
            if(bitRate < 0)
            {
                registerDecodeProblem("Bad bitrate index: " + bitrateIndex);
                return false;
            }
            if(bitRate == 0)
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
            int sampleRate = sampleRateLookup[3*sampleRateIndex + column];
            if(sampleRate <= 0)
            {
                registerDecodeProblem("Invalid sample rate index: " + sampleRateIndex);
                return false;
            }

            int padding = (header[2] & 0x2) >> 1;
            int frameLengthInBytes, samplesPerFrame;
            if(layerVersion == 1)
            {
                samplesPerFrame = 384;
                frameLengthInBytes = (12 * bitRate / sampleRate + padding) * 4;
            } 
            else
            {
                samplesPerFrame = 1152;
                frameLengthInBytes = 144*bitRate/sampleRate + padding;
            }

            double duration = (double) samplesPerFrame/sampleRate;

            Console.WriteLine("Frame is mp{0} with bitrate={1}, samplerate={2}, padding={3}, bytelength = {4}, secsLength={5}",
                              layerVersion, bitRate, sampleRate, padding, frameLengthInBytes, duration);

            // skip past these frames
            byte[] ignore = new byte[frameLengthInBytes - 4];
            numRead = stream.Read(ignore, 0, ignore.Length);
            if (numRead != ignore.Length)
            {
                registerDecodeProblem("Problem reading frame content");
                return false;
            }

            ByteOffset += frameLengthInBytes;
            TimeOffset += duration;

            return true;
        }

        /// <summary>
        ///  Skip past ID3 in somewhat hackish fashing by looking for 0xff (8 consecutive bits set)
        /// </summary>
        /// <param name="reader"></param>
        static void skipID3(FileStream stream)
        {
            while(true)
            {
                int c = stream.ReadByte();
                if (c == -1) break; // EOF
                if (c == 0xff)
                {
                    // we get start of mp3 frame, and need to unread the given byte
                    stream.Seek(-1, SeekOrigin.Current);
                    return;
                }

                ByteOffset += 1;
            }
        }

        static void oldMain(string[] args)
        {
            if(args.Length != 1)
            {             
                Console.WriteLine("Must be called with a single filename argument to mp3 file.");
                return;
            }

            string filename = args[0];
            FileStream stream = new FileStream(filename, FileMode.Open, FileAccess.Read);

            // skip past ID3 tag with meta-data about file
            skipID3(stream);

            long byteOffsetBeforeFirst = ByteOffset;
            double secondsPerFrame = 0;
            long bytesPerFrame = 0;
            long numFrames = 0;

            // real all frames to make sure there is nothing variable bit-rate
            while (true)
            {
                long byteOffsetBefore = ByteOffset;
                double timeOffsetBefore = TimeOffset;

                if (!readNextFrame(stream)) break;

                double secsGone = TimeOffset - timeOffsetBefore;
                long bytesSeen = ByteOffset - byteOffsetBefore;
                numFrames += 1;

                if(numFrames == 1)
                {
                    bytesPerFrame = bytesSeen;
                    secondsPerFrame = secsGone;
                } else
                {
                    if(bytesPerFrame != bytesSeen)
                    {
                        Console.Error.WriteLine("Frame #{0} contains {1} bytes but {2} was expected!", numFrames, bytesSeen, bytesPerFrame);
                        return;
                    }

                    if(secondsPerFrame != secsGone)
                    {
                        Console.Error.WriteLine("Frame #{0} contains {1} seconds but {2} was expected!", numFrames, secsGone, secondsPerFrame);
                        return;
                    }
                }
            }
            Console.WriteLine("{{'byteOffset': {0}, 'bytesPerFrame': {1}, 'secsPerFrame': {2}, 'frameCount': {3}}};",
                              byteOffsetBeforeFirst, bytesPerFrame, secondsPerFrame, numFrames);
        }
    }
}
