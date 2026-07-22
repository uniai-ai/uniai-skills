# `video_clip` node

A **timeline/compositing** node: it merges the upstream `video` clips (in connection order) into one
video using **ffmpeg**, optionally overlaying an upstream `audio` node's track. It does **not** call any
AI model — it's local composition — so it costs **no credits** (the run estimate counts it as 0). The
merged result is uploaded and stored as `data.videoUrl`.

## Fields (`node create --type video_clip`)

No generation flags — a `video_clip` has no prompt/model. Its inputs come entirely from edges:

- connect one or more `video` (or `video_clip`) nodes → the clip merges them in order; **at least one
  upstream video is required**.
- optionally connect one `audio` node → its audio is overlaid on the merged video.

Output after running: `data.videoUrl` (the composited clip).

## Typical use

```bash
# render several generated clips into one (A then B), with narration
( uniai canvas node create --type video --prompt "shot A" --model <m> \
  && uniai canvas node create --type video --prompt "shot B" --model <m> ) \
  | uniai canvas node create --type video_clip
# (then connect an audio node into the video_clip too, if you want a soundtrack)
```

Key points:

- Order matters: clips are concatenated in the order their edges were created (use explicit
  `uniai canvas connect <video> <clipNode>` calls to control sequence).
- Free of AI cost, but it depends on the upstream videos already being generated (run the whole graph
  so the videos complete first, then the clip composites them).
- Server-side it relies on `ffmpeg`; that's present in the platform's deployed environment.
