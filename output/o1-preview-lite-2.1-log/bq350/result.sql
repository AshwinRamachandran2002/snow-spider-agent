SELECT `id` AS `drug_id`, `drugType` AS `drug_type`, `hasBeenWithdrawn`
FROM `open-targets-prod.platform.molecule`
WHERE `isApproved` = TRUE
  AND `blackBoxWarning` = TRUE
  AND `drugType` IS NOT NULL
  AND `drugType` != 'Unknown'
  AND (
    LOWER(`name`) IN ('keytruda', 'vioxx', 'premarin', 'humira')
    OR EXISTS (
      SELECT 1 FROM UNNEST(`synonyms`.`list`) AS s
      WHERE LOWER(s.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
    )
    OR EXISTS (
      SELECT 1 FROM UNNEST(`tradeNames`.`list`) AS t
      WHERE LOWER(t.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
    )
  );