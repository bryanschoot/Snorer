package com.bryanschoot.snorer

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream

class AudioPcmDecoder(private val context: Context) {
    fun decode(inputPath: String): Map<String, Any> {
        val inputFile = File(inputPath)
        require(inputFile.isFile) { "Audio file was not found." }

        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var decoderStarted = false
        var outputFile: File? = null

        try {
            extractor.setDataSource(inputFile.absolutePath)
            var audioTrack = -1
            var audioFormat: MediaFormat? = null
            for (trackIndex in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(trackIndex)
                val mime = format.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    audioTrack = trackIndex
                    audioFormat = format
                    break
                }
            }
            require(audioTrack >= 0 && audioFormat != null) {
                "The audio file does not contain an audio track."
            }

            extractor.selectTrack(audioTrack)
            val mime = audioFormat.getString(MediaFormat.KEY_MIME)
                ?: error("The audio track has no MIME type.")
            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(audioFormat, null, null, 0)
            decoder.start()
            decoderStarted = true

            var sampleRate = audioFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = audioFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            outputFile = File.createTempFile(
                "snorer-decoded-",
                ".pcm",
                context.cacheDir,
            )
            FileOutputStream(outputFile).use { output ->
                val bufferInfo = MediaCodec.BufferInfo()
                var inputDone = false
                var outputDone = false
                val timeoutUs = 10_000L

                while (!outputDone) {
                    if (!inputDone) {
                        val inputIndex = decoder.dequeueInputBuffer(timeoutUs)
                        if (inputIndex >= 0) {
                            val inputBuffer = decoder.getInputBuffer(inputIndex)
                                ?: error("The decoder input buffer was unavailable.")
                            inputBuffer.clear()
                            val sampleSize = extractor.readSampleData(inputBuffer, 0)
                            if (sampleSize < 0) {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputDone = true
                            } else {
                                val sampleTime = extractor.sampleTime.coerceAtLeast(0)
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    sampleSize,
                                    sampleTime,
                                    0,
                                )
                                extractor.advance()
                            }
                        }
                    }

                    when (val outputIndex = decoder.dequeueOutputBuffer(
                        bufferInfo,
                        timeoutUs,
                    )) {
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val format = decoder.outputFormat
                            if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                                sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            }
                            if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                                channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            }
                            if (
                                android.os.Build.VERSION.SDK_INT >=
                                    android.os.Build.VERSION_CODES.N &&
                                format.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                                format.getInteger(MediaFormat.KEY_PCM_ENCODING) !=
                                    AudioFormat.ENCODING_PCM_16BIT
                            ) {
                                error("The decoder did not produce 16-bit PCM audio.")
                            }
                        }

                        MediaCodec.INFO_TRY_AGAIN_LATER -> Unit

                        else -> if (outputIndex >= 0) {
                            val isCodecConfig =
                                bufferInfo.flags and
                                    MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                            if (!isCodecConfig && bufferInfo.size > 0) {
                                val outputBuffer = decoder.getOutputBuffer(outputIndex)
                                    ?: error("The decoder output buffer was unavailable.")
                                val end = bufferInfo.offset + bufferInfo.size
                                require(end <= outputBuffer.capacity()) {
                                    "The decoder returned an invalid output buffer."
                                }
                                outputBuffer.position(bufferInfo.offset)
                                outputBuffer.limit(end)
                                val bytes = ByteArray(bufferInfo.size)
                                outputBuffer.get(bytes)
                                output.write(bytes)
                            }
                            if (
                                bufferInfo.flags and
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            ) {
                                outputDone = true
                            }
                            decoder.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
            }

            val decodedFile = outputFile
                ?: error("The decoder did not create a PCM file.")
            require(decodedFile.length() > 0) {
                "The decoder produced an empty PCM file."
            }
            require(sampleRate > 0 && channels > 0) {
                "The decoder returned invalid PCM metadata."
            }
            return mapOf(
                "path" to decodedFile.absolutePath,
                "sampleRate" to sampleRate,
                "channels" to channels,
            )
        } catch (error: Exception) {
            outputFile?.delete()
            throw error
        } finally {
            if (decoderStarted) {
                try {
                    decoder?.stop()
                } catch (_: Exception) {}
            }
            decoder?.release()
            extractor.release()
        }
    }
}
