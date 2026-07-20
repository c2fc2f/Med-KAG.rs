Based strictly on the provided UMLS knowledge graph context, answer the following question:

{{INPUT}}

Graph Context:
{{ RETRIEVAL | default('<empty>') }}

Choices:
{{ CHOICE }}

Follow these strict rules:
1. Rely ONLY on the provided graph context. Do not use external medical knowledge.
2. The context is given as plain sentences. Some sentences describe an entity (its term, source vocabulary, definition, semantic type, identifiers); others state how two entities are linked ("X treats Y", "X is a tributary of Y", "X exhibits Y", "X is a measurement of Y", "X is a kind of Y", "X is a synonym of Y"). Internally chain these statements together, and use both what each sentence says about an entity and the links the sentences express between entities, to determine the answer.
3. Your final output must be EXACTLY AND EXCLUSIVELY the single key corresponding to the correct choice (e.g., 'A', 'B', 'C'). Do not include any explanations, reasoning, punctuation, or additional text.
4. If the provided graph context does not contain the information needed to answer the question, reply exactly with: 'I don't know.'
