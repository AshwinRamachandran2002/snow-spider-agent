WITH variant_calls AS (
    SELECT
        v."start",
        v."end",
        s.value:"call_set_name"::STRING AS "Sample_ID",
        s.value:"genotype"::VARIANT AS "Genotype"
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
    CROSS JOIN LATERAL FLATTEN(input => v."call") s
    WHERE v."reference_name" = '12'
),
sample_info AS (
    SELECT
        "Sample" AS "Sample_ID",
        "Super_Population"
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    WHERE "Super_Population" IN ('AFR', 'EUR')
),
genotype_counts AS (
    SELECT
        vc."start",
        vc."end",
        si."Super_Population" AS "Phenotype",
        SUM(
            CASE WHEN vc."Genotype"[0]::NUMBER = 0 THEN 1 ELSE 0 END +
            CASE WHEN vc."Genotype"[1]::NUMBER = 0 THEN 1 ELSE 0 END
        ) AS "Ref_Allele_Count",
        SUM(
            CASE WHEN vc."Genotype"[0]::NUMBER != 0 THEN 1 ELSE 0 END +
            CASE WHEN vc."Genotype"[1]::NUMBER != 0 THEN 1 ELSE 0 END
        ) AS "Alt_Allele_Count"
    FROM variant_calls vc
    JOIN sample_info si ON vc."Sample_ID" = si."Sample_ID"
    GROUP BY vc."start", vc."end", si."Super_Population"
),
allele_counts AS (
    SELECT
        "start",
        "end",
        SUM(CASE WHEN "Phenotype" = 'AFR' THEN "Ref_Allele_Count" ELSE 0 END) AS "Case_Ref_Allele",
        SUM(CASE WHEN "Phenotype" = 'AFR' THEN "Alt_Allele_Count" ELSE 0 END) AS "Case_Alt_Allele",
        SUM(CASE WHEN "Phenotype" = 'EUR' THEN "Ref_Allele_Count" ELSE 0 END) AS "Control_Ref_Allele",
        SUM(CASE WHEN "Phenotype" = 'EUR' THEN "Alt_Allele_Count" ELSE 0 END) AS "Control_Alt_Allele"
    FROM genotype_counts
    GROUP BY "start", "end"
),
chi_squared_calculations AS (
    SELECT
        "start",
        "end",
        "Case_Ref_Allele",
        "Case_Alt_Allele",
        "Control_Ref_Allele",
        "Control_Alt_Allele",
        ("Case_Ref_Allele" + "Control_Ref_Allele") AS "Total_Ref_Allele",
        ("Case_Alt_Allele" + "Control_Alt_Allele") AS "Total_Alt_Allele",
        ("Case_Ref_Allele" + "Case_Alt_Allele" + "Control_Ref_Allele" + "Control_Alt_Allele") AS "Total_Alleles",
        -- Expected counts
        (("Total_Ref_Allele" * ("Case_Ref_Allele" + "Case_Alt_Allele")) / "Total_Alleles") AS "E_Case_Ref_Allele",
        (("Total_Alt_Allele" * ("Case_Ref_Allele" + "Case_Alt_Allele")) / "Total_Alleles") AS "E_Case_Alt_Allele",
        (("Total_Ref_Allele" * ("Control_Ref_Allele" + "Control_Alt_Allele")) / "Total_Alleles") AS "E_Control_Ref_Allele",
        (("Total_Alt_Allele" * ("Control_Ref_Allele" + "Control_Alt_Allele")) / "Total_Alleles") AS "E_Control_Alt_Allele"
    FROM allele_counts
),
chi_squared_scores AS (
    SELECT
        "start",
        "end",
        "Case_Ref_Allele",
        "Case_Alt_Allele",
        "Control_Ref_Allele",
        "Control_Alt_Allele",
        "E_Case_Ref_Allele",
        "E_Case_Alt_Allele",
        "E_Control_Ref_Allele",
        "E_Control_Alt_Allele",
        -- Check expected counts
        CASE
            WHEN "E_Case_Ref_Allele" >= 5 AND "E_Case_Alt_Allele" >= 5 AND
                 "E_Control_Ref_Allele" >= 5 AND "E_Control_Alt_Allele" >= 5
            THEN TRUE
            ELSE FALSE
        END AS "Valid_Chi_Squared",
        -- Chi-squared with Yates's correction, rounded to four decimal places
        ROUND(
            CASE WHEN "E_Case_Ref_Allele" > 0
                THEN POWER((ABS("Case_Ref_Allele" - "E_Case_Ref_Allele") - 0.5),2) / "E_Case_Ref_Allele"
                ELSE 0 END +
            CASE WHEN "E_Case_Alt_Allele" > 0
                THEN POWER((ABS("Case_Alt_Allele" - "E_Case_Alt_Allele") - 0.5),2) / "E_Case_Alt_Allele"
                ELSE 0 END +
            CASE WHEN "E_Control_Ref_Allele" > 0
                THEN POWER((ABS("Control_Ref_Allele" - "E_Control_Ref_Allele") - 0.5),2) / "E_Control_Ref_Allele"
                ELSE 0 END +
            CASE WHEN "E_Control_Alt_Allele" > 0
                THEN POWER((ABS("Control_Alt_Allele" - "E_Control_Alt_Allele") - 0.5),2) / "E_Control_Alt_Allele"
                ELSE 0 END
        , 4) AS "Chi_Squared_Score"
    FROM chi_squared_calculations
)
SELECT
    "start",
    "end",
    "Chi_Squared_Score"
FROM chi_squared_scores
WHERE "Valid_Chi_Squared" = TRUE AND "Chi_Squared_Score" >= 29.7168
ORDER BY "Chi_Squared_Score" DESC NULLS LAST
;