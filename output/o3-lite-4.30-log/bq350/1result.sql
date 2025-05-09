SELECT DISTINCT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS tn
LEFT JOIN UNNEST(m.synonyms.list)   AS sn
WHERE m.isApproved      = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType        IS NOT NULL
  AND (
        LOWER(m.name)     IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
        LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
        LOWER(sn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
      )
ORDER BY drug_id;