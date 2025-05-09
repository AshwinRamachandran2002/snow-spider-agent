WITH heavy_mols AS (
    SELECT "molregno", "heavy_atoms"
    FROM EBI_CHEMBL.EBI_CHEMBL.COMPOUND_PROPERTIES
    WHERE "heavy_atoms" BETWEEN 10 AND 15
),
eligible_activities AS (
    SELECT "activity_id", "assay_id", "molregno", "standard_type", "standard_value"::DOUBLE PRECISION AS "standard_value",
           "standard_relation", "pchembl_value", "doc_id"
    FROM EBI_CHEMBL.EBI_CHEMBL.ACTIVITIES
    WHERE "pchembl_value" > 10 AND
          "standard_value" IS NOT NULL AND
          "molregno" IN (SELECT "molregno" FROM heavy_mols)
),
assay_activity_counts AS (
    SELECT "assay_id", COUNT(*) AS "activity_count"
    FROM eligible_activities
    GROUP BY "assay_id"
    HAVING COUNT(*) < 5
),
assay_mol_counts AS (
    SELECT "assay_id", "molregno", COUNT(*) AS "mol_activity_count"
    FROM eligible_activities
    GROUP BY "assay_id", "molregno"
    HAVING COUNT(*) < 2
),
filtered_activities AS (
    SELECT ea.*
    FROM eligible_activities ea
    INNER JOIN assay_activity_counts aac ON ea."assay_id" = aac."assay_id"
    INNER JOIN assay_mol_counts amc ON ea."assay_id" = amc."assay_id" AND ea."molregno" = amc."molregno"
    WHERE ea."standard_relation" IS NOT NULL
),
paired_activities AS (
    SELECT 
        fa1."assay_id", fa1."standard_type", 
        fa1."activity_id" AS "activity_id1", fa1."molregno" AS "molregno1", fa1."standard_value" AS "standard_value1", fa1."standard_relation" AS "standard_relation1", fa1."pchembl_value" AS "pchembl_value1", fa1."doc_id" AS "doc_id1",
        fa2."activity_id" AS "activity_id2", fa2."molregno" AS "molregno2", fa2."standard_value" AS "standard_value2", fa2."standard_relation" AS "standard_relation2", fa2."pchembl_value" AS "pchembl_value2", fa2."doc_id" AS "doc_id2"
    FROM filtered_activities fa1
    INNER JOIN filtered_activities fa2
        ON fa1."assay_id" = fa2."assay_id"
        AND fa1."standard_type" = fa2."standard_type"
        AND fa1."molregno" < fa2."molregno"
),
paired_activities_with_props AS (
    SELECT
        pa.*,
        hm1."heavy_atoms" AS "heavy_atoms1",
        hm2."heavy_atoms" AS "heavy_atoms2"
    FROM paired_activities pa
    INNER JOIN heavy_mols hm1 ON pa."molregno1" = hm1."molregno"
    INNER JOIN heavy_mols hm2 ON pa."molregno2" = hm2."molregno"
),
compound_structures AS (
    SELECT "molregno", "canonical_smiles"
    FROM EBI_CHEMBL.EBI_CHEMBL.COMPOUND_STRUCTURES
),
paired_activities_with_structures AS (
    SELECT
        paws.*,
        cs1."canonical_smiles" AS "smiles1",
        cs2."canonical_smiles" AS "smiles2"
    FROM paired_activities_with_props paws
    INNER JOIN compound_structures cs1 ON paws."molregno1" = cs1."molregno"
    INNER JOIN compound_structures cs2 ON paws."molregno2" = cs2."molregno"
),
molecule_docs AS (
    SELECT "molregno", MAX("doc_id") AS "max_doc_id"
    FROM EBI_CHEMBL.EBI_CHEMBL.ACTIVITIES
    GROUP BY "molregno"
),
docs_with_rank AS (
    SELECT 
        d."doc_id",
        d."journal",
        d."year",
        d."first_page",
        TRY_TO_NUMBER(d."first_page") AS "first_page_num",
        ROW_NUMBER() OVER (PARTITION BY d."journal", d."year" ORDER BY TRY_TO_NUMBER(d."first_page")) AS "doc_rank",
        COUNT(*) OVER (PARTITION BY d."journal", d."year") AS "total_docs"
    FROM EBI_CHEMBL.EBI_CHEMBL.DOCS d
    WHERE d."journal" IS NOT NULL AND d."year" IS NOT NULL AND d."first_page" IS NOT NULL
),
docs_with_percent_rank AS (
    SELECT
        *,
        CASE WHEN "total_docs" > 1 THEN ("doc_rank" - 1)::DOUBLE PRECISION / ("total_docs" - 1)::DOUBLE PRECISION ELSE 0 END AS "percent_rank"
    FROM docs_with_rank
),
docs_with_date AS (
    SELECT
        *,
        FLOOR("percent_rank" * 11) + 1 AS "month",
        MOD(FLOOR("percent_rank" * 308),28) + 1 AS "day"
    FROM docs_with_percent_rank
),
molecule_docs_with_date AS (
    SELECT
        md."molregno",
        md."max_doc_id" AS "doc_id",
        dwd."journal",
        dwd."year",
        dwd."first_page",
        dwd."percent_rank",
        dwd."month",
        dwd."day",
        TO_DATE(TO_VARCHAR(dwd."year") || '-' || TO_VARCHAR(dwd."month") || '-' || TO_VARCHAR(dwd."day"), 'YYYY-MM-DD') AS "publication_date"
    FROM molecule_docs md
    INNER JOIN docs_with_date dwd ON md."max_doc_id" = dwd."doc_id"
)
SELECT
    GREATEST(paws."heavy_atoms1", paws."heavy_atoms2") AS "max_heavy_atom_count",
    GREATEST(mdw1."publication_date", mdw2."publication_date") AS "latest_publication_date",
    GREATEST(paws."doc_id1", paws."doc_id2") AS "highest_doc_id",
    CASE 
        WHEN paws."standard_value1" > paws."standard_value2" AND paws."standard_relation1" IN ('=', '<', '<=') AND paws."standard_relation2" IN ('=', '>', '>=') THEN 'decrease'
        WHEN paws."standard_value1" < paws."standard_value2" AND paws."standard_relation1" IN ('=', '>', '>=') AND paws."standard_relation2" IN ('=', '<', '<=') THEN 'increase'
        WHEN paws."standard_value1" = paws."standard_value2" AND paws."standard_relation1" = '=' AND paws."standard_relation2" = '=' THEN 'no-change'
        ELSE NULL
    END AS "change_classification",
    UPPER(MD5(TO_JSON(OBJECT_CONSTRUCT('activity_id1', paws."activity_id1", 'activity_id2', paws."activity_id2")))) AS "mmp_delta_uuid"
FROM
    paired_activities_with_structures paws
LEFT JOIN molecule_docs_with_date mdw1 ON paws."molregno1" = mdw1."molregno"
LEFT JOIN molecule_docs_with_date mdw2 ON paws."molregno2" = mdw2."molregno"
WHERE paws."standard_relation1" IS NOT NULL AND paws."standard_relation2" IS NOT NULL