--Input data source

CREATE TABLE FOODIE_FI_SUMMARY AS
SELECT PLANS.PLAN_ID
    , PLAN_NAME
    , PRICE
    , CUSTOMER_ID
    , START_DATE
FROM TIL_PLAYGROUND.CS3_FOODIE_FI.PLANS PLANS
    JOIN TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS SUBS
    ON PLANS.PLAN_ID = SUBS.PLAN_ID;

--View info to write up short customer journey summaries

SELECT * FROM FOODIE_FI_SUMMARY
WHERE CUSTOMER_ID IN(1, 2, 11, 13, 15, 16, 18, 19);

--Total Number of Customers (all time): 1000

SELECT COUNT(DISTINCT CUSTOMER_ID)
FROM FOODIE_FI_SUMMARY;

--Monthly distribution of trial start dates

SELECT DATE_TRUNC('MONTH', START_DATE) MONTH
    , COUNT(*) TRIALS_STARTED 
FROM FOODIE_FI_SUMMARY
WHERE PLAN_ID = 0
GROUP BY MONTH
ORDER BY MONTH;

--Plans starting after 2020

SELECT PLAN_NAME
    , COUNT(DISTINCT CUSTOMER_ID) PLANS_STARTED
FROM FOODIE_FI_SUMMARY
WHERE YEAR(START_DATE) > 2020
GROUP BY PLAN_NAME;

--Number and % of Customers who have churned (30.7%)

SELECT COUNT(DISTINCT CUSTOMER_ID) N_CHURNED_CUSTOMERS
    , (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM FOODIE_FI_SUMMARY) N_TOTAL_CUSTOMERS
    , ROUND((N_CHURNED_CUSTOMERS / N_TOTAL_CUSTOMERS) *100, 1) PERCENTAGE_CHURNED
FROM FOODIE_FI_SUMMARY
WHERE PLAN_ID = 4;

--What % of Customers churned immediately after their trial (9.2%)

SELECT COUNT(DISTINCT CUSTOMER_ID) N_CUSTOMERS_IMMEDIATE_CHURN
    , (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM FOODIE_FI_SUMMARY) N_TOTAL_CUSTOMERS
    , ROUND((N_CUSTOMERS_IMMEDIATE_CHURN / N_TOTAL_CUSTOMERS) *100, 1) PERCENTAGE_CHURNED
FROM (
    SELECT CUSTOMER_ID
        , MIN(START_DATE)
        , PLAN_NAME
        , ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY START_DATE ASC) AS RN
    FROM FOODIE_FI_SUMMARY
    WHERE PLAN_ID>0
    GROUP BY CUSTOMER_ID, START_DATE, PLAN_NAME
    ORDER BY CUSTOMER_ID, START_DATE ASC)
WHERE RN = 1 AND PLAN_NAME = 'churn'
;

--Number and % of Customer plans immediately after free trial

SELECT PLAN_NAME
    , COUNT(DISTINCT CUSTOMER_ID) N_CUSTOMERS_ON_PLAN
    , (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM FOODIE_FI_SUMMARY) N_TOTAL_CUSTOMERS
    , ROUND((N_CUSTOMERS_ON_PLAN / N_TOTAL_CUSTOMERS) *100, 1) PERCENTAGE
FROM (
    SELECT CUSTOMER_ID
        , MIN(START_DATE)
        , PLAN_NAME
        , ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY START_DATE ASC) AS RN
    FROM FOODIE_FI_SUMMARY
    WHERE PLAN_ID>0
    GROUP BY CUSTOMER_ID, START_DATE, PLAN_NAME
    ORDER BY CUSTOMER_ID, START_DATE ASC)
WHERE RN = 1 AND PLAN_NAME != 'churn' 
GROUP BY PLAN_NAME
;

--Breakdown of Number and % for all plans as of 2020-12-31

SELECT PLAN_NAME
    , COUNT(DISTINCT CUSTOMER_ID) N_CUSTOMERS_ON_PLAN
    , (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM FOODIE_FI_SUMMARY) N_TOTAL_CUSTOMERS
    , ROUND((N_CUSTOMERS_ON_PLAN / N_TOTAL_CUSTOMERS) *100, 1) PERCENTAGE
