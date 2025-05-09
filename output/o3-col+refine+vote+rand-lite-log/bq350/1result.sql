-- Approved drugs that carry a black-box warning and have a defined drug type
-- Filtered to the four requested medicines: Keytruda, Vioxx, Premarin, Humira
SELECT DISTINCT
  m.id            AS drug_id,
  m.drugType      AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(m.tradeNames.list) AS trade
WHERE (LOWER(m.name)  IN ('keytruda','vioxx','premarin','humira')
       OR LOWER(trade.element) IN ('keytruda','vioxx','premarin','humira'))
  AND m.isApproved       = TRUE          -- drug is approved
  AND m.blackBoxWarning  = TRUE          -- carries FDA black-box warning
  AND m.drugType IS NOT NULL             -- has a known (non-null) drug type
  AND LOWER(m.drugType) <> 'unknown'     -- exclude “Unknown” classifications
;