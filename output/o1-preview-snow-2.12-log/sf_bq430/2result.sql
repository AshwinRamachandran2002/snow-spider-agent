WITH highest_doc AS (
    SELECT MAX("doc_id") AS highest_doc_id FROM EBI_CHEMBL.EBI_CHEMBL."DOCS"
),

filtered_activities AS (
    SELECT 
        a."activity_id", a."assay_id", a."molregno", ROUND(TRY_TO_NUMBER(a."standard_value"), 4) AS standard_value, a."pchembl_value", c."heavy_atoms", s."canonical_smiles", a."standard_type", asy."doc_id"
    FROM EBI_CHEMBL.EBI_CHEMBL."ACTIVITIES" a
    JOIN EBI_CHEMBL.EBI_CHEMBL."COMPOUND_PROPERTIES" c ON a."molregno" = c."molregno"
    JOIN EBI_CHEMBL.EBI_CHEMBL."COMPOUND_STRUCTURES" s ON a."molregno" = s."molregno"
    JOIN EBI_CHEMBL.EBI_CHEMBL."ASSAYS" asy ON a."assay_id" = asy."assay_id"
    WHERE 
        c."heavy_atoms" BETWEEN 10 AND 15
        AND a."standard_value" IS NOT NULL
        AND a."pchembl_value" > 10
        AND TRY_TO_NUMBER(a."standard_value") IS NOT NULL
        AND a."standard_relation" = '='
),

activities_with_counts AS (
    SELECT 
        fa.*,
        COUNT(*) OVER (PARTITION BY fa."assay_id", fa."molregno") AS activity_count,
        COUNT(*) OVER (PARTITION BY fa."assay_id", fa."molregno", fa."standard_type") AS duplicate_count
    FROM filtered_activities fa
),

activities_filtered AS (
    SELECT af.*
    FROM activities_with_counts af
    WHERE activity_count < 5 AND duplicate_count < 2
),

documents AS (
    SELECT DISTINCT d."doc_id", d."journal", d."year", d."first_page"
    FROM EBI_CHEMBL.EBI_CHEMBL."DOCS" d
    WHERE d."year" IS NOT NULL AND d."first_page" IS NOT NULL AND TRY_TO_NUMBER(d."first_page") IS NOT NULL
),

doc_with_rank AS (
    SELECT 
        d.*,
        RANK() OVER (PARTITION BY d."journal", d."year" ORDER BY TRY_TO_NUMBER(d."first_page")) AS doc_rank,
        COUNT(*) OVER (PARTITION BY d."journal", d."year") AS total_docs
    FROM documents d
),

doc_with_date AS (
    SELECT 
        dwr."doc_id",
        dwr."journal",
        dwr."year",
        dwr.doc_rank,
        dwr.total_docs,
        FLOOR( ((dwr.doc_rank - 1) / NULLIF(dwr.total_docs - 1, 0)) * 11 ) + 1 AS synthetic_month,
        MOD( FLOOR( ((dwr.doc_rank - 1) / NULLIF(dwr.total_docs - 1, 0)) * 308 ), 28 ) + 1 AS synthetic_day
    FROM doc_with_rank dwr
),

activities_with_doc AS (
    SELECT af.*, dwd."journal", dwd."year", dwd.synthetic_month, dwd.synthetic_day, dwd.doc_rank
    FROM activities_filtered af
    LEFT JOIN doc_with_date dwd ON af."doc_id" = dwd."doc_id"
),

activity_pairs AS (
    SELECT 
        awd1."activity_id" AS activity_id1, awd1."molregno" AS molregno1, awd1."heavy_atoms" AS heavy_atoms1, awd1.standard_value AS standard_value1, awd1."canonical_smiles" AS canonical_smiles1,
        awd1."journal" AS journal1, awd1."year" AS year1, awd1.synthetic_month AS synthetic_month1, awd1.synthetic_day AS synthetic_day1,
        awd2."activity_id" AS activity_id2, awd2."molregno" AS molregno2, awd2."heavy_atoms" AS heavy_atoms2, awd2.standard_value AS standard_value2, awd2."canonical_smiles" AS canonical_smiles2,
        awd2."journal" AS journal2, awd2."year" AS year2, awd2.synthetic_month AS synthetic_month2, awd2.synthetic_day AS synthetic_day2,
        awd1."assay_id", awd1."standard_type"
    FROM activities_with_doc awd1
    JOIN activities_with_doc awd2 ON
        awd1."assay_id" = awd2."assay_id"
        AND awd1."standard_type" = awd2."standard_type"
        AND awd1."molregno" <> awd2."molregno"
        AND awd1."activity_id" < awd2."activity_id"
)

SELECT 
    GREATEST(ap.heavy_atoms1, ap.heavy_atoms2) AS max_heavy_atom_count,
    CASE WHEN TO_DATE(CONCAT(ap.year1, '-', ap.synthetic_month1, '-', ap.synthetic_day1), 'YYYY-MM-DD') > TO_DATE(CONCAT(ap.year2, '-', ap.synthetic_month2, '-', ap.synthetic_day2), 'YYYY-MM-DD') 
         THEN TO_DATE(CONCAT(ap.year1, '-', ap.synthetic_month1, '-', ap.synthetic_day1), 'YYYY-MM-DD')
         ELSE TO_DATE(CONCAT(ap.year2, '-', ap.synthetic_month2, '-', ap.synthetic_day2), 'YYYY-MM-DD')
    END AS latest_publication_date,
    (SELECT highest_doc_id FROM highest_doc) AS highest_doc_id,
    CASE
        WHEN ap.standard_value1 > ap.standard_value2 THEN 'decrease'
        WHEN ap.standard_value1 < ap.standard_value2 THEN 'increase'
        ELSE 'no-change'
    END AS change_classification,
    UPPER(HEX_ENCODE(MD5(TO_JSON(OBJECT_CONSTRUCT(ap.activity_id1, ap.canonical_smiles1, ap.activity_id2, ap.canonical_smiles2))))) AS mmp_delta_uuid
FROM activity_pairs ap
LIMIT 100;