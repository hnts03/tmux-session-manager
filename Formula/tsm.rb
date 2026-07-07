# Homebrew formula for tsm
# To use before official tap:
#   brew install --formula ./Formula/tsm.rb
#
# Once a tap is published:
#   brew tap hnts03/tmux-session-manager
#   brew install tsm

class Tsm < Formula
  desc "Lightweight fzf-based tmux session manager"
  homepage "https://github.com/hnts03/tmux-session-manager"
  version "0.4.11"

  # Update sha256 after GitHub release
  url "https://github.com/hnts03/tmux-session-manager/archive/refs/tags/v#{version}.tar.gz"
  sha256 "f90f0f56e9cf29131e72f64d617f3957821b2bfd8086caee398b897ef4e10a12"

  license "MIT"

  depends_on "fzf"
  depends_on "tmux"
  depends_on "yq"

  def install
    bin.install "bin/tsm"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tsm version")
  end
end
