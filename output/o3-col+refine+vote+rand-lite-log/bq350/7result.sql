WITH brands AS (
  SELECT 'keytruda'  AS brand UNION ALL
  SELECT 'vioxx'     UNION ALL
  SELECT 'premarin'  UNION ALL
  SELECT 'humira'
)

SELECT DISTINCT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS is_withdrawn
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
WHERE m.isApproved      = TRUE           -- approved drugs
  AND m.blackBoxWarning = TRUE           -- carrying a Black-Box warning
  AND m.drugType IS NOT NULL             -- known drug type
  AND (
        LOWER(m.name) IN (SELECT brand FROM brands)                 -- main name matches
        OR EXISTS (                                                 -- or any trade-name matches
          SELECT 1
          FROM UNNEST(IFNULL(m.tradeNames.list, [])) AS tn
          WHERE LOWER(tn.element) IN (SELECT brand FROM brands)
        )
      );