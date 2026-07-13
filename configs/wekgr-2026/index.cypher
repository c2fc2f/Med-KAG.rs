CREATE VECTOR INDEX `MESH_INDEX` IF NOT EXISTS
FOR (n:MeSH)
ON (n.embedding)
OPTIONS {
  indexConfig: {
    `vector.dimensions`: 768,
    `vector.similarity_function`: 'cosine'
  }
};
