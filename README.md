# Med-KAG.rs

This repository contains **only the data, configuration, and results** used to run
the [`kag`](https://github.com/c2fc2f/kag) program in a medical question-answering
context. It holds no source code of its own; the executable lives in the `kag`
repository.

Its purpose is to collect Knowledge-Augmented Generation (KAG, also known as
GraphRAG) benchmark campaigns on medical question answering, so that a baseline (a
model answering from its own internal knowledge) can be compared against one or more
KAG setups (the same model answering from context retrieved from a Neo4j knowledge
graph).

## What is `kag`

`kag` is a command-line tool written in Rust for Knowledge-Augmented Generation. For
each prompt it can optionally retrieve a subgraph from a Neo4j knowledge graph
through vector similarity plus neighborhood expansion, render that subgraph as text,
and inject it into the prompt before sending it to a completion model. It also ships
a benchmark runner and a scoring command to compare techniques and models across
datasets. See the upstream repository for installation and usage.

## Knowledge graphs

`kag` does not build the knowledge graph itself; it queries a graph that already
exists in Neo4j. The graphs referenced by the campaigns in this repository are built
and enriched with a set of separate tools:

- [PubMed-MeSH-to-KG](https://github.com/c2fc2f/PubMed-MeSH-to-KG) — CLI tool that
  converts the PubMed and MeSH datasets into a CSV-based knowledge graph
  representation for Neo4j.
- [Extend-PubMed-MeSH-KG](https://github.com/c2fc2f/Extend-PubMed-MeSH-KG) — a
  multitool for extending PubMed-MeSH knowledge graphs (CSV-based, for Neo4j) with
  additional nodes, relationships, and external metadata.
- [UMLS-to-KG](https://github.com/c2fc2f/UMLS-to-KG) — CLI tool that converts the
  UMLS dataset into a CSV-based knowledge graph representation for Neo4j.
- [Extend-UMLS-KG](https://github.com/c2fc2f/Extend-UMLS-KG) — a multitool for
  extending UMLS knowledge graphs (CSV-based, for Neo4j) with additional nodes,
  relationships, and external metadata.

Depending on the campaign, the graph may combine PubMed, MeSH, and UMLS data, or rely
on one of them alone; see each campaign's `neo4j.schema` for its exact shape (see
[Campaigns](#campaigns) below). The graph data itself is not included here — only the
configuration used to query it.

## Campaigns

A **campaign** is one self-contained experimental setup: a graph, a retrieval
strategy, a set of prompts, and the models being compared. Each campaign lives under
its own directory name (for example, tied to the conference or workshop it was
submitted to) and follows the same layout:

```
configs/<campaign>/
├── .version         # kag version the campaign was run with
├── config.toml       # providers, database, and retriever components
├── benchmark.toml    # setups being compared (model, prompt, augmentation)
├── index.cypher      # Neo4j vector index required by the retriever(s)
└── neo4j.schema      # schema of the graph the campaign queries

prompts/<campaign>/
└── *.md               # system prompt templates referenced by benchmark.toml
```

### Configuration

`configs/<campaign>/config.toml` declares the components referenced by name during a
run:

- One or more **providers** (typically Ollama) for completion and embedding models.
- A **Neo4j** database, with its connection URI and password read from the
  `NEO4J_URI` and `NEO4J_PASSWORD` environment variables.
- One or more **embedding retrievers**, each embedding the query with a given model,
  running a top-k vector search against a named Neo4j index, expanding a fixed number
  of hops into the graph neighborhood, and rendering the resulting subgraph either as
  formal Cypher-like triplets or as natural-language sentences (see `kag`'s own
  README for the two translation strategies).

`configs/<campaign>/benchmark.toml` defines the setups being compared for that
campaign: always a native baseline (the model answering from its own knowledge) plus
one or more KAG-augmented setups, each pointing to a retriever declared in
`config.toml` and a prompt file under `prompts/<campaign>/`.

### Vector index

Every retriever queries a Neo4j vector index that must exist before `kag` can run.
`configs/<campaign>/index.cypher` holds the exact `CREATE VECTOR INDEX` statement for
that campaign, matching the embedding model's dimensionality and similarity function,
for example:

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

### Schema

`configs/<campaign>/neo4j.schema` documents the node labels, relationship types, and
properties of the graph that campaign expects to query, as reported by Neo4j's own
schema introspection. It is informational only — the graph itself is built and
populated by the tools listed under [Knowledge graphs](#knowledge-graphs).

## Datasets

`datasets/mirage.json` holds the [MIRAGE](https://github.com/Teddy-XiongGZ/MIRAGE)
medical question-answering benchmark, split into several subsets:

| Subset | Entries |
| --- | --- |
| medqa | 1273 |
| medmcqa | 4183 |
| pubmedqa | 500 |
| bioasq | 618 |
| mmlu | 1089 |

Each entry provides an input question, an answer type (for example multiple choice),
the available options, and the ground-truth answer. A campaign's `benchmark.toml`
selects which subset(s) it runs against.

## Prompts

Each campaign ships its own prompt templates under `prompts/<campaign>/`, typically:

- a **native** prompt, instructing the model to answer from its own internal medical
  knowledge;
- one or more **KAG** prompts, instructing the model to rely strictly on the
  retrieved graph context (formal triplets and/or natural-language sentences,
  depending on the retriever) and to ignore external knowledge.

All prompts require the model to answer with exactly the key of the correct choice,
and nothing else, to keep scoring unambiguous.

## Results

`results/<dataset>/` contains one folder per question, identified by its ID in the
dataset (for `pubmedqa`, its PubMed ID). Each folder holds one JSON file per
`<campaign>-<setup>` pair evaluated for that question, named
`<campaign>-<setup>.json`. Result files are tracked with [Git LFS](https://git-lfs.com/).

Each result records the model's selected answer, the exact prompt sent to it, the
retrieved graph context (for KAG setups), the run configuration, and the elapsed
time. These files are the raw material for comparing baseline accuracy against
KAG-augmented accuracy for a given campaign; scoring is performed with the `stats`
subcommand of `kag`, which aggregates a result tree against the dataset's ground
truth.

Campaigns are added over time as new experiments are run; consult a given
`configs/<campaign>/` directory and its corresponding entries under `results/` for
the specifics of that run.

## License

This repository is distributed under the MIT License. See `LICENSE` for details.
