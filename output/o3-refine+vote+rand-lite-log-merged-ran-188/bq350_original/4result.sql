-- Approved drugs that carry an FDA Black-Box Warning and match the brand
-- names Keytruda, Vioxx, Premarin or Humira.
SELECT DISTINCT
       m.id               AS drug_id,
       m.drugType         AS drug_type,
       m.hasBeenWithdrawn AS withdrawal_status
FROM  `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT  JOIN UNNEST(m.tradeNames.list) AS trade          -- brand names
LEFT  JOIN UNNEST(m.synonyms.list)   AS syn            -- synonyms
WHERE m.blackBoxWarning = TRUE                         -- FDA BBW
  AND m.isApproved      = TRUE                         -- approved
  AND m.drugType IS NOT NULL                           -- known drug type
  AND ( LOWER(m.name)            IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(trade.element)     IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(syn.element)  LIKE '%keytruda%'
     OR LOWER(syn.element)  LIKE '%vioxx%'
     OR LOWER(syn.element)  LIKE '%premarin%'
     OR LOWER(syn.element)  LIKE '%humira%' );