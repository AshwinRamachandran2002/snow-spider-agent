-- Drug ID, type, and withdrawal status for approved black-box-warning drugs 
-- traded as Keytruda, Vioxx, Premarin, or Humira
SELECT DISTINCT
  m.id           AS drug_id,
  m.drugType     AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
CROSS JOIN UNNEST(m.tradeNames.list) AS tn
WHERE LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
  AND m.blackBoxWarning = TRUE
  AND m.isApproved      = TRUE
  AND m.drugType        IS NOT NULL;