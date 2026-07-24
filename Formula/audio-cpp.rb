class AudioCpp < Formula
  desc "C++ audio inference engine powered by ggml"
  homepage "https://github.com/0xShug0/audio.cpp"
  url "https://github.com/0xShug0/audio.cpp/archive/refs/tags/release-0.4.tar.gz"
  sha256 "a12d8f5c7f9f6825c6cdbe510625b5605fed6543b6ce67f4a2f0a7ca662d4ffe"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "libomp" => :build
  depends_on "ninja" => :build

  def install
    private_lib = libexec/"lib"
    args = std_cmake_args + %W[
      -DAUDIOCPP_DEPLOYMENT_BUILD=ON
      -DENGINE_ENABLE_OPENMP=ON
      -DENGINE_ENABLE_NATIVE_CPU=ON
      -DENGINE_ENABLE_METAL=#{OS.mac? ? "ON" : "OFF"}
      -DENGINE_BUILD_EXAMPLES=OFF
      -DENGINE_BUILD_TESTS=OFF
      -DENGINE_BUILD_WARMBENCH=OFF
    ]
    args << "-DOpenMP_ROOT=#{formula_opt_prefix("libomp")}" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
                    *args
    system "cmake", "--build", "build",
                    "--target", "audiocpp_cli", "audiocpp_server", "audiocpp_gguf"

    bin.install "build/bin/audiocpp_cli"
    bin.install_symlink bin/"audiocpp_cli" => "audiocpp"
    bin.install "build/bin/audiocpp_server"
    bin.install "build/bin/audiocpp_gguf"

    if OS.mac?
      libomp = formula_opt_lib("libomp")/"libomp.dylib"
      private_lib.mkpath
      cp libomp.realpath, private_lib/libomp.basename
      private_libomp = private_lib/libomp.basename
      chmod 0644, private_libomp
      private_name = "@executable_path/../libexec/lib/#{private_libomp.basename}"
      MachO::Tools.change_dylib_id(private_libomp, private_name)
      MachO.codesign! private_libomp

      [bin/"audiocpp_cli", bin/"audiocpp_server", bin/"audiocpp_gguf"].each do |exe|
        chmod 0755, exe
        Utils.safe_popen_read("otool", "-L", exe).lines.grep(/libomp/).each do |line|
          old_name = line.strip.split.first
          MachO::Tools.change_install_name(exe, old_name, private_name)
        end
        MachO.codesign! exe
      end
    end
  end

  test do
    assert_match "audiocpp_cli --task", shell_output("#{bin}/audiocpp_cli --help")
    assert_match "audiocpp_server --config", shell_output("#{bin}/audiocpp_server --help")
    assert_match "Usage: audiocpp_gguf", shell_output("#{bin}/audiocpp_gguf --help")
  end
end
