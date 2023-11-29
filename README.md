# Swadgics

Partial reimplementation of [badge](https://github.com/HazAT/badge) in Swift using Core Graphics (Swadgics = Sw(ift) + (b)adg(e) + (Core Graph)ics).

Its main advantage is that it does not require ImageMagick, GraphicsMagick, or RSVG, and that at runtime it does not use the network. As it uses Core Graphics it needs to be run on macOS, but for iOS applications that should not be much of a limitation.

Instead of sending pull requests to add new features, do not hesitate to fork it and adapt it to your own needs.

This project under the MIT license. The files under `Sources/Resources/` have been copied as-is from [badge](https://github.com/HazAT/badge) but were already under MIT license.

## Differences

It handles many of the flags of [badge](https://github.com/HazAT/badge) but the generated image will not be exactly the same.

Also, Swadgics will not automatically search for icons ([badge](https://github.com/HazAT/badge) looks at `./**/*.appiconset/*.{png,PNG}`), and does not take a `--glob` option. You have to give it the path to the images to modify. You can use your shell's glob features of course.

```console
$ swadgics badge --shield "Version-0.0.3-blue" --dark --shield_geometry "+0+25%" --shield_scale 0.75 path/to/my/icon.png
```

WARNING: As in [badge](https://github.com/HazAT/badge), the files are modified in place so make sure to make a copy before applying Swadgics on them. However, for testing purpose, when only once input file is specified, you can use `--output-file` to specify the file path to output to.
