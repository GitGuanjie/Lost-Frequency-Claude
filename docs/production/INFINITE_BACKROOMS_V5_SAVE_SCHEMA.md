# Infinite Backrooms v5 — Versioned Save Schema

Applies to the developer continuity lab only.
The canonical story save is a different, older schema
(`autoload/SaveService.gd`, `SCHEMA := 100`) and is **not** touched by
anything in this document.

---

## 1. File layout

```
%APPDATA%/Godot/app_userdata/LostFrequency/continuity_lab/
    selected_seed.txt          the seed the lab opens with
    seed_index.json            the list of seeds the player has visited
    world.json                 seed 1337 (the default world)
    world_<seed>.json          every other seed
    world_<seed>.json.bak      the previous good copy of that file
```

One file per seed. Changing seeds never deletes another world's history.
The story save under `saves/` is a different directory and is never written
by the lab: the lab uses the developer scope of `SaveService`, and
`SaveService.save_story()` refuses to write while the session is not in story
mode.

---

## 2. World file format

```jsonc
{
  "schema": 2,                 // this file's own format version
  "world_id": "L000_CONTINUITY_1337",
  "seed": 1337,                // the world seed; the layout follows from it
  "generator_version": 5,      // the generator that wrote the file
  "versions": {                // per-chunk layout version counter
    "3:-2:0": 1,               // "<chunk_x>:<chunk_y>:<chunk_z>"
    "4:0:2": 2
  },
  "changes": {                 // everything the player actually changed
    "0:0:0": { "visited": true, "discovered": true },
    "1:0:0": { "marked": true },
    "1:0:1": { "relay_active": true },
    "3:0:3": { "network_online": true }
  }
}
```

### What is stored

* **Only the differences.** The geometry of the world is never serialised.
  It is a pure function of the seed and the coordinates, so storing it would
  only duplicate what the generator already knows.
* **`versions`** — the per-chunk counter behind the F4 "reshape this room"
  action. It changes the room *motif* only; it can never move a portal, a
  floor well, a bridge, a megastructure or a power relay.
* **`changes`** — the persistent gameplay flags of the lab:
  `visited`, `discovered`, `marked`, `relay_active`, `network_online`.

### What is never stored

* Chunk meshes, collision shapes, lights — all regenerated.
* The regional plan — it is recomputed from the seed and the coordinates.
* The canonical story checkpoint, inventory or journal.

---

## 3. Write path

`ChunkWorld3D.save_to_disk()`:

1. `mkdir -p` the target directory.
2. Serialise the payload.
3. Write to `<file>.tmp`, flush, close.
4. **Read the temp file back and verify** that it parses and that its
   `world_id` matches. A corrupt payload is discarded, not renamed into
   place.
5. If the primary file exists, rotate it to `<file>.bak`
   (the previous `.bak` is deleted first).
6. Rename the verified temp file over the primary.

A crash at any point leaves either the primary, the backup or the verified
temp recoverable.

`ChunkWorld3D._load_disk()` reads the primary, then `.bak`, and accepts the
first file whose `world_id` matches the world being opened. A file belonging
to another world is ignored, not merged.

The lab also flushes on `NOTIFICATION_WM_CLOSE_REQUEST` and
`NOTIFICATION_APPLICATION_FOCUS_OUT`, on a seed switch, and on the way back
to the menu. A periodic autosave runs every `AUTOSAVE_SECONDS` (12 s) while
something is dirty.

---

## 4. Versioning and migration

| Field | Meaning |
|---|---|
| `schema` | the format of this file. Bumped when the JSON shape changes. |
| `generator_version` | the generator that produced the layout. Bumped when the generator changes the shape of a world. |
| `seed` | the world seed. |

`RegionalPlan.GENERATOR_VERSION` and `ChunkWorld3D.GENERATOR_VERSION` are both
`5` in this build and must be raised together.

**Migration rule.** When the file's `generator_version` differs from the
running generator:

* the **seed is kept** — the same seed must always describe the same place;
* the **layout versions are dropped** — a version counter only means
  something inside the generator that wrote it, and keeping it would make
  F4 produce a different room than the one the player last saw;
* the **changes are kept** — `visited`, `discovered`, `marked` and the power
  states are gameplay facts, not layout, and the player must not lose them;
* the migration is recorded in the in-memory scope as
  `migrated_from_generator` / `migrated_to_generator`.

**Seed isolation.** A file whose `world_id` or `seed` does not match the
world being opened is rejected outright. Two worlds never share state, and a
world never inherits another world's exploration.

---

## 5. Schema history

| Schema | Generator | Change |
|---|---|---|
| 1 | 4 | initial lab file: seed, versions, changes |
| 2 | 5 | added `generator_version`; added the migration rule; the file is now rejected when the world id does not match |

---

## 6. Verification

* `tests/test_worldlab_v5_static.py` asserts that the streamer keeps the
  per-world file, the `.bak` rotation, the schema field and the absence of a
  compile-time `SaveService` dependency.
* `tests/ContinuityPhysicalWalkTest.gd` asserts that an unloaded and
  rebuilt chunk produces an identical structure, i.e. that the geometry is a
  function of the coordinates and not of the session history.
* `tests/ContinuityTopologyTest.gd` asserts that per-chunk changes survive a
  version bump and an unload/rebuild cycle.
