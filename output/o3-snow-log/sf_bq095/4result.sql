SELECT
    k."prefName"                                         AS "drug_name",
    k."approvedSymbol"                                   AS "target_approved_symbol",
    LISTAGG(DISTINCT u.value:"url"::STRING, '; ') 
        WITHIN GROUP (ORDER BY u.value:"url"::STRING)    AS "clinical_trial_urls"
FROM  OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED" k,
      LATERAL FLATTEN(INPUT => k."urls") u
WHERE k."diseaseId" = 'EFO_0007416'               -- pancreatic endocrine carcinoma
  AND LOWER(k."status") LIKE '%completed%'        -- keep only completed trials
GROUP BY
    k."prefName",
    k."approvedSymbol"
ORDER BY
    k."prefName";