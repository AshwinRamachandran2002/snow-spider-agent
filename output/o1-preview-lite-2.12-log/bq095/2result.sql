SELECT DISTINCT
  prefName AS drug_name,
  approvedSymbol AS target_approved_symbol,
  url.element.url AS clinical_trial_links
FROM
  `open-targets-prod.platform.knownDrugsAggregated`,
  UNNEST(urls.list) AS url
WHERE
  diseaseId = 'EFO_0007416'
  AND status = 'Completed'
  AND url.element.url LIKE '%clinicaltrials.gov%'