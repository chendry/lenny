import {audioCtx} from "./start_audio_context_hook"

export const PlayAudioHook = {
  mounted() {
    const callStart = {
      "inbound": null,
      "outbound": null
    }

    const lastCallStartRefresh = {
      "inbound": null,
      "outbound": null
    }

    const refreshIntervals = {
      "inbound": 1,
      "outbound": 15
    }

    const refreshCallStart = (track, timestamp) => {
      callStart[track] = audioCtx.currentTime - timestamp
      lastCallStartRefresh[track] = audioCtx.currentTime
    }

    this.handleEvent("media", ({media}) => {
      if (audioCtx.state != "running") {
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

      if (callStart[media.track] == null || lastCallStartRefresh[media.track] < audioCtx.currentTime - refreshIntervals[media.track]) {
        refreshCallStart(media.track, timestamp)
      }

      source.start(callStart[media.track] + timestamp + 0.100)
    })
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
