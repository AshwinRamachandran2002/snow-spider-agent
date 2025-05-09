WITH sample_counts AS (
    SELECT "Super_Population", COUNT(*) AS Sample_Count
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    GROUP BY "Super_Population"
),
population_sizes AS (
    SELECT
        "Super_Population",
        CASE
            WHEN "Super_Population" = 'ASN' THEN
                (SELECT SUM(Sample_Count) FROM sample_counts WHERE "Super_Population" IN ('EAS', 'SAS'))
            ELSE
                SUM(Sample_Count)
        END AS Total_Population_Size
    FROM
        sample_counts
    WHERE
        "Super_Population" IN ('AFR', 'AMR', 'EUR', 'EAS', 'SAS') OR "Super_Population" = 'ASN'
    GROUP BY
        "Super_Population"
),
variant_data AS (
    SELECT
        COALESCE(VT, '') AS Variant_Type,
        ARRAY_SORT(ARRAY_COMPACT(ARRAY_CONSTRUCT(
            CASE WHEN "AFR_AF" >= 0.05 THEN 'AFR' ELSE NULL END,
            CASE WHEN "AMR_AF" >= 0.05 THEN 'AMR' ELSE NULL END,
            CASE WHEN "EUR_AF" >= 0.05 THEN 'EUR' ELSE NULL END,
            CASE WHEN "ASN_AF" >= 0.05 THEN 'ASN' ELSE NULL END
        ))) AS Super_Populations
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"
    WHERE
        "AF" >= 0.05
        AND "reference_name" NOT IN ('X', 'Y', 'MT')
),
variant_counts AS (
    SELECT
        ARRAY_TO_STRING(Super_Populations, ' & ') AS Super_Population_Combination,
        Variant_Type,
        COUNT(*) AS Number_of_Common_Autosomal_Variants
    FROM
        variant_data
    WHERE
        ARRAY_SIZE(Super_Populations) > 0
    GROUP BY
        Super_Population_Combination, Variant_Type
),
combination_sizes AS (
    SELECT
        vc.Super_Population_Combination,
        SUM(ps.Total_Population_Size) AS Total_Population_Size
    FROM
        variant_counts vc
    JOIN LATERAL
        FLATTEN(input => SPLIT(vc.Super_Population_Combination, ' & ')) sp
    JOIN
        population_sizes ps
    ON
        ps."Super_Population" = sp.VALUE::STRING
    GROUP BY
        vc.Super_Population_Combination
)
SELECT
    vc.Super_Population_Combination,
    cs.Total_Population_Size,
    vc.Variant_Type,
    cs.Total_Population_Size AS Sample_Count,
    vc.Number_of_Common_Autosomal_Variants
FROM
    variant_counts vc
LEFT JOIN
    combination_sizes cs
ON
    vc.Super_Population_Combination = cs.Super_Population_Combination
ORDER BY
    vc.Number_of_Common_Autosomal_Variants DESC NULLS LAST;