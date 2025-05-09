WITH sorafenib_targets AS (
  SELECT DISTINCT i.targetID, i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e ON i.expID = e.expID
  WHERE LOWER(i.drugName) = 'sorafenib'
    AND LOWER(i.targetSpecies) = 'homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow <= 100 OR e.exp_assayValueLow IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
    AND i.target_uniprotID IS NOT NULL
),
all_physical_entities AS (
  SELECT DISTINCT pe.uniprot_id, pp.pathway_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
  JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pp ON pe.stable_id = pp.pe_stable_id
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` p ON pp.pathway_stable_id = p.stable_id
  WHERE pp.evidence_code = 'TAS'
    AND p.lowest_level = TRUE
    AND LOWER(p.species) = 'homo sapiens'
),
annotated_entities AS (
  SELECT
    pathway_stable_id,
    uniprot_id,
    CASE WHEN uniprot_id IN (SELECT target_uniprotID FROM sorafenib_targets) THEN 1 ELSE 0 END AS is_target
  FROM all_physical_entities
),
counts_per_pathway AS (
  SELECT
    pathway_stable_id,
    SUM(is_target) AS target_count,
    SUM(1 - is_target) AS non_target_count,
    COUNT(*) AS total_count
  FROM annotated_entities
  GROUP BY pathway_stable_id
),
total_counts AS (
  SELECT
    SUM(target_count) AS total_target_count,
    SUM(non_target_count) AS total_non_target_count,
    SUM(total_count) AS grand_total_count
  FROM counts_per_pathway
),
expected_counts_per_pathway AS (
  SELECT
    cp.pathway_stable_id,
    cp.target_count,
    cp.non_target_count,
    cp.total_count,
    tc.total_target_count,
    tc.total_non_target_count,
    tc.grand_total_count,
    (cp.total_count * tc.total_target_count) / tc.grand_total_count AS expected_target_count,
    (cp.total_count * tc.total_non_target_count) / tc.grand_total_count AS expected_non_target_count
  FROM counts_per_pathway cp
  CROSS JOIN total_counts tc
),
chi_squared_per_pathway AS (
  SELECT
    pathway_stable_id,
    target_count,
    non_target_count,
    expected_target_count,
    expected_non_target_count,
    ((target_count - expected_target_count)*(target_count - expected_target_count))/expected_target_count +
    ((non_target_count - expected_non_target_count)*(non_target_count - expected_non_target_count))/expected_non_target_count AS chi_squared
  FROM expected_counts_per_pathway
  WHERE expected_target_count > 0 AND expected_non_target_count > 0
),
top_three_pathways AS (
  SELECT pathway_stable_id
  FROM chi_squared_per_pathway
  ORDER BY chi_squared DESC
  LIMIT 3
),
counts_within_top3 AS (
  SELECT 
    'Within Top 3 Pathways' AS `Group`,
    CASE WHEN is_target = 1 THEN 'Yes' ELSE 'No' END AS IsTarget,
    COUNT(*) AS `Count`
  FROM annotated_entities
  WHERE pathway_stable_id IN (SELECT pathway_stable_id FROM top_three_pathways)
  GROUP BY `Group`, IsTarget
),
counts_outside_top3 AS (
  SELECT 
    'Outside Top 3 Pathways' AS `Group`,
    CASE WHEN is_target = 1 THEN 'Yes' ELSE 'No' END AS IsTarget,
    COUNT(*) AS `Count`
  FROM annotated_entities
  WHERE pathway_stable_id NOT IN (SELECT pathway_stable_id FROM top_three_pathways)
  GROUP BY `Group`, IsTarget
)
SELECT *
FROM counts_within_top3
UNION ALL
SELECT *
FROM counts_outside_top3
ORDER BY `Group`, IsTarget;