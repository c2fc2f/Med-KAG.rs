Based strictly on the provided PubMed/MeSH/UMLS knowledge graph context, answer the following question:

{{INPUT}}

Graph Context:
{{ RETRIEVAL | default('<empty>') }}

Choices:
{{ CHOICE }}

Follow these strict rules:
1. Rely ONLY on the provided graph context. Do not use external medical knowledge.
2. Internally trace the relationships (e.g., 'tributary_of', 'treats', 'exhibits', 'measurement_of') between the medical nodes to determine the correct answer.
3. Your final output must be EXACTLY AND EXCLUSIVELY the single key corresponding to the correct choice (e.g., 'a', 'b', 'c'). Do not include any explanations, reasoning, punctuation, or additional text.
4. If the provided graph context does not contain the information needed to answer the question, reply exactly with: 'I don't know.'
