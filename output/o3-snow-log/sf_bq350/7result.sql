WITH warned_drugs AS (
    SELECT DISTINCT
           f.value:"element"::STRING AS chembl_id
    FROM  OPEN_TARGETS_PLATFORM_1.PLATFORM.DRUGWARNINGS d,
          LATERAL FLATTEN(INPUT => d."chemblIds":list) f
    WHERE d."warningType" ILIKE 'Black Box Warning'
)

SELECT
       m."id"               AS "drug_id",
       m."drugType"         AS "drug_type",
       m."hasBeenWithdrawn" AS "withdrawal_status"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE   m
JOIN   warned_drugs                                 w
       ON m."id" = w.chembl_id
WHERE  m."isApproved" = TRUE
  AND  m."drugType"  IS NOT NULL
  AND (
        ILIKE(m."name", 'Keytruda')
     OR ILIKE(m."name", 'Vioxx')
     OR ILIKE(m."name", 'Premarin')
     OR ILIKE(m."name", 'Humira')
     OR TO_VARCHAR(m."tradeNames") ILIKE '%Keytruda%'
     OR TO_VARCHAR(m."tradeNames") ILIKE '%Vioxx%'
     OR TO_VARCHAR(m."tradeNames") ILIKE '%Premarin%'
     OR TO_VARCHAR(m."tradeNames") ILIKE '%Humira%'
  );