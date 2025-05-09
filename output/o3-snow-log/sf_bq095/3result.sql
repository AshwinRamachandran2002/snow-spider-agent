SELECT DISTINCT
       k."drugId",
       m."name"                       AS "drug_name",
       t."approvedSymbol"             AS "target_symbol",
       f.value:"url"::STRING          AS "clinical_trial_url"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED"  k
JOIN   OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"              m ON k."drugId"  = m."id"
JOIN   OPEN_TARGETS_PLATFORM_1.PLATFORM."TARGETS"               t ON k."targetId" = t."id",
       LATERAL FLATTEN(input => k."urls")                       f
WHERE  k."diseaseId" = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND  LOWER(k."status") LIKE '%completed%'   -- keep only completed trials
ORDER BY k."drugId",
         "clinical_trial_url";