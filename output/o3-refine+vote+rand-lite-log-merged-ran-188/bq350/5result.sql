-- Approved drugs that carry a Black-Box warning and match Keytruda, Vioxx, Premarin, or Humira
SELECT
  m.id               AS drug_id,
  m.drugType         AS drug_type,
  m.hasBeenWithdrawn AS withdrawal_status
FROM `bigquery-public-data.open_targets_platform.molecule` AS m
WHERE m.isApproved      = TRUE                         -- FDA-approved
  AND m.blackBoxWarning = TRUE                         -- carries Black-Box warning
  AND m.drugType IS NOT NULL                           -- known drug type
  AND LOWER(m.drugType) <> 'unknown'
  AND (
        REGEXP_CONTAINS(LOWER(m.name), r'(keytruda|vioxx|premarin|humira)')
     OR EXISTS (
          SELECT 1
          FROM UNNEST(COALESCE(m.tradeNames.list, [])) AS tn
          WHERE REGEXP_CONTAINS(LOWER(tn.element), r'(keytruda|vioxx|premarin|humira)')
        )
     OR EXISTS (
          SELECT 1
          FROM UNNEST(COALESCE(m.synonyms.list, [])) AS syn
          WHERE REGEXP_CONTAINS(LOWER(syn.element), r'(keytruda|vioxx|premarin|humira)')
        )
      );