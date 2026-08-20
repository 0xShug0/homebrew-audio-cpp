class AudioCpp < Formula
  desc "C++ audio inference engine powered by ggml"
  homepage "https://github.com/0xShug0/audio.cpp"
  url "https://github.com/0xShug0/audio.cpp/archive/refs/tags/release-0.6.1-brew-test.tar.gz"
  sha256 "da58a9910987cfb66a9af48aaa5234f06d2b16997b4efa81785a1547e377002a"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "libomp" => :build
  depends_on "ninja" => :build

  resource "boringssl" do
    url "https://github.com/google/boringssl/archive/refs/tags/0.20260813.0.tar.gz"
    sha256 "37e23cb9a5fa54f01b07cadd653cebc1d1b235945439a6c334fea58ea47b5b0a"
  end

  def install
    private_bin = libexec/"bin"
    private_lib = libexec/"lib"
    resource("boringssl").stage buildpath/"boringssl"
    inreplace "external/cpp-httplib/CMakeLists.txt",
              "FetchContent_MakeAvailable(audiocpp_boringssl)",
              <<~CMAKE
                if (AUDIOCPP_BORINGSSL_SOURCE_DIR)
                    set(audiocpp_boringssl_SOURCE_DIR "${AUDIOCPP_BORINGSSL_SOURCE_DIR}")
                    add_subdirectory("${AUDIOCPP_BORINGSSL_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/audiocpp_boringssl-build")
                else()
                    FetchContent_MakeAvailable(audiocpp_boringssl)
                endif()
              CMAKE
    inreplace "app/server/runtime.cpp",
              'default_models_root_ = (binary_directory / "models").lexically_normal();',
              "default_models_root_ = std::filesystem::path(\"#{var}/audio-cpp/models\").lexically_normal();"
    args = std_cmake_args + %W[
      -DAUDIOCPP_DEPLOYMENT_BUILD=ON
      -DAUDIOCPP_BUILD_NATIVE_MODEL_MANAGER=ON
      -DAUDIOCPP_BORINGSSL_SOURCE_DIR=#{buildpath/"boringssl"}
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
                    "--target", "audiocpp_cli", "audiocpp_server", "audiocpp_gguf",
                    "audiocpp_model_manager"

    private_bin.install "build/bin/audiocpp_cli"
    private_bin.install "build/bin/audiocpp_server"
    private_bin.install "build/bin/audiocpp_gguf"
    private_bin.install "build/bin/audiocpp_model_manager"
    libexec.install "model_specs"
    (libexec/"tools").install "tools/model_manager_v2.py", "tools/model_manager_deprecated.py"
    (libexec/"assets").install "assets/model_manager" if (buildpath/"assets/model_manager").exist?

    bin.write_exec_script private_bin/"audiocpp_cli"
    bin.install_symlink "audiocpp_cli" => "audiocpp"
    bin.write_exec_script private_bin/"audiocpp_server"
    bin.write_exec_script private_bin/"audiocpp_gguf"
    bin.write_exec_script private_bin/"audiocpp_model_manager"

    if OS.mac?
      libomp = formula_opt_lib("libomp")/"libomp.dylib"
      private_lib.mkpath
      cp libomp.realpath, private_lib/libomp.basename
      private_libomp = private_lib/libomp.basename
      chmod 0644, private_libomp
      private_name = "@executable_path/../lib/#{private_libomp.basename}"
      MachO::Tools.change_dylib_id(private_libomp, private_name)
      MachO.codesign! private_libomp

      [
        private_bin/"audiocpp_cli",
        private_bin/"audiocpp_server",
        private_bin/"audiocpp_gguf",
        private_bin/"audiocpp_model_manager",
      ].each do |exe|
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
    assert_match "audiocpp_server [--config", shell_output("#{bin}/audiocpp_server --help")
    assert_match "Usage: audiocpp_gguf", shell_output("#{bin}/audiocpp_gguf --help")
    assert_match "audio.cpp native model package manager", shell_output("#{bin}/audiocpp_model_manager --help")
  end
end
