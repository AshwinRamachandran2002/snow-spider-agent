-- Drugs with completed clinical-trial records for pancreatic endocrine carcinoma (EFO_0007416)
-- showing drug name (from MOLECULE catalogue), target gene symbol and trial URLs
SELECT
        COALESCE(m."name", k."prefName")                   AS "drug_name",
        t."approvedSymbol"                                 AS "target_symbol",
        LISTAGG(u.value:"element":"url"::STRING, ' | ')
            WITHIN GROUP (ORDER BY u.value:"element":"url"::STRING) 
                                                          AS "clinical_trial_links"
FROM  "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."KNOWNDRUGSAGGREGATED"  k
JOIN  "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."MOLECULE"              m
          ON k."drugId"   = m."id"
JOIN  "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS"               t
          ON k."targetId" = t."id"
CROSS JOIN LATERAL FLATTEN(input => k."urls") u
WHERE k."diseaseId" = 'EFO_0007416'                 -- pancreatic endocrine carcinoma
  AND LOWER(k."status") LIKE '%completed%'          -- keep only completed trials
GROUP BY
        COALESCE(m."name", k."prefName"),
        t."approvedSymbol"
ORDER BY
        "drug_name";