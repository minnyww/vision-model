# ---- Stage 1: bake the model into its own layer ----
# Pulling at build time (instead of at cold start) so instances start ready to serve.
# `ollama pull` requires a running server, so start one for the duration of the pull.
FROM ollama/ollama:latest AS model-builder
ENV OLLAMA_MODELS=/models
RUN /bin/ollama serve & pid=$!; \
    i=0; \
    until /bin/ollama list >/dev/null 2>&1; do \
        i=$((i+1)); [ $i -gt 60 ] && echo "ollama server did not start" && exit 1; \
        sleep 1; \
    done; \
    /bin/ollama pull minicpm-v4.6 && \
    kill $pid

# ---- Stage 2: runtime ----
FROM ollama/ollama:latest
ENV OLLAMA_MODELS=/models \
    OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_KEEP_ALIVE=10m
COPY --from=model-builder /models /models
EXPOSE 8080
# Base image already sets ENTRYPOINT ["/bin/ollama"] CMD ["serve"]
