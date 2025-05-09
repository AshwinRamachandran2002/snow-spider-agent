SELECT DISTINCT
       m."id"                AS "drug_id",
       m."drugType",
       m."hasBeenWithdrawn"  AS "withdrawal_status"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m
WHERE  m."isApproved"       = TRUE                -- approved drugs
  AND  m."blackBoxWarning"  = TRUE                -- with Black-Box warning
  AND  m."drugType"         IS NOT NULL           -- known drug type
  AND (
        UPPER(m."name")                         IN ('KEYTRUDA','VIOXX','PREMARIN','HUMIRA')
        OR UPPER(m."tradeNames"::STRING)  LIKE '%KEYTRUDA%'
        OR UPPER(m."tradeNames"::STRING)  LIKE '%VIOXX%'
        OR UPPER(m."tradeNames"::STRING)  LIKE '%PREMARIN%'
        OR UPPER(m."tradeNames"::STRING)  LIKE '%HUMIRA%'
        OR UPPER(m."synonyms"::STRING)    LIKE '%KEYTRUDA%'
        OR UPPER(m."synonyms"::STRING)    LIKE '%VIOXX%'
        OR UPPER(m."synonyms"::STRING)    LIKE '%PREMARIN%'
        OR UPPER(m."synonyms"::STRING)    LIKE '%HUMIRA%'
      )
ORDER BY "drug_id";