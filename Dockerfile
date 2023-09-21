FROM python:3.11.2-slim-bullseye AS builder

RUN apt-get update && \
  apt-get upgrade --yes

RUN useradd -create-home smile
USER smile
WORKDIR /home/smile

ENV VIRTUALENV=/home/smile/.venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="$VIRTUALENV/bin:$PATH"

# COPY --from=builder /home/smile/dist/docker_test*.whl /home/smile

# Cache Your Project Dependencies
COPY --chown=smile pyproject.toml constraints.txt ./
RUN python -m pip install --upgrade pip setuptools && \
    python -m pip install --no-cache-dir -c constraints.txt ".[dev]"

# Run Tests as Part of the Build Process
COPY --chown=smile src/ src/
COPY --chown=smile src/test/ src/test/

RUN python -m pip install . -c constraints.txt && \
    python -m pytest src/test/unit/ && \
    python -m flake8 src/ && \
    python -m isort src/ --check && \
    python -m black src/ --check --quiet && \
    python -m pylint src/ --exit-zero && \
    python -m bandit -r src/docker_test --quiet && \
    python -m pip wheel --wheel-dir dist/ . -c constraints.txt

# Specify the Command to Run in Docker Containers
CMD ["flask", "--app", "page_tracker.app", "run", \
     "--host", "0.0.0.0", "--port", "5000"]



#============= 2ND STAGE ================

FROM python:3.11.2-slim-bullseye

RUN apt-get update && \
  apt-get upgrade --yes

RUN useradd -create-home smile
USER smile
WORKDIR /home/smile

ENV VIRTUALENV=/home/smile/.venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --from=builder /home/smile/dist/docker_test*.whl /home/smile

RUN python -m pip install --upgrade pip setuptools && \
    python -m pip install --no-cache-dir docker_test*.whl

CMD ["flask", "--app", "page_tracker.app", "run", \
     "--host", "0.0.0.0", "--port", "5000"]
