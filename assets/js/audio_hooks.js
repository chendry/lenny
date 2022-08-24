const audioCtx = new (window.AudioContext || window.webkitAudioContext())()
let clockOffset = null

export const StartAudioHook = {
  mounted() {
    this.el.addEventListener("click", () => {
      audioCtx.resume()
    })
  }
}

export const PlayAudioChunkHook = {
  mounted() {
    const pcm = mulawDecode(base64decode(this.el.dataset.payload))
    const timestamp = parseInt(this.el.dataset.timestamp, 10) / 1000
    const buffer = audioCtx.createBuffer(1, pcm.length, 8000)
    const channelData = buffer.getChannelData(0)

    for (let i = 0; i < pcm.length; i ++) {
      channelData[i] = pcm[i] / 65535
    }

    const source = audioCtx.createBufferSource()

    source.connect(audioCtx.destination)
    source.buffer = buffer

    if (clockOffset == null) {
      /* this is the first chunk.  timestamp is the offset in seconds
       * into the call from which this audio came from.  Set
       * clockOffset to the current time, minus the timestamp, and
       * plus 50 milliseconds.  The 50 milliseconds gives us a little
       * bit of a buffer so we can smooth the audio.  Doing this will
       * cause the call to source.start below to play the first audio
       * chunk exactly 50ms from now */
      clockOffset = (audioCtx.currentTime - timestamp) + 0.05;
    }

    if (clockOffset + timestamp < audioCtx.currentTime) {
      /* this audio chunk arrived late; maybe we're getting data too
       * slow.  We're supposed to start it at a some point in the past
       * which isn't feasible.  Instead, change our clockOffset so
       * that the chunk is played 50ms from now. */
      clockOffset = (audioCtx.currentTime - timestamp) + 0.05;
    }

    if (clockOffset + timestamp > audioCtx.currentTime + 0.10) {
      /* now we're receiving audio chunks which were obviously
       * recorded in the past, but we're scheduling playback for over
       * 100ms into the future.  This is avoidable lag, so change
       * clockOffset so that the chunk is played 50ms from now. */
      clockOffset = (audioCtx.currentTime - timestamp) + 0.05;
    }

    source.start(clockOffset + timestamp)
  }
}

const decodeTable = [0, 132, 396, 924, 1980, 4092, 8316, 16764]

function mulawDecodeSample(mulawSample) {
  mulawSample = ~mulawSample

  const sign = (mulawSample & 0x80)
  const exponent = (mulawSample >> 4) & 0x07
  const mantissa = mulawSample & 0x0F

  let sample = decodeTable[exponent] + (mantissa << (exponent+3))

  if (sign != 0)
    sample = -sample

  return sample
}

function mulawDecode(samples) {
  let pcmSamples = new Int16Array(samples.length)

  for (let i = 0; i < samples.length; i++) {
    pcmSamples[i] = mulawDecodeSample(samples[i])
  }

  return pcmSamples
}

function base64decode(str) {
  const binary = atob(str)
  const bytes = new Uint8Array(binary.length)

  for (let i = 0; i < binary.length; i ++)
    bytes[i] = binary.charCodeAt(i)

  return bytes
}
