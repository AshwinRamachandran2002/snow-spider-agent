/* Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
   – return molecule (drug) name, target approved symbol and clinical-trial URLs */
SELECT DISTINCT
       COALESCE(m."name", k."prefName")                            AS "drug_name",
       k."approvedSymbol"                                          AS "target_symbol",
       url_item.value:"element":"url"::STRING                      AS "clinical_trial_url"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED"  k
LEFT  JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"          m
       ON m."id" = k."drugId"
     , LATERAL FLATTEN(INPUT => k."urls":"list")                 url_item
WHERE  k."diseaseId" = 'EFO_0007416'                 -- pancreatic endocrine carcinoma
  AND  LOWER(k."status") LIKE '%complete%'           -- completed trials
  AND  url_item.value:"element":"url" IS NOT NULL    -- keep rows that contain a URL
ORDER BY "drug_name", "clinical_trial_url";