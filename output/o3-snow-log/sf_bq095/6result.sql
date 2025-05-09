SELECT
       k."drugId"                                            AS "drug_id",
       m."name"                                              AS "drug_name",
       t."approvedSymbol"                                    AS "target_symbol",
       ARRAY_TO_STRING(
           ARRAY_AGG(DISTINCT url_item.value:"url"::STRING), ' | '
       )                                                     AS "clinical_trial_links"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM."KNOWNDRUGSAGGREGATED"  k
JOIN   OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"              m
       ON k."drugId" = m."id"
JOIN   OPEN_TARGETS_PLATFORM_1.PLATFORM."TARGETS"               t
       ON k."targetId" = t."id"
,      LATERAL FLATTEN(input => k."urls")                       url_item
WHERE  k."diseaseId" = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND  LOWER(k."status") LIKE '%completed%'   -- keep only completed trials
GROUP  BY k."drugId", m."name", t."approvedSymbol"
ORDER  BY m."name";