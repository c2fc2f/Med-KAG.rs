CREATE VECTOR INDEX `UMLS_INDEX` IF NOT EXISTS
FOR (n:UMLSConcept)
ON (n.embedding)
OPTIONS {
  indexConfig: {
    `vector.dimensions`: 768,
    `vector.similarity_function`: 'cosine'
  }
};
