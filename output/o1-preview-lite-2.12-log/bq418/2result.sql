WITH SorafenibDrugIDs AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),
SorafenibTargets AS (
  SELECT DISTINCT UPPER(REGEXP_EXTRACT(i.target_uniprotID, r'^[^-]+')) AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` AS i
  JOIN SorafenibDrugIDs d ON i.drugID = d.drugID
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` AS e
    ON i.expID = e.expID
  WHERE LOWER(i.targetSpecies) = 'homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow <= 100 OR e.exp_assayValueLow IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
    AND i.target_uniprotID IS NOT NULL
),
AllProteinsAndPathways AS (
  SELECT DISTINCT UPPER(REGEXP_EXTRACT(p.uniprot_id, r'^[^-]+')) AS uniprot_id, pep.pathway_stable_id, pwy.name AS pathway_name
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS p
  JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS pep
    ON p.stable_id = pep.pe_stable_id
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` AS pwy
    ON pep.pathway_stable_id = pwy.stable_id
  WHERE pwy.species = 'Homo sapiens'
    AND pwy.lowest_level = TRUE
    AND pep.evidence_code = 'TAS'
    AND p.uniprot_id IS NOT NULL
),
TotalTargets AS (
  SELECT COUNT(DISTINCT uniprot_id) AS total_targets
  FROM SorafenibTargets
),
TotalProteins AS (
  SELECT COUNT(DISTINCT uniprot_id) AS total_proteins
  FROM AllProteinsAndPathways
),
TargetsInPathways AS (
  SELECT
    pathway_stable_id AS Pathway_ID,
    pathway_name AS Pathway_Name,
    COUNT(DISTINCT CASE WHEN s.uniprot_id IS NOT NULL THEN p.uniprot_id END) AS Targets_in_Pathway,
    COUNT(DISTINCT CASE WHEN s.uniprot_id IS NULL THEN p.uniprot_id END) AS Non_targets_in_Pathway
  FROM AllProteinsAndPathways p
  LEFT JOIN SorafenibTargets s
    ON p.uniprot_id = s.uniprot_id
  GROUP BY pathway_stable_id, pathway_name
),
Counts AS (
  SELECT
    Pathway_ID,
    Pathway_Name,
    A,
    B,
    C,
    D
  FROM (
    SELECT
      Pathway_ID,
      Pathway_Name,
      Targets_in_Pathway AS A,
      GREATEST(t.total_targets - Targets_in_Pathway, 0) AS B,
      Non_targets_in_Pathway AS C,
      GREATEST(tp.total_proteins - t.total_targets - Non_targets_in_Pathway, 0) AS D
    FROM TargetsInPathways
    CROSS JOIN TotalTargets t
    CROSS JOIN TotalProteins tp
  ) WHERE (A + B) > 0 AND (C + D) > 0 AND (A + C) > 0 AND (B + D) > 0
),
ChiSquared AS (
  SELECT
    Pathway_ID,
    Pathway_Name,
    A,
    B,
    C,
    D,
    ((A * D - B * C) * (A * D - B * C) * (A + B + C + D)) / NULLIF(((A + B) * (C + D) * (A + C) * (B + D)), 0) AS Chi_squared_statistic
  FROM Counts
)
SELECT
  Pathway_ID,
  Pathway_Name,
  A AS Targets_in_Pathway,
  B AS Targets_not_in_Pathway,
  C AS Non_targets_in_Pathway,
  D AS Non_targets_not_in_Pathway,
  ROUND(Chi_squared_statistic, 4) AS Chi_squared_statistic
FROM ChiSquared
WHERE Chi_squared_statistic IS NOT NULL
ORDER BY Chi_squared_statistic DESC
LIMIT 3;