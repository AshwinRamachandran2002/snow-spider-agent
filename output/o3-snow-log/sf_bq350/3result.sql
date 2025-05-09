SELECT
  "id"            AS "drug_id",
  "drugType"      AS "drug_type",
  "hasBeenWithdrawn" AS "withdrawn_status"
FROM
  OPEN_TARGETS_PLATFORM_1.PLATFORM."MOLECULE"
WHERE
  "isApproved" = TRUE                       -- approved drugs
  AND "blackBoxWarning" = TRUE              -- with Black-Box warning
  AND (                                     
        LOWER("name") IN ('keytruda','vioxx','premarin','humira')
     OR "synonyms"::string ILIKE '%Keytruda%'
     OR "synonyms"::string ILIKE '%Vioxx%'
     OR "synonyms"::string ILIKE '%Premarin%'
     OR "synonyms"::string ILIKE '%Humira%'
     OR "tradeNames"::string ILIKE '%Keytruda%'
     OR "tradeNames"::string ILIKE '%Vioxx%'
     OR "tradeNames"::string ILIKE '%Premarin%'
     OR "tradeNames"::string ILIKE '%Humira%'
      );