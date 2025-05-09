SELECT DISTINCT
  m.id            AS drug_id,
  m.drugType      AS drug_type,
  m.hasBeenWithdrawn
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
WHERE m.isApproved       = TRUE
  AND m.blackBoxWarning  = TRUE
  AND m.drugType IS NOT NULL
  AND (
        REGEXP_CONTAINS(
          LOWER(m.name),
          r'\b(keytruda|pembrolizumab|vioxx|rofecoxib|premarin|conjugated[ _-]?estrogens?|humira|adalimumab)\b'
        )
     OR EXISTS (
          SELECT 1
          FROM UNNEST(IFNULL(m.synonyms.list, [])) AS syn
          WHERE REGEXP_CONTAINS(
                  LOWER(syn.element),
                  r'\b(keytruda|pembrolizumab|vioxx|rofecoxib|premarin|conjugated[ _-]?estrogens?|humira|adalimumab)\b'
                )
     )
  );