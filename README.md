# Med-KAG-rs

This repository contains **only the data, results, and configuration** used to run
the [`kag`](https://github.com/c2fc2f/kag) program in a medical context. It holds no
source code of its own; the executable lives in the `kag` repository.

The purpose of this repository is to collect Knowledge-Augmented Generation (KAG)
benchmark results on medical question answering, so that a baseline (the model
answering from its own internal knowledge) can be compared against a KAG setup (the
same model answering from context retrieved from a Neo4j knowledge graph).

## What is `kag`

`kag` is a command-line tool written in Rust for Knowledge-Augmented Generation
(also known as GraphRAG). For each prompt it can optionally retrieve a subgraph from
a Neo4j knowledge graph through vector similarity plus neighborhood expansion, render
that subgraph as text, and inject it into the prompt before sending it to a completion
model. It also ships a benchmark runner and a scoring command to compare techniques
and models across datasets. See the upstream repository for installation and usage.

## Knowledge graph (PMU)

`kag` does not build the knowledge graph itself; it queries a graph that already
exists in Neo4j. The graph used by the KAG setup here is a PubMed / MeSH / UMLS
("PMU") graph, generated and enriched with the following separate tools:

- [PubMed-MeSH-to-KG](https://github.com/c2fc2f/PubMed-MeSH-to-KG) — CLI tool that
  converts the PubMed and MeSH datasets into a CSV-based knowledge graph
  representation for Neo4j.
- [Extend-PubMed-MeSH-KG](https://github.com/c2fc2f/Extend-PubMed-MeSH-KG) — a
  multitool for extending PubMed-MeSH knowledge graphs (CSV-based, for Neo4j) with
  additional nodes, relationships, and external metadata.
- [UMLS-to-KG](https://github.com/c2fc2f/UMLS-to-KG) — CLI tool that converts the
  UMLS dataset into a CSV-based knowledge graph representation for Neo4j.

The retriever in this repository queries that graph through the `MESH_INDEX` vector
index (see the configuration below). The graph data itself is not included here.

### Vector index

Each `MeSH` node must carry an `embedding` property, and a Neo4j vector index named
`MESH_INDEX` must exist over it before `kag` can run the KAG setup. The embeddings are
produced with the `embeddinggemma` model (768 dimensions), so the index is created
with a matching dimensionality and cosine similarity:

```cypher
CREATE VECTOR INDEX `MESH_INDEX` IF NOT EXISTS
FOR (n:MeSH)
ON (n.embedding)
OPTIONS {
  indexConfig: {
    `vector.dimensions`: 768,
    `vector.similarity_function`: 'cosine'
  }
};
```

## Configuration

`configs/config.toml` declares the components referenced by name during a run:

- An **Ollama** provider for completion and embedding models.
- A **Neo4j** database, with its connection URI and password read from the
  `NEO4J_URI` and `NEO4J_PASSWORD` environment variables.
- An **embedding retriever** (`neo4j-embedding-triplet-formal`) that embeds the query
  with `embeddinggemma:latest`, runs a top-k (3) vector search against the
  `MESH_INDEX` index, expands one hop into the graph neighborhood, and renders the
  resulting subgraph as formal Cypher-like triplets.

`configs/benchmark.toml` defines the two setups that are compared:

| Setup | Model | Augmentation | Prompt |
| --- | --- | --- | --- |
| `qwen35-9b-ollama-native` | `qwen3.5:9b` | None (baseline) | `prompt_mcq.md` |
| `qwen35-9b-ollama-neo4j-embedding-triplet-formal` | `qwen3.5:9b` | Neo4j retriever (KAG) | `pmu_prompt_mcq.md` |

Both setups run at temperature `0.0` with a token budget of `10000`, on the
`pubmedqa` dataset.

## Datasets

`datasets/mirage.json` holds the MIRAGE medical question-answering benchmark. It is
split into several subsets:

| Subset | Entries |
| --- | --- |
| medqa | 1273 |
| medmcqa | 4183 |
| pubmedqa | 500 |
| bioasq | 618 |
| mmlu | 1089 |

Each entry provides an input question, an answer type (for example multiple choice),
the available options, and the ground-truth answer. The results published here cover
the `pubmedqa` subset.

## Prompts

- `prompts/prompt_mcq.md` is the baseline prompt: the model answers from its own
  internal medical knowledge, returning only the key of the correct choice.
- `prompts/pmu_prompt_mcq.md` is the KAG prompt: the model is instructed to rely
  strictly on the provided PubMed / MeSH / UMLS graph context and to ignore external
  knowledge, again returning only the key of the correct choice.

## Results

`results/pubmedqa/` contains one folder per question (identified by its PubMed ID).
Each folder holds two JSON files, one per setup:

- `wekgr-qwen35-9b-ollama-native.json` (baseline)
- `wekgr-qwen35-9b-ollama-neo4j-embedding-triplet-formal.json` (KAG)

Each result records the selected answer, the exact prompt sent to the model, the
retrieved graph context (for the KAG setup), the run configuration, and the elapsed
time. These files are the raw material for comparing baseline accuracy against the
KAG-augmented accuracy; scoring is performed with the `stats` subcommand of `kag`.

## License

This repository is distributed under the MIT License. See `LICENSE` for details.
