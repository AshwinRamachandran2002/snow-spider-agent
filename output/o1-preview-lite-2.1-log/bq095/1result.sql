SELECT
  k.prefName AS drug_name,
  t.approvedSymbol AS target_approved_symbol,
  STRING_AGG(DISTINCT u.element.url, ', ') AS clinical_trial_links
FROM
  `open-targets-prod.platform.knownDrugsAggregated` AS k
JOIN
  `open-targets-prod.platform.targets` AS t
    ON k.targetId = t.id
CROSS JOIN
  UNNEST(k.urls.list) AS u
WHERE
  k.diseaseId = 'EFO_0007416'
  AND k.phase >= 3
GROUP BY
  k.prefName,
  t.approvedSymbol;