--First step - create a new table reshaped with the rating columns as described:

CREATE TABLE PD_2023_06_STEP1 AS
(
WITH MOBILE_SCORES AS (
    SELECT CUSTOMER_ID
        , REPLACE(MOB_METRIC, 'MOBILE_APP___', '') MOB_METRIC_NEW
        , MOB_SCORE
          FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK06_DSB_CUSTOMER_SURVEY
        UNPIVOT( MOB_SCORE FOR MOB_METRIC IN (MOBILE_APP___EASE_OF_USE
                                            , MOBILE_APP___EASE_OF_ACCESS
                                            , MOBILE_APP___NAVIGATION
                                            , MOBILE_APP___LIKELIHOOD_TO_RECOMMEND
                                            , MOBILE_APP___OVERALL_RATING)
    ))
    , ONLINE_SCORES AS (
    SELECT CUSTOMER_ID
        , REPLACE(ONLINE_METRIC, 'ONLINE_INTERFACE___', '') ONLINE_METRIC_NEW
        , ONLINE_SCORE
          FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK06_DSB_CUSTOMER_SURVEY
        UNPIVOT( ONLINE_SCORE FOR ONLINE_METRIC IN (ONLINE_INTERFACE___EASE_OF_USE
                                            , ONLINE_INTERFACE___EASE_OF_ACCESS
                                            , ONLINE_INTERFACE___NAVIGATION
                                            , ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND
                                            , ONLINE_INTERFACE___OVERALL_RATING)
    ))
SELECT MOBILE_SCORES.CUSTOMER_ID
        , MOB_METRIC_NEW
        , MOB_SCORE
        , ONLINE_METRIC_NEW
        , ONLINE_SCORE
FROM MOBILE_SCORES
JOIN ONLINE_SCORES
    ON MOBILE_SCORES.CUSTOMER_ID = ONLINE_SCORES.CUSTOMER_ID
    AND MOBILE_SCORES.MOB_METRIC_NEW = ONLINE_SCORES.ONLINE_METRIC_NEW
WHERE MOB_METRIC_NEW != 'OVERALL_RATING'
);

SELECT * FROM PD_2023_06_STEP1;

--Second step - find average score from each customer for each device, allocate Preference values, then create summary table

SELECT PREFERENCE
    , ROUND(
        ( COUNT(DISTINCT CUSTOMER_ID) /  (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM PD_2023_06_STEP1) ) 
        *100, 1) PERCENTAGE_OF_TOTAL
FROM (
        SELECT CUSTOMER_ID
            , AVG(MOB_SCORE) MOB_AVG_SCORE
            , AVG(ONLINE_SCORE) ONLINE_AVG_SCORE
            , (MOB_AVG_SCORE - ONLINE_AVG_SCORE) SCORE_DIFF
            , (CASE
                WHEN SCORE_DIFF >= 2 THEN 'Mobile App Superfan'
                WHEN SCORE_DIFF < 2 AND SCORE_DIFF >=1 THEN 'Mobile App Fan'
                WHEN SCORE_DIFF <1 AND SCORE_DIFF > -1 THEN 'Neutral'
                WHEN SCORE_DIFF <= -1 AND SCORE_DIFF > -2 THEN 'Online Interface Fan'
                WHEN SCORE_DIFF <= -2 THEN 'Online Interface Superfan'
                END
            ) PREFERENCE
        FROM PD_2023_06_STEP1
        GROUP BY CUSTOMER_ID
)
GROUP BY PREFERENCE
ORDER BY PERCENTAGE_OF_TOTAL DESC;