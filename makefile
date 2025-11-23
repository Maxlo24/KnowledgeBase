# Makefile for generating and managing a Python project.

# VARIABLES
PROJECT_NAME ?= default-project
PYTHON_VERSION ?= 3.12
PYTHON_EXECUTABLE = $(PYTHON_VERSION)
VENV_DIR = .venv
PYTHON_DIR = python
DATA_DIR = data
DOCS_DIR = documents
CONFIG_DIR = config
SRC_DIR = $(PYTHON_DIR)/src
TESTS_DIR = $(PYTHON_DIR)/tests
CLI_DIR = $(SRC_DIR)/cli
NOTEBOOK_DIR = $(CLI_DIR)/notebooks
COMMON_DIR = $(SRC_DIR)/common
PROMPT_DIR = $(SRC_DIR)/prompts
UTILS_DIR = $(COMMON_DIR)/utils
DATAMODEL_DIR = $(COMMON_DIR)/data_models

APP_DIR = $(SRC_DIR)/app
APP_DOWNLOAD_URL := https://github.com/Maxlo24/KnowledgeBase/releases/download/fast-api-setup-v0/app.zip

# Phony targets are not associated with files.
.PHONY: setup add_notebook add_ml add_llm add_graph create_init init sanitize help clean activate test coverage run remove_all

# Default command to run when 'make' is called without arguments.
help:
	@echo "Available commands:"
	@echo "  make setup       - Initialize project (folders, pyproject.toml, default deps)."
	@echo "  make init        - Create .venv and install dependencies."
	@echo "  make sanitize    - Run linter and formatter."
	@echo "  make test        - Run pytest."
	@echo "  make coverage    - Run pytest with coverage report."
	@echo "  make clean       - Remove virtual environment and cache files."
	@echo "  make activate    - Print activation command."
	@echo "  make add_notebook- Add Jupyter kernel support."
	@echo "  make add_ml      - Add machine learning dependencies (torch, numpy)."
	@echo "  make add_llm     - Add LLM dependencies (langchain, langchain-community)."
	@echo "  make add_graph   - Add graph-related dependencies."
	@echo "  make remove_all  - Deep clean all project files."

# TARGET: setup
setup:
	@echo "--- Creating project directories ---"
	@mkdir -p $(SRC_DIR) $(TESTS_DIR) $(DATA_DIR) $(DOCS_DIR) $(CONFIG_DIR) $(CLI_DIR) $(NOTEBOOK_DIR) $(COMMON_DIR) $(DATAMODEL_DIR) $(UTILS_DIR)
	@make create_init
	@echo "--- Creating main.py in src ---"
	@echo 'from loguru import logger\n\n' > $(UTILS_DIR)/test.py
	@echo 'def Hello():\n    logger.debug("Hello from main.py!")' >> $(UTILS_DIR)/test.py
	@echo 'from common.utils.test import Hello\n\n' > $(CLI_DIR)/main.py
	@echo 'def main():\n    Hello()\n\n\nif __name__ == "__main__":\n    main()' >> $(CLI_DIR)/main.py
	@echo "--- Creating placeholder test file ---"
	@echo 'def test_always_passes():\n    assert True' > $(TESTS_DIR)/test_placeholder.py
	@echo "--- Creating .gitignore and .env placeholders ---"
	@echo ".venv/\n__pycache__/\n*.pyc\n.pytest_cache/\nhtmlcov/\n.coverage\n.ruff_cache/\nuv.lock\n.env\n.DS_Store" > .gitignore
	@echo "# Local environment variables go here\n" > .env
	
	@echo "--- Initializing root pyproject.toml for tooling ---"
	@uv python pin $(PYTHON_EXECUTABLE)
	@uv init --quiet
	@rm -f main.py
	@uv add ruff black pytest pytest-cov pydantic loguru pandas pydantic-settings
	@echo '\n[tool.ruff]\nline-length = 88\n\n[tool.ruff.lint]\nselect = ["E", "F", "W", "I"]\nignore = ["E203", "E501"]' >> pyproject.toml

	@echo "--- Initializing python/pyproject.toml for src package ---"
	@cd $(PYTHON_DIR) && uv init --quiet
	@cd $(PYTHON_DIR) && rm -f main.py
	@cd $(PYTHON_DIR) && echo '\n[project.scripts]\nmain = "cli.main:main"' >> pyproject.toml
	@echo "--- Installing src package in editable mode from python/ ---"
	@uv pip install -e ./$(PYTHON_DIR)

	@echo "--- Initializing root README.md ---"
	@echo '# Your project name\nProvide a description for the project' >> README.md
	@echo '\n## Setup the project\nInit the environment :\n```cli\nmake init\n```\nActivate the environment :\n```cli\nsource .venv/bin/activate\n```' >> README.md
	@echo '\n## Start fast API\nStart the server :\n```cli\nuv run uvicorn python.src.app.server:app --reload --port 8080\n```' >> README.md
	@echo '\n## Make commands\n* use `make sanitize` to automatically make the code compliant.' >> README.md
	@echo '* use `make coverage` to run tests and check the coverage.' >> README.md
	@echo '* use `make clean` to automatically remove cash file and `.venv`.' >> README.md
	@echo '* use `make help` to se other available commands.' >> README.md
	@echo '\n## Run scripts\n```cli\nuv run main\n```' >> README.md
	@echo '\n## Authors\n* Maxime Gillot : maxime.gillot@ibm.com' >> README.md
	@echo "--- Setup complete ---"

create_init:
	@echo "--- Creating __init__.py in src and subfolders ---"
	@find $(SRC_DIR) -type d -exec touch {}/__init__.py \;

# TARGET: setup add_notebook
add_notebook:
	@uv add ipykernel

add_fastapi:
	@uv add fastapi uvicorn dotenv
	@mkdir $(APP_DIR)
	@curl -L $(APP_DOWNLOAD_URL) | tar -xz -C $(APP_DIR) --strip-components=1 --exclude='._*'

# TARGET: setup add_ml
add_ml:
	@uv add torch numpy

add_llm:
	@uv add langchain langchain-community
	@mkdir -p $(PROMPT_DIR)
	@make create_init

add_graph:
	@uv add yfiles-jupyter-graphs neomodel networkx langchain-neo4j

# TARGET: init
init:
	@echo "--- Creating virtual environment with $(PYTHON_EXECUTABLE) using uv... ---"
	@uv venv -p $(PYTHON_EXECUTABLE)
	@echo "--- Installing dependencies from pyproject.toml... ---"
	@uv sync
	@echo "--- Installing project in editable mode ---"
	@uv pip install -e ./$(PYTHON_DIR)
	@echo "--- Environment ready. Activate with: source .venv/bin/activate"

start:
	@cd python && PYTHONPATH=./src uv run uvicorn App.server:app --reload

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
	@uv run python $(CLI_DIR)/main.py

remove_all:
	@echo "--- WARNING ! deep cleaning folder, cache files, and alias script... ---"
	@make clean
	@rm -rf $(PYTHON_DIR) $(DATA_DIR) $(DOCS_DIR) $(CONFIG_DIR) pyproject.toml README.md .env .python-version


