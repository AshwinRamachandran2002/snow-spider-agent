-- approved drugs with a black-box warning and a known drug type
-- that are marketed as Keytruda, Vioxx, Premarin, or Humira
SELECT DISTINCT
       m.id               AS drug_id,
       m.drugType         AS drug_type,
       m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(IFNULL(m.tradeNames.list, [])) AS tn      -- trade names
LEFT JOIN UNNEST(IFNULL(m.synonyms.list, []))   AS sn      -- synonyms
WHERE (
        LOWER(m.name)              IN ('keytruda','vioxx','premarin','humira')
     OR LOWER(tn.element) LIKE '%keytruda%'
     OR LOWER(tn.element) LIKE '%vioxx%'
     OR LOWER(tn.element) LIKE '%premarin%'
     OR LOWER(tn.element) LIKE '%humira%'
     OR LOWER(sn.element) LIKE '%keytruda%'
     OR LOWER(sn.element) LIKE '%vioxx%'
     OR LOWER(sn.element) LIKE '%premarin%'
     OR LOWER(sn.element) LIKE '%humira%'
      )
  AND m.blackBoxWarning = TRUE     -- must carry an FDA black-box warning
  AND m.isApproved      = TRUE     -- approved for use
  AND m.drugType IS NOT NULL       -- ensure drug type is known
ORDER BY drug_id;