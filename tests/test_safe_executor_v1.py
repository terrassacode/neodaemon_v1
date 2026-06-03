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

    (tmp / "docs").mkdir()
    (tmp / "docs" / "FEATURE_WORKFLOW_V1.md").write_text(
        "# Feature Workflow\n\nTARGET LINE\n",
        encoding="utf-8",
    )
    (tmp / "README.md").write_text("# test\n", encoding="utf-8")
    run(["git", "add", "README.md", "docs/FEATURE_WORKFLOW_V1.md", "scripts/safe_executor_v1.py"], tmp)
    run(["git", "commit", "-m", "test: init repo"], tmp)


def write_request(raw, payload):
    path = Path(tempfile.mkdtemp()) / "request.json"
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


def insert_payload():
    return {
        "action": "insert_before",
        "branch": "docs/insert-test",
        "file_path": "docs/FEATURE_WORKFLOW_V1.md",
        "target": "TARGET LINE",
        "content": "Inserted text.",
        "commit_message": "docs(test): insert text",
    }


def run_executor(tmp, payload):
    request = write_request(tmp, payload)
    return run(["python3", "scripts/safe_executor_v1.py", "--input", str(request)], tmp)


def test_success_creates_local_commit():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, base_payload())

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

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "file_path must start with docs/" in result.stdout


def test_blocks_non_markdown_file():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = base_payload()
        payload["file_path"] = "docs/test/bad.txt"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "file_path must end with .md" in result.stdout


def test_blocks_secret_like_content():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = base_payload()
        payload["content"] = "client_secret = bad"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "blocked secret-like pattern" in result.stdout


def test_blocks_dirty_working_tree():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        (tmp / "dirty.txt").write_text("dirty\n", encoding="utf-8")

        result = run_executor(tmp, base_payload())

        assert result.returncode != 0
        assert "working tree is not clean before execution" in result.stdout


def test_inspect_repo_requires_only_action():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, {"action": "inspect_repo"})

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)
        assert data["status"] == "INSPECT_REPO_RESULT"
        assert data["mode"] == "READ_ONLY"


def test_inspect_repo_denies_extra_fields():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, {"action": "inspect_repo", "branch": "bad"})

        assert result.returncode != 0
        assert "unexpected fields for inspect_repo" in result.stdout


def test_inspect_repo_readonly_with_dirty_repo():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)
        (tmp / "dirty.txt").write_text("dirty\n", encoding="utf-8")

        result = run_executor(tmp, {"action": "inspect_repo"})

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)
        assert data["validations"]["read_only"] is True
        assert "dirty.txt" in data["git_status_short"]


def test_inspect_repo_does_not_require_main_branch():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)
        run(["git", "checkout", "-b", "docs/inspection"], tmp)

        result = run_executor(tmp, {"action": "inspect_repo"})

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)
        assert data["branch"] == "docs/inspection"


def test_insert_before_success():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, insert_payload())

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)
        text = (tmp / "docs/FEATURE_WORKFLOW_V1.md").read_text(encoding="utf-8")

        assert data["status"] == "FEATURE_READY_FOR_GITHUB"
        assert data["action"] == "insert_before"
        assert "Inserted text.\n\nTARGET LINE" in text


def test_insert_before_requires_target():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload.pop("target")

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "missing fields for insert_before" in result.stdout


def test_insert_before_requires_content():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload.pop("content")

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "missing fields for insert_before" in result.stdout


def test_insert_before_denies_extra_fields():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload["extra"] = "bad"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "unexpected fields for insert_before" in result.stdout


def test_insert_before_denies_missing_target():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload["target"] = "MISSING"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "target not found" in result.stdout


def test_insert_before_denies_duplicate_target():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)
        path = tmp / "docs/FEATURE_WORKFLOW_V1.md"
        path.write_text("# Feature Workflow\n\nTARGET LINE\nTARGET LINE\n", encoding="utf-8")
        run(["git", "add", "docs/FEATURE_WORKFLOW_V1.md"], tmp)
        run(["git", "commit", "-m", "test: duplicate target"], tmp)

        result = run_executor(tmp, insert_payload())

        assert result.returncode != 0
        assert "target appears more than once" in result.stdout


def test_insert_before_denies_existing_content():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)
        path = tmp / "docs/FEATURE_WORKFLOW_V1.md"
        path.write_text("# Feature Workflow\n\nInserted text.\n\nTARGET LINE\n", encoding="utf-8")
        run(["git", "add", "docs/FEATURE_WORKFLOW_V1.md"], tmp)
        run(["git", "commit", "-m", "test: existing content"], tmp)

        result = run_executor(tmp, insert_payload())

        assert result.returncode != 0
        assert "content already exists" in result.stdout


def test_insert_before_denies_non_docs_path():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload["file_path"] = "README.md"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "file_path must start with docs/" in result.stdout


def test_insert_before_denies_non_markdown():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload["file_path"] = "docs/bad.txt"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "file_path must end with .md" in result.stdout


def test_insert_before_commits_local_change():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, insert_payload())

        assert result.returncode == 0, result.stderr + result.stdout
        data = json.loads(result.stdout)
        assert data["validations"]["working_tree_clean_after_commit"] is True
        assert data["commit"]


def test_insert_before_changes_only_one_file():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        result = run_executor(tmp, insert_payload())

        assert result.returncode == 0, result.stderr + result.stdout
        changed = run(["git", "show", "--name-only", "--format=", "HEAD"], tmp).stdout.strip().splitlines()
        assert changed == ["docs/FEATURE_WORKFLOW_V1.md"]


def test_secret_pattern_blocked_for_insert_before():
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw)
        init_repo(tmp)

        payload = insert_payload()
        payload["content"] = "password = bad"

        result = run_executor(tmp, payload)

        assert result.returncode != 0
        assert "blocked secret-like pattern" in result.stdout


if __name__ == "__main__":
    test_success_creates_local_commit()
    test_blocks_non_docs_path()
    test_blocks_non_markdown_file()
    test_blocks_secret_like_content()
    test_blocks_dirty_working_tree()
    test_inspect_repo_requires_only_action()
    test_inspect_repo_denies_extra_fields()
    test_inspect_repo_readonly_with_dirty_repo()
    test_inspect_repo_does_not_require_main_branch()
    test_insert_before_success()
    test_insert_before_requires_target()
    test_insert_before_requires_content()
    test_insert_before_denies_extra_fields()
    test_insert_before_denies_missing_target()
    test_insert_before_denies_duplicate_target()
    test_insert_before_denies_existing_content()
    test_insert_before_denies_non_docs_path()
    test_insert_before_denies_non_markdown()
    test_insert_before_commits_local_change()
    test_insert_before_changes_only_one_file()
    test_secret_pattern_blocked_for_insert_before()
    print("OK")
