export const audioCtx = new (window.AudioContext || window.webkitAudioContext())()

export const StartAudioContextHook = {
  mounted() {
    this.pushEvent("audio_ctx_state", {state: audioCtx.state})

    audioCtx.onstatechange = () => {
      this.pushEvent("audio_ctx_state", {state: audioCtx.state})
    }

    this.el.addEventListener("click", () => {
      audioCtx.resume()
    })
  }
}
