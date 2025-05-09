-- Drug ID, type, and withdrawal status for the requested agents
-- that are   • approved
--            • carry a Black-Box Warning
--            • have a non-null, non-“Unknown” drug type
SELECT DISTINCT
  m.id AS drug_id,
  m.drugType,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS tn
LEFT JOIN UNNEST(m.synonyms.list)   AS syn
WHERE (
        LOWER(m.name)     IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(tn.element) IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(syn.element)IN ('keytruda','vioxx','premarin','humira')
      )
  AND m.isApproved      = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) <> 'unknown';