FROM (
    SELECT CUSTOMER_ID
        , MIN(START_DATE)
        , PLAN_NAME
        , ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY START_DATE DESC) AS RN --Took a moment to realise I needed to reverse the RN order for this question.
    FROM FOODIE_FI_SUMMARY
    WHERE START_DATE <= '2020-12-31'
    GROUP BY CUSTOMER_ID, START_DATE, PLAN_NAME
    ORDER BY CUSTOMER_ID, START_DATE ASC)
WHERE RN = 1
GROUP BY PLAN_NAME
;

--How many customers upgraded to annual plans in 2020 (195)

SELECT COUNT(DISTINCT CUSTOMER_ID)
FROM FOODIE_FI_SUMMARY
WHERE PLAN_ID = 3
    AND YEAR(START_DATE) = 2020;

--On avg. how many days do customers take to upgrade to annual plans (104)

SELECT ROUND(AVG(DAYS_TO_UPGRADE), 1)
FROM
    (SELECT CUSTOMER_ID
            , MIN(START_DATE) JOINED_DATE
            , MIN(CASE WHEN PLAN_ID = 3 THEN START_DATE END) UPGRADED
            , DATEDIFF('DAY', JOINED_DATE, UPGRADED) DAYS_TO_UPGRADE
        FROM FOODIE_FI_SUMMARY
        GROUP BY CUSTOMER_ID)
;

--Break this down into 30 day bins

SELECT (CASE 
        WHEN DAYS_TO_UPGRADE <= 30 THEN '0-30'
        WHEN DAYS_TO_UPGRADE >30 AND DAYS_TO_UPGRADE <= 60 THEN '0-60'
        WHEN DAYS_TO_UPGRADE >60 AND DAYS_TO_UPGRADE <= 90 THEN '61-90'
        WHEN DAYS_TO_UPGRADE >90 AND DAYS_TO_UPGRADE <= 120 THEN '91-120'
        WHEN DAYS_TO_UPGRADE >120 AND DAYS_TO_UPGRADE <= 150 THEN '121-150'
        WHEN DAYS_TO_UPGRADE >150 AND DAYS_TO_UPGRADE <= 180 THEN '151-180'
        WHEN DAYS_TO_UPGRADE >180 AND DAYS_TO_UPGRADE <= 210 THEN '181-210'
        WHEN DAYS_TO_UPGRADE >210 AND DAYS_TO_UPGRADE <= 240 THEN '211-240'
        WHEN DAYS_TO_UPGRADE >240 AND DAYS_TO_UPGRADE <= 270 THEN '241-270'
        WHEN DAYS_TO_UPGRADE >270 AND DAYS_TO_UPGRADE <= 300 THEN '271-300'
        WHEN DAYS_TO_UPGRADE >300 AND DAYS_TO_UPGRADE <= 330 THEN '301-330'
        WHEN DAYS_TO_UPGRADE >330 AND DAYS_TO_UPGRADE <= 360 THEN '331-360'
        WHEN DAYS_TO_UPGRADE >360 AND DAYS_TO_UPGRADE <= 390 THEN '361-390' 
        END )
        DAYS_BINS
        , COUNT(DISTINCT CUSTOMER_ID)
FROM ( 
    SELECT CUSTOMER_ID
        , MIN(START_DATE) JOINED_DATE
        , MIN(CASE WHEN PLAN_ID = 3 THEN START_DATE END) UPGRADED
        , DATEDIFF('DAY', JOINED_DATE, UPGRADED) DAYS_TO_UPGRADE
    FROM FOODIE_FI_SUMMARY
    GROUP BY CUSTOMER_ID
    )
GROUP BY DAYS_BINS
;

--Total customers downgrading from pro to basic monthly plans in 2020 (0)

SELECT COUNT(DISTINCT CUSTOMER_ID) TOTAL_CUSTOMERS_DOWNGRADING
FROM (
    SELECT CUSTOMER_ID
            , MIN(CASE WHEN PLAN_ID = 2 THEN START_DATE END) PRO_PLAN_START
            , MIN(CASE WHEN PLAN_ID = 1 THEN START_DATE END) BASIC_PLAN_START
            , (CASE WHEN BASIC_PLAN_START > PRO_PLAN_START THEN 1 ELSE 0 END) FLAG
        FROM FOODIE_FI_SUMMARY
        GROUP BY CUSTOMER_ID
    )
WHERE FLAG = 1
AND YEAR(BASIC_PLAN_START) = 2020
;