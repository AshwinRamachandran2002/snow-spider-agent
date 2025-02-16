-- Task: For each molecule with heavy atom counts between 10 and 15, retrieve the calculated publication date based on their associated document's rank within the same journal and year (mapped to a synthetic month and day), and report the heavy atom count, the calculated publication date, and the document ID. Limit the results to 100 entries.
SELECT
  act.molregno,
  CAST(cmp.heavy_atoms AS INT64) AS heavy_atoms,
  CAST(d.doc_id AS INT64) AS doc_id,
  DATE(
    COALESCE(CAST(d.year AS INT64), 1970),
    COALESCE(CAST(FLOOR(PERCENT_RANK() OVER (
      PARTITION BY d.journal, d.year
      ORDER BY SAFE_CAST(d.first_page AS INT64)
    ) * 11) AS INT64) + 1, 1),
    COALESCE(MOD(CAST(FLOOR(PERCENT_RANK() OVER (
      PARTITION BY d.journal, d.year
      ORDER BY SAFE_CAST(d.first_page AS INT64)
    ) * 308) AS INT64), 28) + 1, 1)
  ) AS publication_date
FROM `bigquery-public-data.ebi_chembl.activities` act
JOIN `bigquery-public-data.ebi_chembl.compound_properties` cmp USING (molregno)
LEFT JOIN `bigquery-public-data.ebi_chembl.docs` d USING (doc_id)
WHERE CAST(cmp.heavy_atoms AS INT64) BETWEEN 10 AND 15
LIMIT 100