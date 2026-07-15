class AudioCpp < Formula
  desc "C++ audio inference engine powered by ggml"
  homepage "https://github.com/0xShug0/audio.cpp"
  url "https://github.com/0xShug0/audio.cpp/archive/refs/tags/release-0.3-gguf-v2.tar.gz"
  version "0.3-gguf-v2"
  sha256 "266d9f51f9419a650f086c99172a780f5c6c498fdefaf1beb256aa1e8bc79509"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "libomp" => :build
  depends_on "ninja" => :build

  def install
    private_lib = libexec/"lib"
    args = std_cmake_args + %W[
      -DAUDIOCPP_DEPLOYMENT_BUILD=ON
      -DENGINE_ENABLE_OPENMP=ON
      -DENGINE_ENABLE_NATIVE_CPU=OFF
      -DENGINE_ENABLE_METAL=#{OS.mac? ? "ON" : "OFF"}
      -DENGINE_BUILD_EXAMPLES=OFF
      -DENGINE_BUILD_TESTS=OFF
      -DENGINE_BUILD_WARMBENCH=OFF
    ]
    args << "-DOpenMP_ROOT=#{Formula["libomp"].opt_prefix}" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
                    *args
    system "cmake", "--build", "build",
                    "--target", "audiocpp_cli", "audiocpp_server", "audiocpp_gguf"

    bin.install "build/bin/audiocpp_cli"
    bin.install_symlink bin/"audiocpp_cli" => "audiocpp"
    bin.install "build/bin/audiocpp_server"
    bin.install "build/bin/audiocpp_gguf"

    if OS.mac?
      libomp = Formula["libomp"].opt_lib/shared_library("libomp")
      private_lib.install libomp.realpath => libomp.basename
      private_libomp = private_lib/libomp.basename
      system "install_name_tool", "-id", "@executable_path/../libexec/lib/#{private_libomp.basename}",
             private_libomp

      [bin/"audiocpp_cli", bin/"audiocpp_server", bin/"audiocpp_gguf"].each do |exe|
        shell_output("otool -L #{exe}").lines.grep(/libomp/).each do |line|
          old_name = line.strip.split.first
          system "install_name_tool", "-change", old_name,
                 "@executable_path/../libexec/lib/#{private_libomp.basename}", exe
        end
      end
    end
  end

  test do
    assert_match "audiocpp_cli --task", shell_output("#{bin}/audiocpp_cli --help")
    assert_match "audiocpp_server --config", shell_output("#{bin}/audiocpp_server --help")
    assert_match "Usage: audiocpp_gguf", shell_output("#{bin}/audiocpp_gguf --help")
  end
end
