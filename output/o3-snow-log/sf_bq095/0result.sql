SELECT DISTINCT
       m."name"                AS "drug_name",
       k."approvedSymbol"      AS "target_symbol",
       f.value:"url"::STRING   AS "clinical_trial_url"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED" k
JOIN   OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"             m
       ON k."drugId" = m."id",
     LATERAL FLATTEN(INPUT => k."urls")                         f
WHERE  k."diseaseId" = 'EFO_0007416'     -- pancreatic endocrine carcinoma
  AND  k."status"   = 'Completed';