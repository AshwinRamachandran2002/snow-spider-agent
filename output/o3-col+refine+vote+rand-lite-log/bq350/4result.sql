SELECT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
LEFT JOIN UNNEST(IFNULL(m.tradeNames.list, [])) AS tn
LEFT JOIN UNNEST(IFNULL(m.synonyms.list,    [])) AS sn
WHERE (
        REGEXP_CONTAINS(LOWER(m.name), r'keytruda|vioxx|premarin|humira')      OR
        REGEXP_CONTAINS(LOWER(tn.element), r'keytruda|vioxx|premarin|humira') OR
        REGEXP_CONTAINS(LOWER(sn.element), r'keytruda|vioxx|premarin|humira')
      )
  AND m.isApproved       = TRUE          -- FDA-approved
  AND m.blackBoxWarning  = TRUE          -- carries Black-Box warning
  AND m.drugType IS NOT NULL             -- known drug type
ORDER BY drug_id;