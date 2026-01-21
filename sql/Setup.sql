CREATE SCHEMA IF NOT EXISTS sub_metrics;
SET search_path = sub_metrics, public;
/*The above commands create a new schema named sub_metrics if it does not already exist and set the search path to prioritize this schema for subsequent operations.*/

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'sub_metrics';
/*This query checks if the sub_metrics schema exists by querying the information_schema.schemata table. If the schema exists, it will return its name.*/

CREATE TABLE sub_metrics.users_raw (
    row_id TEXT,
    user_id INT,
    username TEXT,
    email TEXT,
    password_hash TEXT,
    first_name TEXT,
    last_name TEXT,
    subscription_type TEXT,
    created_at TEXT
)
/*This command creates a table named users_raw within the sub_metrics schema. The table is designed to store raw user data with various fields such as user_id, 
username, email, subscription_type, and created_at. Each field is defined with an appropriate data type.*/

DROP TABLE IF EXISTS public.users_raw;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'users_raw';

COPY sub_metrics.users_raw 
FROM 'C:/Users/Pedro/Desktop/Data Analysis Project 4/Dataset/users.csv'
WITH (FORMAT csv, HEADER true);

TRUNCATE TABLE sub_metrics.users_raw;

DROP TABLE IF EXISTS sub_metrics.users_raw;

CREATE TABLE sub_metrics.users_raw (
  row_id            TEXT,
  user_id           TEXT,
  username          TEXT,
  email             TEXT,
  password_hash     TEXT,
  first_name        TEXT,
  last_name         TEXT,
  subscription_type TEXT,
  created_at        TEXT
);
/*This command recreates the users_raw table within the sub_metrics schema, defining all columns as TEXT data types. This approach allows for initial data loading without type constraints,
facilitating subsequent data cleaning and transformation.*/

SELECT *
FROM sub_metrics.users_raw
LIMIT 3;

DELETE FROM sub_metrics.users_raw
WHERE user_id = 'user_id';
/*This command deletes any rows in the users_raw table where the user_id is equal to the string 'user_id', which is likely a header row mistakenly included in the data.*/

SELECT COUNT(*) 
FROM sub_metrics.users_raw;

SELECT COUNT(*) AS users_rows
FROM sub_metrics.users_raw;

SELECT user_id
FROM sub_metrics.users_raw
WHERE user_id !~ '^[0-9]+$'
LIMIT 20;
/*Sanity checks*/

CREATE OR REPLACE VIEW sub_metrics.dim_users AS
SELECT
  row_id,
  user_id::int AS user_id,
  username,
  email,
  first_name,
  last_name,
  subscription_type,
  created_at
FROM sub_metrics.users_raw;
/*This command creates a view named dim_users within the sub_metrics schema. The view transforms the user_id column from TEXT to INT, while retaining other columns as they are. 
This allows for easier querying and analysis of user data with the correct data type for user_id.*/

SELECT COUNT(*) FROM sub_metrics.dim_users;

SELECT * FROM sub_metrics.dim_users LIMIT 5;

DROP TABLE IF EXISTS sub_metrics.subscriptions_raw;
CREATE TABLE sub_metrics.subscriptions_raw (
  row_id TEXT,
  subscription_id TEXT,
  user_id TEXT,
  subscription_type TEXT,
  start_date TEXT,
  end_date TEXT,
  created_at TEXT
);
/*This command creates a table named subscriptions_raw within the sub_metrics schema. The table is designed to store raw subscription data with various fields such as subscription_id,
user_id, subscription_type, start_date, end_date, and created_at. Each field is defined with a TEXT data type to facilitate initial data loading without type constraints.*/

SELECT *
FROM sub_metrics.subscriptions_raw
LIMIT 3;
/*Sanity checks*/

DELETE FROM sub_metrics.subscriptions_raw
WHERE subscription_id = 'subscription_id';
/*This command deletes any rows in the subscriptions_raw table where the subscription_id is equal to the string 'subscription_id', which is likely a header row mistakenly included in the data.*/

