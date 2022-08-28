export let audioCtx = null

export const StartAudioContextHook = {
  mounted() {
    this.el.addEventListener("click", () => {
      if (audioCtx == null) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext())()
      }

      audioCtx.onstatechange = () => {
        this.pushEvent("audio_ctx_state", {state: audioCtx.state})
      }

      audioCtx.resume()

      this.pushEvent("audio_ctx_state", {state: audioCtx.state})
    })
  }
}
