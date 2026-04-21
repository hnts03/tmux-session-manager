# Homebrew formula for tsm
# To use before official tap:
#   brew install --formula ./Formula/tsm.rb
#
# Once a tap is published:
#   brew tap hnts03/tsm
#   brew install tsm

class Tsm < Formula
  desc "Lightweight fzf-based tmux session manager"
  homepage "https://github.com/hnts03/tmux-session-manager"
  version "0.1.0"

  # Update url and sha256 after first GitHub release
  url "https://github.com/hnts03/tmux-session-manager/archive/refs/tags/v#{version}.tar.gz"
  sha256 "" # fill after tagging

  license "MIT"

  depends_on "fzf"
  depends_on "tmux"

  def install
    bin.install "bin/tsm"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tsm version")
  end
end
