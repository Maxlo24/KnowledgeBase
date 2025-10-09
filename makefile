# Makefile for generating and managing a Python project.

# VARIABLES
PROJECT_NAME ?= default-project
PYTHON_VERSION ?= 3.12
PYTHON_EXECUTABLE = $(PYTHON_VERSION)
VENV_DIR = .venv
PYTHON_DIR = python
NOTEBOOK_DIR = $(PYTHON_DIR)/notebooks
SRC_DIR = $(PYTHON_DIR)/src
TESTS_DIR = $(PYTHON_DIR)/tests
DATA_DIR = data
DOCS_DIR = documents
CONFIG_DIR = config

# Phony targets are not associated with files.
.PHONY: setup setup_notebook create_init init sanitize help clean activate test coverage run

# Default command to run when 'make' is called without arguments.
help:
	@echo "Available commands:"
	@echo "  make setup    - Initialize project (folders, pyproject.toml, default deps)."
	@echo "  make init     - Create .venv and install dependencies."
	@echo "  make sanitize - Run linter and formatter."
	@echo "  make test     - Run pytest."
	@echo "  make coverage - Run pytest with coverage report."
	@echo "  make clean    - Remove virtual environment and cache files."
	@echo "  make activate - Print activation command."

# TARGET: setup
setup:
	@echo "--- Creating project directories ---"
	@mkdir -p $(SRC_DIR) $(TESTS_DIR) $(DATA_DIR) $(DOCS_DIR) $(CONFIG_DIR) $(NOTEBOOK_DIR)
	@echo "--- Creating __init__.py in src ---"
	@touch $(SRC_DIR)/__init__.py  # <--- NEW: Makes 'src' a package
	@echo "--- Creating main.py in src ---"
	@echo 'from loguru import logger\n\n' > $(SRC_DIR)/main.py
	@echo 'def main():\n    logger.debug("Hello from main.py!")\n\n\nif __name__ == "__main__":\n    main()' >> $(SRC_DIR)/main.py
	@echo "--- Creating placeholder test file ---"
	@echo 'def test_always_passes():\n    assert True' > $(TESTS_DIR)/test_placeholder.py
	@echo "--- Creating .gitignore and .env placeholders ---"
	@echo ".venv/\n__pycache__/\n*.pyc\n.pytest_cache/\nhtmlcov/\n.coverage\n.ruff_cache/\nuv.lock\n.env" > .gitignore
	@echo "# Local environment variables go here\n" > .env
	
	@echo "--- Initializing root pyproject.toml for tooling ---"
	@uv python pin $(PYTHON_EXECUTABLE)
	@uv init --quiet
	@rm -f main.py
	@uv add ruff black pytest pytest-cov pydantic loguru
	@echo '\n[tool.ruff]\nline-length = 88\n\n[tool.ruff.lint]\nselect = ["E", "F", "W", "I"]\nignore = ["E203", "E501"]' >> pyproject.toml

	@echo "--- Initializing python/pyproject.toml for src package ---"
	@cd $(PYTHON_DIR) && uv init --quiet
	@cd $(PYTHON_DIR) && rm -f main.py

	@echo "--- Installing src package in editable mode from python/ ---"
	@uv pip install -e ./$(PYTHON_DIR)

	@echo "--- Setup complete ---"

create_init:
	@echo "--- Creating __init__.py in src and subfolders ---"
	@find $(SRC_DIR) -type d -exec touch {}/__init__.py \;

# TARGET: setup add_notebook
add_notebook:
	@uv add ipykernel

# TARGET: setup add_ml
add_ml:
	@uv add torch numpy

add_llm:
	@uv add langchain langchain-community

add_graph:
	@uv add yfiles-jupyter-graphs neomodel

# TARGET: init
init:
	@echo "--- Creating virtual environment with $(PYTHON_EXECUTABLE) using uv... ---"
	@uv venv -p $(PYTHON_EXECUTABLE)
	@echo "--- Installing dependencies from pyproject.toml... ---"
	@uv sync
# 	@echo "--- Installing project in editable mode ---"
# 	@uv pip install -e ./$(PYTHON_DIR)
	@echo "--- Environment ready. Activate with: source .venv/bin/activate"

# TARGET: sanitize
sanitize:
	@echo "--- Running linter (ruff) and formatter (black)... ---"
	@uv run black $(SRC_DIR) $(TESTS_DIR)
	@uv run ruff check --fix $(SRC_DIR) $(TESTS_DIR)

# TARGET: test
test:
	@echo "--- Running tests with pytest ---"
	@uv run pytest -v $(TESTS_DIR)

# TARGET: coverage
coverage:
	@echo "--- Running tests with pytest + coverage ---"
	@uv run pytest --cov=$(SRC_DIR) --cov-report=term-missing $(TESTS_DIR)

# TARGET: clean
clean:
	@echo "--- Removing virtual environment, cache files, and alias script... ---"
	@rm -rf $(VENV_DIR)
	@find . -type d \( -name "__pycache__" -o -name ".ruff_cache" -o -name ".pytest_cache" \) -exec rm -rf {} +
	@rm -f uv.lock .coverage activate_alias.sh

# TARGET: activate
activate:
	@echo "Activate with: source .venv/bin/activate"

# TARGET: run
run:
	@echo "--- Running main script ---"
	@uv run python $(SRC_DIR)/main.py
