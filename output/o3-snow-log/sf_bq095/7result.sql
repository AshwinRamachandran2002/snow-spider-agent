SELECT DISTINCT
       k."drugId",
       COALESCE(m."name", k."prefName") AS "drug_name",
       k."approvedSymbol"               AS "target_symbol",
       u.value:"element":"url"::STRING  AS "clinical_trial_url"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED" k
LEFT  JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"          m
       ON k."drugId" = m."id"
CROSS JOIN LATERAL FLATTEN(input => k."urls":"list")            u
WHERE  k."diseaseId" = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND  k."status"  ILIKE '%Completed%'        -- completed clinical trials
  AND  u.value:"element":"url" IS NOT NULL    -- keep only entries with a URL
ORDER BY k."drugId", "clinical_trial_url";