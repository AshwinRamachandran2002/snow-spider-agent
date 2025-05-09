-- Approved drugs with an FDA Black-Box Warning whose brand name (trade name or synonym)
-- matches exactly Keytruda, Vioxx, Premarin or Humira.
-- Output: drug id, drug type and withdrawal status.
SELECT DISTINCT
       m.id               AS drug_id,
       m.drugType         AS drug_type,
       m.hasBeenWithdrawn AS has_been_withdrawn
FROM   `bigquery-public-data.open_targets_platform.molecule` AS m
WHERE  m.blackBoxWarning = TRUE            -- carries FDA black-box warning
  AND  m.isApproved      = TRUE            -- approved drug
  AND  m.drugType        IS NOT NULL       -- known drug type
  AND (
        -- brand appears among official trade names
        EXISTS (SELECT 1
                FROM UNNEST(m.tradeNames.list) AS t
                WHERE UPPER(t.element) IN ('KEYTRUDA','VIOXX','PREMARIN','HUMIRA'))
        OR
        -- …or appears in any synonym (case-insensitive)
        EXISTS (SELECT 1
                FROM UNNEST(m.synonyms.list) AS s
                WHERE REGEXP_CONTAINS(LOWER(s.element),
                                     r'(keytruda|vioxx|premarin|humira)'))
      );