#!/usr/bin/env python3

from pathlib import Path
import json
import subprocess
import tempfile


SCRIPT = Path("scripts/safe_executor_v1.py").resolve()


def run(cmd, cwd):
    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        capture_output=True,
        check=False,
    )


def init_repo(tmp):
    run(["git", "init"], tmp)
    run(["git", "config", "user.email", "test@example.com"], tmp)
    run(["git", "config", "user.name", "Test User"], tmp)

    (tmp / "scripts").mkdir()
    (tmp / "scripts" / "safe_executor_v1.py").write_text(
        SCRIPT.read_text(encoding="utf-8"),
        encoding="utf-8",
    )

    (tmp / "README.md").write_text("# test\n", encoding="utf-8")
    run(["git", "add", "README.md", "scripts/safe_executor_v1.py"], tmp)
    run(["git", "commit", "-m", "test: init repo"], tmp)


def write_request(raw, payload):
    path = Path(raw).parent / "request.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path

def base_payload():
    return {
        "action": "create_doc_commit",
        "branch": "docs/test-doc",
        "file_path": "docs/test/TEST_DOC.md",
        "content": "# Test Doc\n\nContenido seguro.\n",
        "commit_message": "docs(test): add test doc",
    }


def test_success_creates_local_commit():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        request = write_request(tmp, base_payload())
        result = run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)

        assert data["status"] == "FEATURE_READY_FOR_GITHUB"
        assert data["mode"] == "LOCAL_ONLY"
        assert data["file"] == "docs/test/TEST_DOC.md"
        assert data["validations"]["working_tree_clean_after_commit"] is True
        assert "push" in data["not_included"]
        assert (tmp / "docs/test/TEST_DOC.md").exists()


def test_blocks_non_docs_path():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = base_payload()
        payload["file_path"] = "scripts/bad.md"

        request = write_request(tmp, payload)
        result = run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)

        assert result.returncode != 0
        assert "file_path must start with docs/" in result.stdout


def test_blocks_non_markdown_file():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = base_payload()
        payload["file_path"] = "docs/test/bad.txt"

        request = write_request(tmp, payload)
        result = run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)

        assert result.returncode != 0
        assert "file_path must end with .md" in result.stdout


def test_blocks_secret_like_content():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = base_payload()
        payload["content"] = "client_secret = bad"

        request = write_request(tmp, payload)
        result = run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)

        assert result.returncode != 0
        assert "blocked secret-like pattern" in result.stdout


def test_blocks_dirty_working_tree():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        (tmp / "dirty.txt").write_text("dirty\n", encoding="utf-8")

        request = write_request(tmp, base_payload())
        result = run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)

        assert result.returncode != 0
        assert "working tree is not clean before execution" in result.stdout


if __name__ == "__main__":
    test_success_creates_local_commit()
    test_blocks_non_docs_path()
    test_blocks_non_markdown_file()
    test_blocks_secret_like_content()
    test_blocks_dirty_working_tree()
    print("OK")

