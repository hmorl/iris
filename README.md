```
      ⌒
 ┬ ┬──┐ ┬ ┌──┐
 │ │  │ │ │  │
 │ ├─┬┘ │ └──┐
 │ │ │  │ │  │
 ┴ ┴ └─ ┴ └──┘
```

# a visualization technique for signals & stories

<!-- prettier-ignore-start -->
| ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/1.png?raw=true) | ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/2.png?raw=true) | ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/6.png?raw=true) |
|-|-|-|
| ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/4.png?raw=true) | ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/5.png?raw=true) | ![Iris screenshot](https://github.com/hmorl/iris-repo-assets/blob/main/img/10.png?raw=true) |
<!-- prettier-ignore-end -->

Iris is an art project & visualization system written in [Odin](https://odin-lang.org/) & [Raylib](https://www.raylib.com/), which runs on desktop systems that support openGL, including Raspberry Pi.

It contains...

- an audio engine which performs basic audio analysis (RMS, centroid, FFT)
- scenes which are passed the audio features for visualizing
- shaders n stuff
- keyboard-centric control
- (hopefully) decent performance for low-powered systems (RPi)
- (planned) automatic scene switching

# Scenes

Scenes are inspired by artefacts from Greek mythology.

## AMBROSIA

Food of the gods.

![Iris gif - AMBROSIA scene](https://github.com/hmorl/iris-repo-assets/blob/main/gif/ambrosia.gif?raw=true)

## NECKLACE OF HARMONIA

Cursed jewellery.

![Iris gif - HARMONIA scene](https://github.com/hmorl/iris-repo-assets/blob/main/gif/harmonia.gif?raw=true)

## HARPE

Blades of sound.

Under construction :warning:

# Key mappings

Iris has a layer-based key mapping system for ready-to-hand & expressive keyboard control.

There are 4 key map layers. In each layer, the alphanumeric keys are used as primary keys for certain actions.

## App shortcuts

Activated by holding the `Ctrl+Alt` modifier

- Toggle FPS: `/`
- Toggle cursor visibility: `c`
- Quit: `q`

## Global Scene Mode

Primarily for switching between scenes.

Permanent latch: `[Alt/Option]+Enter` or `[Alt/Option]+Tab`  
Temporary latch: `Alt/Option`

- `[a-z]` keys switch scenes (currently only a handful do something)
- `[1-9, 0]`for setting the audio input level (`1` is min, `0` is max, i.e. number-row-as-a-slider)

## Global FX Mode

For toggling effects.

Permanent latch: `Shift+Enter` or `Shift+Tab`  
Temporary latch: `Shift`

Actions:

- Toggle pixelate: `p`
- Toggle warp: `w`
- ...more coming
- Clear all: `backspace`

## Scene Mode

Under construction :warning:

For controlling individual scene parameters.

Permanent latch: `Ctrl+Enter` or `Ctrl+Tab`  
Temporary latch: `Ctrl`

# How to build

Under construction :warning:

# Extending

Iris can be extended with the addition of scenes: simple structs which provide a draw procedure. Scene draw procedures are passed the scene's current state, a set of params (which includes audio features) and a texture to draw to. Scenes are initialised in `init_scenes` in [`scene.odin`](https://github.com/hmorl/iris/blob/main/src/scene.odin).

[`scene_utils.odin`](https://github.com/hmorl/iris/blob/main/src/scene_utils.odin) contains utilities for visualization: a stateless LFO including smoothed random, interpolators, polar/cartesian convertors & colour utilities.

# Appearances

- [One Fantastic Bind](https://www.youtube.com/watch?v=d_HVayu6qM8) (music video) - [hops](https://hopsbrighton.bandcamp.com) & [Icebeing](https://icebeing.bandcamp.com/) (2025)

# References & inspirations

- [Coding Challenge 183: Paper Marbling Algorithm](https://www.youtube.com/watch?v=p7IGZTjC008) - Daniel Shiffman / The Coding Train
- [greekmythology.org](https://www.greekmythology.com/)
- [ICEBEING](https://icebeing.bandcamp.com/)
- [Don’t Forget the Laptop: Using Native Input Capabilities
  for Expressive Musical Control](https://www.nime.org/proceedings/2007/nime2007_164.pdf) - Rebecca Fiebrink, Ge Wang, Perry R. Cook
- [Hydra video synth](https://hydra.ojack.xyz) - Olivia Jack
- [EYESY](https://www.critterandguitari.com/eyesy):tm: - Critter & Guitari
- [Atmospheric Plugin Design](https://www.youtube.com/watch?v=ARduQFatyk0) (ADC 2024) - Syl Morrison

---

N.B. Iris is in its very early stages and will remain unstable/experimental for some time. I'm not actively seeking contributions but will happily answer any questions about the project.
