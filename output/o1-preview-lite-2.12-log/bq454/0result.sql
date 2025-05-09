WITH population_sizes AS (
  SELECT
    Super_Population,
    COUNT(DISTINCT Sample) AS Total_Population_Size
  FROM `genomics-public-data.1000_genomes.sample_info`
  GROUP BY Super_Population
),
sample_counts AS (
  SELECT
    Super_Population,
    COUNT(DISTINCT Sample) AS Sample_Count
  FROM `genomics-public-data.1000_genomes.sample_info`
  WHERE In_Final_Phase_Variant_Calling = TRUE
  GROUP BY Super_Population
),
super_population_info AS (
  SELECT
    Super_Population,
    Total_Population_Size,
    Sample_Count
  FROM population_sizes
  JOIN sample_counts USING (Super_Population)
),
variants_info AS (
  SELECT
    v.reference_name,
    v.start,
    v.reference_bases,
    v.alternate_bases[OFFSET(0)] AS alternate_base,
    v.VT AS Variant_Type,
    CONCAT(
      v.reference_name, ':', CAST(v.start AS STRING), ':', v.reference_bases, '>', v.alternate_bases[OFFSET(0)]
    ) AS variant_id
  FROM `genomics-public-data.1000_genomes.variants` AS v
  WHERE
    v.reference_name IN ('1','2','3','4','5','6','7','8','9','10',
                         '11','12','13','14','15','16','17','18','19','20','21','22')
    AND v.AF >= 0.05
),
variant_super_pops AS (
  SELECT
    vi.variant_id,
    vi.Variant_Type,
    si.Super_Population
  FROM variants_info AS vi
  JOIN `genomics-public-data.1000_genomes.variants` AS v
    ON vi.variant_id = CONCAT(
      v.reference_name, ':', CAST(v.start AS STRING), ':', v.reference_bases, '>', v.alternate_bases[OFFSET(0)]
    )
  JOIN UNNEST(v.call) AS c
  ON TRUE
  JOIN `genomics-public-data.1000_genomes.sample_info` AS si
    ON c.call_set_name = si.Sample
  WHERE
    c.genotype[SAFE_OFFSET(0)] != 0 OR c.genotype[SAFE_OFFSET(1)] != 0
),
variant_super_pops_grouped AS (
  SELECT
    variant_id,
    Variant_Type,
    ARRAY_AGG(DISTINCT Super_Population ORDER BY Super_Population) AS super_pops
  FROM variant_super_pops
  GROUP BY variant_id, Variant_Type
),
common_variants AS (
  SELECT
    ARRAY_TO_STRING(super_pops, ',') AS Super_Populations,
    Variant_Type,
    COUNT(*) AS Number_of_Common_Autosomal_Variants
  FROM variant_super_pops_grouped
  GROUP BY Super_Populations, Variant_Type
),
super_pops_expanded AS (
  SELECT
    cv.Super_Populations,
    cv.Variant_Type,
    cv.Number_of_Common_Autosomal_Variants,
    sp AS Super_Population
  FROM common_variants AS cv
  JOIN UNNEST(SPLIT(cv.Super_Populations, ',')) AS sp
),
super_pop_counts AS (
  SELECT
    cv.Super_Populations,
    cv.Variant_Type,
    cv.Number_of_Common_Autosomal_Variants,
    SUM(spi.Total_Population_Size) AS Total_Population_Size,
    SUM(spi.Sample_Count) AS Sample_Count
  FROM super_pops_expanded AS cv
  JOIN super_population_info AS spi
    ON cv.Super_Population = spi.Super_Population
  GROUP BY cv.Super_Populations, cv.Variant_Type, cv.Number_of_Common_Autosomal_Variants
)
SELECT
  Super_Populations,
  Total_Population_Size,
  Variant_Type,
  Sample_Count,
  Number_of_Common_Autosomal_Variants
FROM super_pop_counts
ORDER BY Super_Populations, Variant_Type;