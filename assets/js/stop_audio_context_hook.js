import {audioCtx} from "./start_audio_context_hook"

export const StopAudioContextHook = {
  mounted() {
    this.el.addEventListener("click", () => {
      audioCtx.suspend()
    })
  }
}
