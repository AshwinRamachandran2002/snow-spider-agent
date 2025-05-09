SELECT
  id AS drugId,
  drugType,
  hasBeenWithdrawn
FROM `bigquery-public-data.open_targets_platform.molecule`
WHERE LOWER(name) IN ('pembrolizumab',           -- Keytruda
                      'rofecoxib',               -- Vioxx
                      'estrogens, conjugated',   -- Premarin
                      'adalimumab')              -- Humira
  AND isApproved = TRUE                 -- FDA-approved
  AND blackBoxWarning = TRUE            -- carries an FDA black-box warning
  AND drugType IS NOT NULL              -- has a known drug class
  AND LOWER(drugType) <> 'unknown';