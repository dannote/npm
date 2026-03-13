defmodule NPM.IntegrityTest do
  use ExUnit.Case, async: true

  describe "Integrity.verify" do
    test "verifies matching sha512" do
      data = "hello world"
      integrity = NPM.Integrity.compute_sha512(data)
      assert :ok = NPM.Integrity.verify(data, integrity)
    end

    test "rejects mismatched data" do
      integrity = NPM.Integrity.compute_sha512("hello")
      assert {:error, :integrity_mismatch} = NPM.Integrity.verify("world", integrity)
    end

    test "accepts empty integrity" do
      assert :ok = NPM.Integrity.verify("any data", "")
    end

    test "accepts nil integrity" do
      assert :ok = NPM.Integrity.verify("any data", nil)
    end

    test "verifies sha256" do
      data = "test data"
      integrity = NPM.Integrity.compute_sha256(data)
      assert :ok = NPM.Integrity.verify(data, integrity)
    end
  end

  describe "Integrity.parse" do
    test "parses sha512" do
      assert {:ok, {"sha512", "abc123"}} = NPM.Integrity.parse("sha512-abc123")
    end

    test "parses sha256" do
      assert {:ok, {"sha256", "xyz"}} = NPM.Integrity.parse("sha256-xyz")
    end

    test "rejects unknown algo" do
      assert :error = NPM.Integrity.parse("md5-abc")
    end

    test "rejects nil" do
      assert :error = NPM.Integrity.parse(nil)
    end

    test "rejects malformed" do
      assert :error = NPM.Integrity.parse("nohyphen")
    end
  end

  describe "Integrity.algorithm" do
    test "extracts algorithm" do
      assert "sha512" = NPM.Integrity.algorithm("sha512-abc123")
    end

    test "returns nil for invalid" do
      assert nil == NPM.Integrity.algorithm("bad-string")
    end
  end

  describe "Integrity.compute_sha256" do
    test "produces sha256- prefix" do
      result = NPM.Integrity.compute_sha256("test")
      assert String.starts_with?(result, "sha256-")
    end
  end

  describe "Integrity.compute_sha512" do
    test "produces sha512- prefix" do
      result = NPM.Integrity.compute_sha512("test")
      assert String.starts_with?(result, "sha512-")
    end

    test "same data produces same hash" do
      a = NPM.Integrity.compute_sha512("data")
      b = NPM.Integrity.compute_sha512("data")
      assert a == b
    end

    test "different data produces different hash" do
      a = NPM.Integrity.compute_sha512("hello")
      b = NPM.Integrity.compute_sha512("world")
      assert a != b
    end
  end

  describe "Integrity: parse various formats" do
    test "parses sha512" do
      {:ok, {"sha512", _}} = NPM.Integrity.parse("sha512-abc123")
    end

    test "parses sha256" do
      {:ok, {"sha256", _}} = NPM.Integrity.parse("sha256-abc123")
    end

    test "parse returns error for invalid format" do
      result = NPM.Integrity.parse("invalid")
      assert result == :error or match?({:error, _}, result)
    end
  end

  describe "Integrity: compute sha256 consistency" do
    test "sha256 of same data is deterministic" do
      data = "test-data-for-hash"
      h1 = NPM.Integrity.compute_sha256(data)
      h2 = NPM.Integrity.compute_sha256(data)
      assert h1 == h2
    end
  end

  describe "Integrity: algorithm extraction" do
    test "extracts sha512 algorithm" do
      assert "sha512" = NPM.Integrity.algorithm("sha512-abc")
    end

    test "returns nil for unsupported algorithm" do
      assert nil == NPM.Integrity.algorithm("md5-abc")
    end
  end

  describe "Integrity: compute consistency" do
    test "same input produces same hash" do
      data = "deterministic"
      h1 = NPM.Integrity.compute_sha512(data)
      h2 = NPM.Integrity.compute_sha512(data)
      assert h1 == h2
    end

    test "different input produces different hash" do
      h1 = NPM.Integrity.compute_sha512("aaa")
      h2 = NPM.Integrity.compute_sha512("bbb")
      assert h1 != h2
    end
  end

  describe "Integrity: round-trip verification" do
    test "compute then verify succeeds for sha512" do
      data = :crypto.strong_rand_bytes(256)
      sri = NPM.Integrity.compute_sha512(data)
      assert :ok = NPM.Integrity.verify(data, sri)
    end

    test "compute then verify succeeds for sha256" do
      data = :crypto.strong_rand_bytes(256)
      sri = NPM.Integrity.compute_sha256(data)
      assert :ok = NPM.Integrity.verify(data, sri)
    end
  end

  describe "Integrity: SRI hash operations" do
    test "compute_sha512 produces valid SRI string" do
      result = NPM.Integrity.compute_sha512("hello world")
      assert String.starts_with?(result, "sha512-")
    end

    test "compute_sha256 produces valid SRI string" do
      result = NPM.Integrity.compute_sha256("hello world")
      assert String.starts_with?(result, "sha256-")
    end

    test "parse extracts algorithm and hash" do
      sri = "sha512-" <> Base.encode64("testhash")
      {:ok, {algo, hash}} = NPM.Integrity.parse(sri)
      assert algo == "sha512"
      assert is_binary(hash)
    end

    test "verify succeeds for matching data" do
      data = "test data"
      sri = NPM.Integrity.compute_sha512(data)
      assert :ok = NPM.Integrity.verify(data, sri)
    end

    test "verify fails for mismatched data" do
      sri = NPM.Integrity.compute_sha512("original")
      assert {:error, :integrity_mismatch} = NPM.Integrity.verify("tampered", sri)
    end

    test "algorithm extracts algo from SRI string" do
      assert "sha512" = NPM.Integrity.algorithm("sha512-abc")
      assert "sha256" = NPM.Integrity.algorithm("sha256-abc")
    end
  end

  describe "Integrity: compute_sha512 consistency" do
    test "sha512 of same data is deterministic" do
      data = "hash-test-data"
      h1 = NPM.Integrity.compute_sha512(data)
      h2 = NPM.Integrity.compute_sha512(data)
      assert h1 == h2
      assert String.starts_with?(h1, "sha512-")
    end
  end
end
