SELECT DISTINCT
       m.id               AS drug_id,
       m.drugType         AS drug_type,
       m.hasBeenWithdrawn AS has_been_withdrawn
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS tn
WHERE m.isApproved      = TRUE
  AND m.blackBoxWarning = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) <> 'unknown'          -- keep only “known” drug types
  AND (
        LOWER(m.name)     IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(tn.element) IN ('keytruda','vioxx','premarin','humira')
      );