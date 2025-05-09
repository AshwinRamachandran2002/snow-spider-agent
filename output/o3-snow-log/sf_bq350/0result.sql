SELECT DISTINCT
       m."id"               AS "drug_id",
       m."drugType",
       m."hasBeenWithdrawn" AS "withdrawal_status"
FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m,
     LATERAL FLATTEN(
         INPUT  => m."tradeNames":"list",
         OUTER  => TRUE
     ) t
WHERE m."isApproved"      = TRUE            -- approved drugs
  AND m."blackBoxWarning" = TRUE            -- carries Black Box warning
  AND m."drugType"        IS NOT NULL       -- known drug type
  AND (
         UPPER(m."name") IN ('KEYTRUDA','VIOXX','PREMARIN','HUMIRA')
      OR UPPER(t.value:"element"::STRING) IN ('KEYTRUDA','VIOXX','PREMARIN','HUMIRA')
      );