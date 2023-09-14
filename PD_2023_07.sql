--bring in the 4 tables, making some changes to shape and filtering as needed
WITH transaction_path AS
    (SELECT *
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK07_TRANSACTION_PATH)
, transaction_detail AS
    (SELECT * FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK07_TRANSACTION_DETAIL)
, account_info AS 
    (SELECT ACCOUNT_NUMBER
        , ACCOUNT_TYPE
        , BALANCE_DATE
        , BALANCE
        , INDEX AS JOINT_ACCOUNT_MEMBER
        , VALUE AS NEW_ACCOUNT_HOLDER_ID FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK07_ACCOUNT_INFORMATION, LATERAL SPLIT_TO_TABLE(ACCOUNT_HOLDER_ID, ', ')
    WHERE NEW_ACCOUNT_HOLDER_ID IS NOT NULL
    )
, account_holders AS
    (SELECT *, '0' || CONTACT_NUMBER FULL_CONTACT_NUMBER
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK07_ACCOUNT_HOLDERS
    WHERE FULL_CONTACT_NUMBER LIKE '07%'
    AND ACCOUNT_HOLDER_ID IS NOT NULL)

--combine 4 tables together, and filter to only possible fraudulent transactions
--initial mistake was to join the account info table on 'ACCOUNT_TO' instead of 'ACCOUNT_FROM'
SELECT transaction_path.TRANSACTION_ID --this is where I was previously getting errors for field name ambiguity: had to specify which table the field should come from
    , ACCOUNT_TO
    , TRANSACTION_DATE
    , VALUE
    , ACCOUNT_NUMBER
    , ACCOUNT_TYPE
    , BALANCE_DATE
    , BALANCE
    , NAME
    , DATE_OF_BIRTH
    , FULL_CONTACT_NUMBER
    , FIRST_LINE_OF_ADDRESS
FROM transaction_path
JOIN transaction_detail ON transaction_path.TRANSACTION_ID = transaction_detail.TRANSACTION_ID
JOIN account_info ON transaction_path.ACCOUNT_FROM = account_info.ACCOUNT_NUMBER
JOIN account_holders ON account_info.NEW_ACCOUNT_HOLDER_ID = account_holders.ACCOUNT_HOLDER_ID
WHERE CANCELLED_ = 'N'
    AND ACCOUNT_TYPE != 'Platinum'
    AND VALUE > 1000;