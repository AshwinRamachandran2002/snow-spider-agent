WITH candidate_activities AS (
    SELECT
        a.activity_id,
        a.assay_id,
        a.standard_type,
        a.molregno,
        CAST(a.standard_value AS FLOAT64) AS standard_value,
        a.standard_relation,
        CAST(a.pchembl_value AS FLOAT64) AS pchembl_value,
        a.doc_id,
        CAST(cp.heavy_atoms AS INT64) AS heavy_atoms
    FROM `bigquery-public-data.ebi_chembl.activities` AS a
    JOIN `bigquery-public-data.ebi_chembl.compound_properties` AS cp
        ON a.molregno = cp.molregno
    WHERE a.standard_value IS NOT NULL
      AND CAST(a.pchembl_value AS FLOAT64) > 10
      AND CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
),
activity_counts AS (
    SELECT
        assay_id,
        molregno,
        COUNT(*) AS activity_count
    FROM candidate_activities
    GROUP BY assay_id, molregno
),
duplicate_counts AS (
    SELECT
        assay_id,
        molregno,
        standard_value,
        standard_relation,
        COUNT(*) AS duplicate_count
    FROM candidate_activities
    GROUP BY assay_id, molregno, standard_value, standard_relation
),
filtered_activities AS (
    SELECT ca.*
    FROM candidate_activities AS ca
    JOIN activity_counts AS ac
        ON ca.assay_id = ac.assay_id AND ca.molregno = ac.molregno
    JOIN duplicate_counts AS dc
        ON ca.assay_id = dc.assay_id AND ca.molregno = dc.molregno
           AND ca.standard_value = dc.standard_value AND ca.standard_relation = dc.standard_relation
    WHERE ac.activity_count < 5
      AND dc.duplicate_count < 2
),
docs_publication_dates AS (
    SELECT
        d.doc_id,
        CAST(d.year AS INT64) AS year,
        d.journal,
        CAST(d.first_page AS INT64) AS first_page,
        ROW_NUMBER() OVER (
            PARTITION BY d.journal, CAST(d.year AS INT64)
            ORDER BY CAST(d.first_page AS INT64)
        ) AS doc_rank,
        COUNT(*) OVER (PARTITION BY d.journal, CAST(d.year AS INT64)) AS total_docs
    FROM `bigquery-public-data.ebi_chembl.docs` AS d
    WHERE d.year IS NOT NULL AND d.year != ''
      AND d.first_page IS NOT NULL AND REGEXP_CONTAINS(d.first_page, r'^\d+$')
),
publication_dates AS (
    SELECT
        doc_id,
        DATE(
            IFNULL(year, 1970),
            CAST(
                IFNULL(
                    FLOOR(
                        (CASE WHEN total_docs > 1 THEN (doc_rank - 1)/(total_docs - 1) ELSE 0 END) * 11
                    ), 0
                ) + 1 AS INT64
            ),
            CAST(
                MOD(
                    CAST(
                        FLOOR(
                            (CASE WHEN total_docs > 1 THEN (doc_rank - 1)/(total_docs - 1) ELSE 0 END) * 308
                        ) AS INT64
                    ), 28
                ) + 1 AS INT64
            )
        ) AS publication_date
    FROM docs_publication_dates
),
canonical_smiles AS (
    SELECT molregno, canonical_smiles
    FROM `bigquery-public-data.ebi_chembl.compound_structures`
    WHERE canonical_smiles IS NOT NULL AND canonical_smiles != ''
),
molecule_data AS (
    SELECT
        fa.*,
        pd.publication_date,
        cs.canonical_smiles
    FROM filtered_activities AS fa
    LEFT JOIN publication_dates AS pd
        ON fa.doc_id = pd.doc_id
    LEFT JOIN canonical_smiles AS cs
        ON fa.molregno = cs.molregno
),
molecule_pairs AS (
    SELECT
        md1.assay_id,
        md1.standard_type,
        md1.molregno AS molregno1,
        md1.activity_id AS activity_id1,
        md1.standard_value AS standard_value1,
        md1.standard_relation AS standard_relation1,
        md1.pchembl_value AS pchembl_value1,
        md1.doc_id AS doc_id1,
        md1.heavy_atoms AS heavy_atoms1,
        md1.publication_date AS publication_date1,
        md1.canonical_smiles AS canonical_smiles1,
        md2.molregno AS molregno2,
        md2.activity_id AS activity_id2,
        md2.standard_value AS standard_value2,
        md2.standard_relation AS standard_relation2,
        md2.pchembl_value AS pchembl_value2,
        md2.doc_id AS doc_id2,
        md2.heavy_atoms AS heavy_atoms2,
        md2.publication_date AS publication_date2,
        md2.canonical_smiles AS canonical_smiles2
    FROM molecule_data AS md1
    JOIN molecule_data AS md2
        ON md1.assay_id = md2.assay_id
        AND md1.standard_type = md2.standard_type
        AND md1.molregno < md2.molregno
)
SELECT
    GREATEST(mp.heavy_atoms1, mp.heavy_atoms2) AS Max_heavy_atom_count,
    FORMAT_DATE('%Y-%m-%d', GREATEST(mp.publication_date1, mp.publication_date2)) AS Latest_publication_date,
    GREATEST(CAST(mp.doc_id1 AS INT64), CAST(mp.doc_id2 AS INT64)) AS Highest_doc_id,
    CASE
        WHEN mp.standard_relation1 = '=' AND mp.standard_relation2 = '=' THEN
            CASE
                WHEN mp.standard_value1 > mp.standard_value2 THEN 'decrease'
                WHEN mp.standard_value1 < mp.standard_value2 THEN 'increase'
                WHEN mp.standard_value1 = mp.standard_value2 THEN 'no-change'
                ELSE 'unknown'
            END
        ELSE 'unknown'
    END AS Change_classification,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(mp.activity_id1, mp.activity_id2)))) AS UUID
FROM molecule_pairs AS mp
LIMIT 100