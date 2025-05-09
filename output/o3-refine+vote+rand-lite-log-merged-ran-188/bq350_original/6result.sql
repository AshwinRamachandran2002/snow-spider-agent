-- Approved drugs with FDA Black-Box warnings whose primary or trade
-- names mention Keytruda, Vioxx, Premarin, or Humira
-- Keep only records that have a defined (non-“Unknown”) drug type
SELECT DISTINCT
       m.id            AS drug_id,
       m.drugType      AS drug_type,
       m.hasBeenWithdrawn AS withdrawal_status
FROM  `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT  JOIN UNNEST(m.tradeNames.list) AS tn
WHERE (
        LOWER(m.name)         LIKE '%keytruda%'  OR LOWER(tn.element) LIKE '%keytruda%' OR
        LOWER(m.name)         LIKE '%vioxx%'     OR LOWER(tn.element) LIKE '%vioxx%'    OR
        LOWER(m.name)         LIKE '%premarin%'  OR LOWER(tn.element) LIKE '%premarin%' OR
        LOWER(m.name)         LIKE '%humira%'    OR LOWER(tn.element) LIKE '%humira%'
      )
  AND m.blackBoxWarning = TRUE
  AND m.isApproved       = TRUE
  AND m.drugType IS NOT NULL
  AND LOWER(m.drugType) <> 'unknown';