SELECT COUNT(*) AS subscriptions_rows
FROM sub_metrics.subscriptions_raw;

CREATE OR REPLACE VIEW sub_metrics.fct_subscriptions AS
SELECT
  row_id,
  subscription_id::int AS subscription_id,
  user_id::int AS user_id,
  subscription_type,
  TO_DATE(start_date, 'DD-MM-YYYY') AS start_date,
  CASE 
    WHEN end_date = 'NULL' THEN NULL
    ELSE TO_DATE(end_date, 'DD-MM-YYYY')
  END AS end_date,
  created_at
FROM sub_metrics.subscriptions_raw;
/*This command creates a view named fct_subscriptions within the sub_metrics schema. The view transforms the subscription_id and user_id columns from TEXT to INT,
and converts the start_date and end_date columns from TEXT to DATE format. The end_date is set to NULL if it contains the string 'NULL'. This allows for easier querying and analysis of subscription data with the correct data types.*/

SELECT COUNT(*) 
FROM sub_metrics.fct_subscriptions;

SELECT *
FROM sub_metrics.fct_subscriptions
LIMIT 5;

SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'sub_metrics'
  AND table_name = 'fct_subscriptions';
/*Sanity checks*/

DROP TABLE IF EXISTS sub_metrics.payments_raw;
CREATE TABLE sub_metrics.payments_raw (
  row_id TEXT,
  payment_id TEXT,
  user_id TEXT,
  amount TEXT,
  payment_date TEXT,
  payment_method TEXT,
  created_at TEXT,
  subscription_id TEXT
);
/*This command creates a table named payments_raw within the sub_metrics schema. The table is designed to store raw payment data with various fields such as payment_id, user_id,
amount, payment_date, payment_method, created_at, and subscription_id. Each field is defined with a TEXT data type to facilitate initial data loading without type constraints.*/

SELECT *
FROM sub_metrics.payments_raw
LIMIT 3;

DELETE FROM sub_metrics.payments_raw
WHERE payment_id = 'payment_id';
/*This command deletes any rows in the payments_raw table where the payment_id is equal to the string 'payment_id', which is likely a header row mistakenly included in the data.*/

SELECT COUNT(*) AS payment_rows
FROM sub_metrics.payments_raw;

SELECT 
  MIN(amount) AS min_amount,
  MAX(amount) AS max_amount
FROM sub_metrics.payments_raw;

SELECT
  amount,
  COUNT(*) AS cnt
FROM sub_metrics.payments_raw
GROUP BY amount
ORDER BY cnt DESC
LIMIT 15;

SELECT
  MIN(amount::int) AS min_amount_int,
  MAX(amount::int) AS max_amount_int
FROM sub_metrics.payments_raw;

SELECT
  amount::int AS amount_int,
  COUNT(*) AS cnt
FROM sub_metrics.payments_raw
GROUP BY amount::int
ORDER BY cnt DESC
LIMIT 15;
/*Sanity checks*/

CREATE OR REPLACE VIEW sub_metrics.fct_payments AS
SELECT
  row_id,
  payment_id::int AS payment_id,
  user_id::int AS user_id,
  subscription_id::int AS subscription_id,
  amount::int AS amount_cents,
  (amount::int / 100.0)::numeric(12,2) AS amount,
  TO_DATE(payment_date, 'DD-MM-YYYY') AS payment_date,
  payment_method,
  created_at
FROM sub_metrics.payments_raw;
/*This command creates a view named fct_payments within the sub_metrics schema. The view transforms the payment_id, user_id, and subscription_id columns from TEXT to INT,
converts the amount column from TEXT to INT (representing cents), and creates a new amount column in dollars as a numeric type. The payment_date column is converted from 
TEXT to DATE format. This allows for easier querying and analysis of payment data with the correct data types.*/

