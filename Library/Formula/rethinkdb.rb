require "formula"

class Rethinkdb < Formula
  homepage "http://www.rethinkdb.com/"
  url "http://download.rethinkdb.com/dist/rethinkdb-1.15.2.tgz"
  sha1 "31c14c764355e555734c7f4479397bd3bd7e0e44"

  bottle do
    sha1 "2710231d7a0013779e2d61228aa0395e8261611f" => :yosemite
    sha1 "c8c7f4e2d05535953de0ba229ac3c12ac11de8b9" => :mavericks
    sha1 "bcbdc4b123365987dd5ce6f6cc0f628302d95e3c" => :mountain_lion
  end

  depends_on :macos => :lion
  # Embeds an older V8, whose gyp still requires the full Xcode
  # Reported upstream: https://github.com/rethinkdb/rethinkdb/issues/2581
  depends_on :xcode => :build
  depends_on "boost" => :build
  depends_on "openssl"

  fails_with :gcc do
    build 5666 # GCC 4.2.1
    cause "RethinkDB uses C++0x"
  end

  # boost 1.56 compatibility
  # https://github.com/rethinkdb/rethinkdb/issues/3044#issuecomment-55478774
  patch :DATA

  def install
    args = ["--prefix=#{prefix}"]

    # brew's v8 is too recent. rethinkdb uses an older v8 API
    args += ["--fetch", "v8"]

    # rethinkdb requires that protobuf be linked against libc++
    # but brew's protobuf is sometimes linked against libstdc++
    args += ["--fetch", "protobuf"]

    # support gcc with boost 1.56
    # https://github.com/rethinkdb/rethinkdb/issues/3044#issuecomment-55471981
    args << "CXXFLAGS=-DBOOST_VARIANT_DO_NOT_USE_VARIADIC_TEMPLATES"

    system "./configure", *args
    system "make"
    system "make", "install-osx"

    mkdir_p "#{var}/log/rethinkdb"
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
          <string>#{opt_bin}/rethinkdb</string>
          <string>-d</string>
          <string>#{var}/rethinkdb</string>
      </array>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/rethinkdb/rethinkdb.log</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/rethinkdb/rethinkdb.log</string>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <true/>
    </dict>
    </plist>
    EOS
  end
end
