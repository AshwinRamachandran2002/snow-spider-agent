SELECT
  k.`prefName` AS drug_name,
  k.`approvedSymbol` AS target_approved_symbol,
  STRING_AGG(DISTINCT url.`element`.url, ', ') AS clinical_trial_links
FROM `open-targets-prod.platform.knownDrugsAggregated` AS k
LEFT JOIN UNNEST(k.`urls`.list) AS url
WHERE k.`diseaseId` = 'EFO_0007416' AND k.`phase` >= 3
GROUP BY k.`prefName`, k.`approvedSymbol`