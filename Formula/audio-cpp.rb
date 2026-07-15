class AudioCpp < Formula
  desc "C++ audio inference engine powered by ggml"
  homepage "https://github.com/0xShug0/audio.cpp"
  url "https://github.com/0xShug0/audio.cpp/archive/refs/tags/release-0.3-gguf-v2.tar.gz"
  version "0.3-gguf-v2"
  sha256 "266d9f51f9419a650f086c99172a780f5c6c498fdefaf1beb256aa1e8bc79509"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
                    *std_cmake_args,
                    "-DAUDIOCPP_DEPLOYMENT_BUILD=ON",
                    "-DENGINE_ENABLE_OPENMP=OFF",
                    "-DENGINE_ENABLE_NATIVE_CPU=OFF",
                    "-DENGINE_ENABLE_METAL=#{OS.mac? ? "ON" : "OFF"}",
                    "-DENGINE_BUILD_EXAMPLES=OFF",
                    "-DENGINE_BUILD_TESTS=OFF",
                    "-DENGINE_BUILD_WARMBENCH=OFF"
    system "cmake", "--build", "build",
                    "--target", "audiocpp_cli", "audiocpp_server", "audiocpp_gguf"

    bin.install "build/bin/audiocpp_cli"
    bin.install_symlink bin/"audiocpp_cli" => "audiocpp"
    bin.install "build/bin/audiocpp_server"
    bin.install "build/bin/audiocpp_gguf"
  end

  test do
    assert_match "audiocpp_cli --task", shell_output("#{bin}/audiocpp_cli --help")
    assert_match "audiocpp_server --config", shell_output("#{bin}/audiocpp_server --help")
    assert_match "Usage: audiocpp_gguf", shell_output("#{bin}/audiocpp_gguf --help")
  end
end
