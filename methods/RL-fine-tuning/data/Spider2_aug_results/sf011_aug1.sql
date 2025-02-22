-- Task: Retrieve the block group ID, census value, state county tract ID, and block group polygon for all block groups in New York State using 2021 ACS data.
SELECT
    CG."BlockGroupID",
    FCV."CensusValue",
    CG."StateCountyTractID",
    CG."BlockGroupPolygon"
FROM
    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Dim_CensusGeography" CG
JOIN
    CENSUS_GALAXY__ZIP_CODE_TO_BLOCK_GROUP_SAMPLE.PUBLIC."Fact_CensusValues_ACS2021" FCV
    ON CG."BlockGroupID" = FCV."BlockGroupID"
WHERE
    CG."StateAbbrev" = 'NY'
    AND FCV."MetricID" = 'B01003_001E';