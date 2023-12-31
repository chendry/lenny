let audioCtx = null

export const AudioContextHook = {
  mounted() {
    this.el.addEventListener("click", () => {
      if (audioCtx == null) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext())()
        this._initializeAudioCtx()
        audioCtx.resume()
      } else {
        if (audioCtx.state == "running") {
          audioCtx.suspend()
        } else {
          audioCtx.resume()
        }
      }
    })

    if (audioCtx != null) {
      this._initializeAudioCtx()
    }

    this.handleEvent("media", buildMediaHandlerForTrack("inbound", 15))
    this.handleEvent("media", buildMediaHandlerForTrack("outbound", 1))
  },

  _initializeAudioCtx() {
    this.pushEvent("audio_ctx_state", {state: audioCtx.state})

    audioCtx.onstatechange = () => {
      this.pushEvent("audio_ctx_state", {state: audioCtx.state})
    }
  }
}

function buildMediaHandlerForTrack(track, callStartRefreshInterval) {
  let lastCallStartRefresh = null
  let callStart = null

  return ({media}) => {
    if (audioCtx == null) {
      return
    }

    if (audioCtx.state != "running" || media.track != track) {
      return
    }

    const timestamp = parseInt(media.timestamp, 10) / 1000
    const pcm = mulawDecode(base64decode(media.payload))
    const buffer = audioCtx.createBuffer(1, pcm.length, 8000)
    const channelData = buffer.getChannelData(0)

    for (let i = 0; i < pcm.length; i ++) {
      channelData[i] = pcm[i] / 65535
    }

    const source = audioCtx.createBufferSource()
    source.connect(audioCtx.destination)
    source.buffer = buffer

    const currentTime = audioCtx.currentTime

    if (callStart == null || lastCallStartRefresh < currentTime - callStartRefreshInterval) {
      callStart = currentTime - timestamp
      lastCallStartRefresh = currentTime
    }

    source.start(callStart + timestamp + 0.250)
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
