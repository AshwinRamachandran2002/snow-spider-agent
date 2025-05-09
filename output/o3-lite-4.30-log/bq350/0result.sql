SELECT DISTINCT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(IFNULL(m.tradeNames.list, [])) AS t
LEFT JOIN UNNEST(IFNULL(m.synonyms.list, []))   AS s
WHERE m.isApproved = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) <> 'unknown'
  AND (
        LOWER(m.name) IN ('keytruda','vioxx','premarin','humira')
        OR LOWER(t.element) IN ('keytruda','vioxx','premarin','humira')
        OR LOWER(s.element) IN ('keytruda','vioxx','premarin','humira')
      );