SELECT COUNT(*)
FROM sub_metrics.fct_payments;

SELECT
  payment_id,
  amount_cents,
  amount,
  payment_date
FROM sub_metrics.fct_payments
LIMIT 10;
/*Sanity checks*/

SELECT *
FROM sub_metrics.fct_payments
WHERE payment_date = '33:25.6'
  OR created_at = '33:25.6'
LIMIT 5;

CREATE OR REPLACE VIEW sub_metrics.fct_payments AS
SELECT
  row_id,
  payment_id::int AS payment_id,
  user_id::int AS user_id,
  subscription_id::int AS subscription_id,
  amount::int AS amount_cents,
  (amount::int / 100.0)::numeric(12,2) AS amount,
  CASE
    WHEN payment_date ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
      THEN TO_DATE(payment_date, 'DD-MM-YYYY')
    ELSE NULL
  END AS payment_date,
  payment_method,
  created_at
FROM sub_metrics.payments_raw;

SELECT COUNT(*) FROM sub_metrics.fct_payments;

SELECT payment_id, amount, payment_date
FROM sub_metrics.fct_payments
LIMIT 10;

SELECT created_at
FROM sub_metrics.payments_raw
LIMIT 20;

SELECT COUNT(*) AS looks_like_date
FROM sub_metrics.payments_raw
WHERE created_at ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}';

/*In payments.csv payment_date looks like 33:25.6, 24:52.6, etc. In subscriptions.csv created_at looks very similar. 
For at least one user_id I saw payments.payment_date ≈ subscriptions.created_at

That is not a coincidence. What this likely means is that those fields are not dates at all. They are 
almost certainly durations / offsets / synthetic timestamps (e.g. “minutes:seconds.milliseconds since 
session start”, or “time since some reference event”).

This dataset is synthetic, and whoever generated it likely reused the same timing signal across tables 
to simulate “event ordering”, not real calendar time.*/

DROP TABLE IF EXISTS sub_metrics.listening_raw;

CREATE TABLE sub_metrics.listening_raw (
  row_id TEXT,
  history_id TEXT,
  user_id TEXT,
  song_id TEXT,
  listen_date TEXT,
  created_at TEXT
);
/*This command creates a table named listening_raw within the sub_metrics schema. The table is designed 
to store raw listening history data with various fields such as history_id, user_id, song_id, listen_date, 
and created_at. Each field is defined with a TEXT data type to facilitate initial data loading without 
type constraints.*/

SELECT *
FROM sub_metrics.listening_raw
LIMIT 3;

DELETE FROM sub_metrics.listening_raw
WHERE history_id = 'history_id';

SELECT COUNT(*) AS listening_events
FROM sub_metrics.listening_raw;

CREATE OR REPLACE VIEW sub_metrics.engagement_per_user AS
SELECT
  user_id::int AS user_id,
  COUNT(*) AS total_listens
FROM sub_metrics.listening_raw
GROUP BY user_id;
/*This command creates a view named engagement_per_user within the sub_metrics schema. The view aggregates
the listening history data by user_id, counting the total number of listening events for each user. 
The user_id column is transformed from TEXT to INT. This allows for easier querying and analysis of user 
engagement based GROUP BY on listening history.*/


/* Creating views for BI-ready exports */

CREATE OR REPLACE VIEW sub_metrics.bi_subscriptions AS
SELECT
  s.subscription_id,
  s.user_id,
  s.subscription_type,
  s.start_date,
  s.end_date,
/* Active and churned status based on current date */
  (s.start_date <= CURRENT_DATE AND (s.end_date IS NULL OR s.end_date >= CURRENT_DATE)) AS is_active,
  (s.end_date IS NOT NULL AND s.end_date < CURRENT_DATE) AS is_churned,
/* Tenure calculation in days */
  CASE
    WHEN s.start_date IS NULL THEN NULL
    WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN (CURRENT_DATE - start_date)
    ELSE (s.end_date - start_date)
    END AS tenure_days,
