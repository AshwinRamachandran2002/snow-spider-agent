WITH targets AS (
    SELECT DISTINCT LOWER(i.target_uniprotID) AS uniprot_id
    FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
    JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e
        ON i.expID = e.expID
    WHERE LOWER(i.drugName) = 'sorafenib'
        AND LOWER(i.targetSpecies) = 'homo sapiens'
        AND e.exp_assayValueMedian <= 100
        AND (e.exp_assayValueLow <= 100 OR e.exp_assayValueLow IS NULL)
        AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),
pathway_entities AS (
    SELECT DISTINCT LOWER(p.uniprot_id) AS uniprot_id, pp.pathway_stable_id
    FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` p
    JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pp
        ON p.stable_id = pp.pe_stable_id
    WHERE pp.evidence_code = 'TAS'
),
pathways_of_interest AS (
    SELECT DISTINCT pv.stable_id AS pathway_stable_id
    FROM `isb-cgc-bq.reactome_versioned.pathway_v77` pv
    WHERE pv.species = 'Homo sapiens' AND pv.lowest_level = TRUE
),
entity_flags AS (
    SELECT pe.uniprot_id, pe.pathway_stable_id,
        CASE WHEN pe.uniprot_id IN (SELECT uniprot_id FROM targets) THEN 'Yes' ELSE 'No' END AS IsTarget
    FROM pathway_entities pe
    JOIN pathways_of_interest pv ON pe.pathway_stable_id = pv.pathway_stable_id
),
pathway_counts AS (
    SELECT
        pathway_stable_id,
        COUNTIF(IsTarget = 'Yes') AS target_count,
        COUNTIF(IsTarget = 'No') AS non_target_count,
        COUNT(*) AS pathway_total
    FROM entity_flags
    GROUP BY pathway_stable_id
),
totals AS (
    SELECT
        SUM(target_count) AS total_targets,
        SUM(non_target_count) AS total_non_targets,
        SUM(pathway_total) AS grand_total
    FROM pathway_counts
),
chi2_stats AS (
    SELECT
        pc.pathway_stable_id,
        pc.target_count,
        pc.non_target_count,
        pc.pathway_total,
        t.total_targets,
        t.total_non_targets,
        t.grand_total,
        SAFE_DIVIDE((pc.pathway_total * t.total_targets), t.grand_total) AS expected_target_count,
        SAFE_DIVIDE((pc.pathway_total * t.total_non_targets), t.grand_total) AS expected_non_target_count,
        (
            CASE
                WHEN SAFE_DIVIDE((pc.pathway_total * t.total_targets), t.grand_total) > 0 THEN
                    POW((pc.target_count - SAFE_DIVIDE((pc.pathway_total * t.total_targets), t.grand_total)), 2) / SAFE_DIVIDE((pc.pathway_total * t.total_targets), t.grand_total)
                ELSE 0
            END
            +
            CASE
                WHEN SAFE_DIVIDE((pc.pathway_total * t.total_non_targets), t.grand_total) > 0 THEN
                    POW((pc.non_target_count - SAFE_DIVIDE((pc.pathway_total * t.total_non_targets), t.grand_total)), 2) / SAFE_DIVIDE((pc.pathway_total * t.total_non_targets), t.grand_total)
                ELSE 0
            END
        ) AS chi_squared
    FROM pathway_counts pc
    CROSS JOIN totals t
),
top_3_pathways AS (
    SELECT pathway_stable_id
    FROM chi2_stats
    ORDER BY chi_squared DESC
    LIMIT 3
),
entity_grouping AS (
    SELECT ef.uniprot_id,
        ef.IsTarget,
        CASE WHEN ef.pathway_stable_id IN (SELECT pathway_stable_id FROM top_3_pathways) THEN 'Within Top 3 Pathways' ELSE 'Outside Top 3 Pathways' END AS `Group`
    FROM entity_flags ef
)
SELECT `Group`, IsTarget, COUNT(DISTINCT uniprot_id) AS Count
FROM entity_grouping
GROUP BY `Group`, IsTarget
ORDER BY CASE `Group` WHEN 'Within Top 3 Pathways' THEN 1 ELSE 2 END, IsTarget DESC;