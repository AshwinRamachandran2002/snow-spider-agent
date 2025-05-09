SELECT DISTINCT m.id AS drug_id, m.drugType AS drug_type, m.hasBeenWithdrawn
FROM `open-targets-prod.platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS tn
LEFT JOIN UNNEST(m.synonyms.list) AS s
WHERE m.isApproved = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) != 'unknown'
  AND (
    LOWER(m.name) IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
    LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
    LOWER(s.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
  );