/* Tenure buckets */
/* 30 days or less from current time or end date*/
  CASE
    WHEN s.start_date IS NULL THEN NULL
    WHEN (CASE
      WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN (CURRENT_DATE - start_date)
      ELSE (s.end_date - s.start_date)
    END) <= 30 THEN '0-30 days'
/* 31 to 90 days from current time or end date*/
    WHEN (CASE
      WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN (CURRENT_DATE - start_date)
      ELSE (s.end_date - start_date)
    END) <= 90 THEN '31-90 days'
/* 91 to 180 days from current time or end date*/
    WHEN (CASE
      WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN (CURRENT_DATE - start_date)
      ELSE (s.end_date - start_date)
    END) <= 180 THEN '91-180 days'
/* 180 to 365 days from current time or end date*/
    WHEN (CASE
      WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN (CURRENT_DATE - start_date)
      ELSE (s.end_date - s.start_date)
    END) <= 365 THEN '181-365 days'
/* More than 365 days from current time or end date*/
    ELSE '365+ days'
  END AS tenure_bucket
FROM sub_metrics.fct_subscriptions s;
/*This command creates a view named bi_subscriptions within the sub_metrics schema. The view enhances the
fct_subscriptions data by adding calculated fields for active and churned status based on the current date,
tenure in days, and tenure buckets. This allows for easier business intelligence analysis of subscription data.*/


CREATE OR REPLACE VIEW sub_metrics.bi_payments AS
SELECT
  p.payment_id,
  p.subscription_id,
  p.user_id,
  s.subscription_type,
  p.amount_cents,
  p.amount,
  p.payment_method,
/* Since the payment time and created time are not real calendar dates, we will not do date-based analysis on them. */
  p.payment_date AS payment_time_raw,
  p.created_at AS created_time_raw
FROM sub_metrics.fct_payments p
JOIN sub_metrics.fct_subscriptions s
  ON s.subscription_id = p.subscription_id;
/*This command creates a view named bi_payments within the sub_metrics schema. The view combines data from
the fct_payments and fct_subscriptions views, retaining relevant fields for payment analysis. The payment_date and created_at fields
are kept as payment_time_raw and created_time_raw to indicate that they are not real calendar dates. This allows for easier 
business intelligence analysis of payment data.*/


CREATE OR REPLACE VIEW sub_metrics.bi_engagement AS
SELECT
  user_id,
  total_listens
FROM sub_metrics.engagement_per_user;
/*This command creates a view named bi_engagement within the sub_metrics schema. The view selects relevant fields
from the engagement_per_user view, focusing on user_id and total_listens. This allows for easier business 
intelligence analysis of user engagement data.*/

CREATE OR REPLACE VIEW sub_metrics.bi_churn_tenure AS
SELECT
  tenure_bucket,
  COUNT(*) AS total_subscriptions,
  COUNT(*) FILTER (WHERE is_churned) AS churned_subscriptions,
  ROUND(COUNT(*) FILTER (WHERE is_churned)::numeric / NULLIF(COUNT(*), 0) * 100, 2) AS churn_rate_percent
FROM sub_metrics.bi_subscriptions
WHERE tenure_bucket IS NOT NULL
GROUP BY tenure_bucket
ORDER BY MIN(tenure_days);
/*This command creates a view named bi_churn_tenure within the sub_metrics schema. The view aggregates subscription data by 
tenure_bucket, calculating the total number of subscriptions, the number of churned subscriptions, and the churn rate percentage 
for each tenure bucket. This allows for easier business intelligence analysis of churn rates based on subscription tenure.*/


/*Validation of views*/
SELECT COUNT(*)
FROM sub_metrics.bi_subscriptions;

SELECT COUNT(*)
FROM sub_metrics.bi_payments;

SELECT COUNT(*)
FROM sub_metrics.bi_engagement;

SELECT *
FROM sub_metrics.bi_churn_tenure;