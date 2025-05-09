SELECT
    "id"            AS "drug_id",
    "drugType"      AS "drug_type",
    "hasBeenWithdrawn" AS "withdrawal_status"
FROM
    OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE
WHERE
    "isApproved" = TRUE                         -- approved drugs
    AND "blackBoxWarning" = TRUE                -- with Black-Box warning
    AND "drugType" IS NOT NULL                  -- known drug type
    AND (
            UPPER("name") IN ('KEYTRUDA','VIOXX','PREMARIN','HUMIRA')
         OR "tradeNames"::string ILIKE '%Keytruda%'
         OR "tradeNames"::string ILIKE '%Vioxx%'
         OR "tradeNames"::string ILIKE '%Premarin%'
         OR "tradeNames"::string ILIKE '%Humira%'
        );