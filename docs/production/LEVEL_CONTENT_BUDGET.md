# Level content budget

| Item | Budget | Why |
|---|---|---|
| Level script | ≤ 30 KB | readable grammar; repository payload cap |
| Committed stills | ≤ 2 per level, 640×360 JPEG q0.70 (≈ 20–30 KB each) | repository cap is 5 MiB total |
| Loaded collision shapes | ≲ 6000 near the player | Jolt broadphase and load time |
| Real dynamic lights | pool of 8–14, ≤ 2 shadowed | Forward+ clustered cost |
| Draw calls | one mesh per material per kit (or chunk) | batching |
| Build time on load | ≤ 1.5 s headless | loading-screen budget |
| Binary assets | none | provenance and size; shaders and synthesis only |

## Repository storage
This game lives in a subfolder of a research repository whose policy (`scripts/check_repo.py`)
caps any file at 512 KiB and the total tracked payload at 5 MiB, and forbids `.log`, `.zip` and
similar. Full-resolution evidence and logs are therefore kept outside Git. Moving the game to its own
repository would remove this constraint: `git subtree split --prefix=lost_frequency` preserves its
history.

## Performance targets (not yet measured)
Target: 60 FPS at 1080p on an RTX 3060-class GPU, Ryzen 5 5600-class CPU, 16 GB RAM, High preset.
**UNVERIFIED.** All evidence so far was rendered with Mesa lavapipe (software Vulkan). Frame times
there (≈ 130 ms at 1280×720) show CPU rasterisation cost only and say nothing about GPU
performance.
