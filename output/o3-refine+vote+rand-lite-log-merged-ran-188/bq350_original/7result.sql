-- Approved drugs that carry an FDA Black-Box warning, have a defined drug type,
-- and whose trade names include any of the brands Keytruda, Vioxx, Premarin, or Humira
SELECT DISTINCT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS tn
ON TRUE
WHERE REGEXP_CONTAINS(LOWER(COALESCE(tn.element, '')),
                       r'(keytruda|vioxx|premarin|humira)')
  AND m.isApproved      = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType        IS NOT NULL;