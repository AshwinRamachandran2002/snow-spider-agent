SELECT DISTINCT m.`id` AS drug_id, m.`drugType` AS drug_type, m.`hasBeenWithdrawn`
FROM `open-targets-prod.platform.molecule` AS m
LEFT JOIN UNNEST(m.`tradeNames`.list) AS tn ON TRUE
LEFT JOIN UNNEST(m.`synonyms`.list) AS sn ON TRUE
WHERE m.`isApproved` = TRUE
  AND m.`blackBoxWarning` = TRUE
  AND m.`drugType` IS NOT NULL AND m.`drugType` <> 'Unknown'
  AND (
    LOWER(m.`name`) IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
    LOWER(tn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira') OR
    LOWER(sn.element) IN ('keytruda', 'vioxx', 'premarin', 'humira')
  );