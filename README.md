# Homebrew tap for audio.cpp

Formula for `audio.cpp` tag `release-0.6.1-brew-test`, with the native model manager enabled.

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
- `audiocpp_model_manager`
