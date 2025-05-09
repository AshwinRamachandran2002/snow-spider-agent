-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT DISTINCT
       k."prefName"                               AS "drug_name",
       k."approvedSymbol"                         AS "target_symbol",
       url.value:"element":"url"::STRING          AS "clinical_trial_url"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM.KNOWNDRUGSAGGREGATED k
       ,LATERAL FLATTEN(input => k."urls":"list") url
WHERE  k."diseaseId" = 'EFO_0007416'             -- pancreatic endocrine carcinoma
  AND  k."status" ILIKE '%Completed%'            -- only completed trials
ORDER BY k."prefName", "clinical_trial_url";