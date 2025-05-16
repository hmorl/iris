```
      ⌒
 ┬ ┬─┐ ┬ ┌─┐
 │ ├┬┘ │ └─┐
 ┴ ┴└─ ┴ └─┘
```

# Iris: a visualization technique for signals & stories

Iris is an art project & visualization system written in [Odin](https://odin-lang.org/) & [Raylib](https://www.raylib.com/), which runs on desktop systems that support openGL, including Raspberry Pi.

It contains:

- an audio engine which performs basic audio analysis (RMS, centroid, FFT)
- scenes which are passed the audio features for visualizing
- shaders n stuff
- keyboard-centric control
- (planned) automatic scene switching
- decent performance for low-powered systems (RPi)

# Scenes

Under construction :warning:

Scenes are inspired by artefacts from Greek mythology.

## AMBROSIA

Food of the gods.

## NECKLACE OF HARMONIA

Cursed jewellery.

## HARPE

Blades of sound.

# Key mappings

Iris has a layer-based key mapping system for ready-to-hand & expressive keyboard control.

There are 4 key map layers. In each layer, the alphanumeric keys are used as primary keys for certain actions.

## App shortcuts

Activated with the `Ctrl+Alt` modifier

- Toggle FPS: `/`
- Toggle cursor visibility: `c`
- Quit: `q`

## Global Scene Mode

Primarily for switching between scenes. This layer can be activated/latched on permanently with `[Alt/Option]+Enter` or `[Alt/Option]+Tab`, or temporarily by holding the `Alt/Option` key.

- `[a-z]` keys switch scenes (currently only a handful do something)
- `[1-9, 0]`for setting the audio input level (`1` is min, `0` is max, i.e. number-row-as-a-slider)

## Global FX Mode

For toggling effects. This layer can be latched permanently with `Shift+Enter` or `Shift+Tab`, or temporarily by holding the `Shift` key.

- Pixelate: `p`
- Warp: `w`
- Clear all: `backspace`

## Scene Mode

Under construction :warning:

For controlling individual scene parameters. This layer can be latched on permanently with `Ctrl+Enter` or `Ctrl+Tab`, or temporarily by holding the `Ctrl` key.

# Extending

Iris can be extended with the addition of scenes: simple structs which provide a draw procedure.

Scene draw procedures are passed the scene's current state, a set of params (which includes audio features) and a texture to draw to. Scenes are initialised in `init_scenes` in `scene.odin`.

`scene_utils.odin` contains utilities for visualization: a stateless LFO including smoothed random, interpolators, polar/cartesian convertors & colour utilities.

# Appearances

- [One Fantastic Bind](https://www.youtube.com/watch?v=d_HVayu6qM8) - hops & Icebeing (music video)

# References & inspirations

- [Coding Challenge 183: Paper Marbling Algorithm](https://www.youtube.com/watch?v=p7IGZTjC008) - Daniel Shiffman, The Coding Train
- [greekmythology.org](https://www.greekmythology.com/)
- [ICEBEING](https://icebeing.bandcamp.com/)
- [Don’t Forget the Laptop: Using Native Input Capabilities
  for Expressive Musical Control](https://www.nime.org/proceedings/2007/nime2007_164.pdf) - Rebecca Fiebrink, Ge Wang, Perry R. Cook
- [Hydra video synth](https://hydra.ojack.xyz)
- [EYESY:tm:](https://www.critterandguitari.com/eyesy)
- [Atmospheric Audio Plugin Design](https://www.youtube.com/watch?v=ARduQFatyk0) - Syl Morrison
