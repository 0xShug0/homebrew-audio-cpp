# Homebrew tap for audio.cpp

Formula for `audio.cpp` tag `release-0.4`.

## Local install

```sh
brew install --build-from-source --formula Formula/audio-cpp.rb
```

## Tap install after publishing

```sh
brew tap 0xShug0/audio-cpp
brew trust 0xShug0/audio-cpp
brew install audio-cpp
```

## Included binaries

- `audiocpp_cli`
- `audiocpp` symlink to `audiocpp_cli`
- `audiocpp_server`
- `audiocpp_gguf`
