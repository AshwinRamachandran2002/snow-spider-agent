-- Approved drugs that carry an FDA Black-Box warning,
-- have a non-null/known drug type, and are marketed under
-- the brand names Keytruda, Vioxx, Premarin, or Humira.
SELECT
  id              AS drug_id,
  drugType        AS drug_type,
  hasBeenWithdrawn AS withdrawal_status
FROM  `bigquery-public-data.open_targets_platform.molecule`
WHERE
      blackBoxWarning = TRUE           -- carries Black-Box warning
  AND isApproved      = TRUE           -- drug is approved
  AND drugType IS NOT NULL
  AND LOWER(drugType) NOT IN ('unknown','') -- keep only known types
  AND (
        REGEXP_CONTAINS(LOWER(name),                      r'(keytruda|vioxx|premarin|humira)')
     OR REGEXP_CONTAINS(LOWER(TO_JSON_STRING(tradeNames)), r'(keytruda|vioxx|premarin|humira)')
     OR REGEXP_CONTAINS(LOWER(TO_JSON_STRING(synonyms)),   r'(keytruda|vioxx|premarin|humira)')
      );