SELECT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(IFNULL(m.tradeNames.list, [])) AS tn
WHERE m.isApproved      = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) <> 'unknown'
  AND LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira');