SELECT DISTINCT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM
  `bigquery-public-data.open_targets_platform.molecule` AS m
WHERE
  m.blackBoxWarning = TRUE
  AND m.isApproved = TRUE
  AND m.drugType IS NOT NULL
  AND (
        LOWER(m.name) IN ('keytruda', 'vioxx', 'premarin', 'humira')
     OR EXISTS (
          SELECT 1
          FROM UNNEST(IFNULL(m.tradeNames.list, [])) AS tn
          WHERE LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
        )
     OR EXISTS (
          SELECT 1
          FROM UNNEST(IFNULL(m.synonyms.list, [])) AS sn
          WHERE LOWER(sn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
        )
  );