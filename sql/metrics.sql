/*This project analyzes a subscription-based digital product to understand churn, monetization, and 
engagement. Using SQL for data modeling and hypothesis testing, I find that revenue is driven by pricing 
tiers rather than user behavior, and engagement does not meaningfully predict churn or monetization.*/


SELECT COUNT(*) AS active_subscriptions
FROM sub_metrics.fct_subscriptions
WHERE start_date <= CURRENT_DATE
    AND (end_date IS NULL OR end_date >= CURRENT_DATE);
/*This query counts the number of active subscriptions by checking if the start date is on or before the current date and if the end 
date is either null (indicating an ongoing subscription) or on or after the current date. That suggests Student is both the biggest 
plan overall and currently.*/

SELECT
    subscription_type,
    COUNT (*) AS active_subscriptions
FROM sub_metrics.fct_subscriptions
WHERE start_date <= CURRENT_DATE
    AND (end_date IS NULL OR end_date >= CURRENT_DATE)
GROUP BY subscription_type
ORDER BY active_subscriptions DESC;
/*This query provides a breakdown of active subscriptions by subscription type. It groups the active subscriptions by their type and counts 
the number of active subscriptions for each type, ordering the results in descending order based on the count.*/

SELECT
    subscription_type,
    COUNT (*) AS total_subscriptions
FROM sub_metrics.fct_subscriptions
GROUP BY subscription_type
ORDER BY total_subscriptions DESC;
/*This query counts the total number of subscriptions for each subscription type, regardless of their active status. It groups the 
subscriptions by type and orders the results in descending order based on the total count.*/

SELECT
    COUNT(*) AS churned_subscriptions
FROM sub_metrics.fct_subscriptions
WHERE end_date IS NOT NULL
    AND end_date < CURRENT_DATE
GROUP BY subscription_type
ORDER BY churned_subscriptions DESC;
/*This query counts the number of churned subscriptions, defined as those with an end date that is not null and is before the current 
date. It groups the churned subscriptions by their type and orders the results in descending order based on the count of churned subscriptions.*/

SELECT
    subscription_type,
    ROUND(COUNT(*) FILTER (WHERE end_date IS NOT NULL AND end_date < CURRENT_DATE)::decimal / COUNT(*) * 100, 2) AS churn_rate
FROM sub_metrics.fct_subscriptions
GROUP BY subscription_type
ORDER BY churn_rate DESC;
/*This query calculates the churn rate for each subscription type. The churn rate is defined as the percentage of subscriptions that 
have ended (i.e., have a non-null end date that is before the current date) out of the total subscriptions for that type. The results 
are grouped by subscription type and ordered in descending order based on the churn rate. 

This is a time-sensitive churn rate, not a current health metric. Most subscriptions do eventually end.

No plan is dramatically stickier than the others and plan type alone does not explain churn, so churn is probably driven by something 
else like: tenure, engagement, pricing cycle, external factors.*/

SELECT
    subscription_type,
    ROUND(COUNT(*) FILTER (WHERE end_date IS NULL OR end_date >= CURRENT_DATE)::decimal / COUNT(*) * 100, 2) AS active_rate_percent,
    ROUND(COUNT(*) FILTER (WHERE end_date IS NOT NULL AND end_date < CURRENT_DATE)::decimal / COUNT(*) * 100, 2) AS churn_rate_percent
FROM sub_metrics.fct_subscriptions
GROUP BY subscription_type
ORDER BY subscription_type;
/*This query calculates both the active rate and churn rate percentages for each subscription type. The active rate is defined as the
percentage of subscriptions that are currently active (i.e., have a null end date or an end date on or after the current date), while
the churn rate is the percentage of subscriptions that have ended (i.e., have a non-null end date before the current date). 
The results are grouped by subscription type and ordered alphabetically by subscription type.

Active subscriptions are a small slice of the whole. Across all plans, only ~1–2% of subscriptions are active right now.
That confirms the historical nature of the churn rate above: it spans a long time horizon and “current health” is not what this metric 
is designed to show

Plan type does not explain lifecycle differences. Active rate and churn rate are extremely similar across plans and within a few tenths 
of a percent, so the conclusion is: Subscription type alone is not a strong driver of churn in this dataset and time based-questions 
are imposed to further the analysis.*/

SELECT
    CASE
        WHEN end_date - start_date <= 30 THEN '0-30 days'
        WHEN end_date - start_date <= 90 THEN '31-90 days'
        WHEN end_date - start_date <= 180 THEN '91-180 days'
        WHEN end_date - start_date <= 365 THEN '181-365 days'
        ELSE '366+ days'
    END AS tenure_bucket,
    COUNT(*) AS churned_subscriptions
FROM sub_metrics.fct_subscriptions
WHERE end_date IS NOT NULL
    AND end_date < CURRENT_DATE
GROUP BY tenure_bucket
ORDER BY MIN(end_date - start_date);
/*This query categorizes churned subscriptions into tenure buckets based on the duration between their start and end dates. It counts 
the number of churned subscriptions in each tenure bucket, grouping the results accordingly and ordering them by the minimum duration 
within each bucket to show the distribution of churned subscriptions across different tenure periods.

Churn is evenly distributed across all buckets, which suggests that tenure alone does not explain churn differences.
This points us to subscriptions that probably have a fixed or semi-fixed duration like for example monthly renewals, semester plans, or 
annual plans 

Early experience is not the main churn driver. Which suggests that the product experience is acceptable and churn is driven by 
time-based decisions, not dissatisfaction.

This is a lifecycle-complete dataset where churn is expected, so these results are not surprising.*/

SELECT
    subscription_type,
    CASE
        WHEN end_date - start_date <= 30 THEN '0-30 days'
        WHEN end_date - start_date <= 90 THEN '31-90 days'
        WHEN end_date - start_date <= 180 THEN '91-180 days'
        WHEN end_date - start_date <= 365 THEN '181-365 days'
        ELSE '366+ days'
    END AS tenure_bucket,
    COUNT(*) AS churned_subscriptions
FROM sub_metrics.fct_subscriptions
WHERE end_date IS NOT NULL
    AND end_date < CURRENT_DATE
GROUP BY subscription_type, tenure_bucket
ORDER BY 
    subscription_type,
    MIN(end_date - start_date);

/* This query extends the previous analysis by breaking down churned subscriptions into tenure buckets for each subscription type.
Within each plan, churn is evenly distributed across the first year, not concentrated at onboarding, not delayed to a single “dip”, 
which confirms the earlier finding.

Plan type does not meaningfully change churn behavior even when split by plan. The shape of churn over time is nearly identical and
differences are mostly scale (Student has more volume), so the earlier conclusion still stands true, plan type is not the driver of 
churn timing.

This is a renewal-driven churn system, and the data is very consistent with subscriptions ending at planned renewal points, churn 
being a normal lifecycle outcome and not an experience-driven failure.*/

SELECT
    SUM(amount) AS total_revenue
FROM sub_metrics.fct_payments;
/*This query calculates the total revenue generated from all payments by summing up the amount column in the fct_payments table.*/

SELECT
    s.subscription_type,
    SUM(p.amount) AS revenue
FROM sub_metrics.fct_payments p
JOIN sub_metrics.fct_subscriptions s
    ON s.subscription_id = p.subscription_id
GROUP BY s.subscription_type
ORDER BY revenue DESC;
/*This query calculates the total revenue generated from payments for each subscription type. It joins the fct_payments table with the
fct_subscriptions table on the subscription_id column, groups the results by subscription type, and sums the amount for each type, 
ordering the results in descending order based on revenue.

Family generates the most revenue even though student has more subscriptions historically. Family likely costs more per payment or has 
more recurring payments per subscription.

So highest volume does not mean highest revenue in this case. Student dominates in count, not value.

Student has the largest user base but the lowest revenue contribution. That’s very typical since student plans are discounted and used 
for acquisition, not monetization.

Premium underperforms Family. Premium has lower revenue than Family and similar revenue to Student despite likely higher price which 
indicates fewer Premium users or shorter lifetimes*/

SELECT
    s.subscription_type,
    ROUND(SUM(p.amount), 2) AS revenue,
    COUNT(DISTINCT s.subscription_id) AS subscriptions,
    ROUND(SUM(p.amount) / NULLIF(COUNT(DISTINCT s.subscription_id), 0) , 2) AS avg_revenue_per_subscription
FROM sub_metrics.fct_payments p
JOIN sub_metrics.fct_subscriptions s
    ON s.subscription_id = p.subscription_id
GROUP BY s.subscription_type
ORDER BY revenue DESC;
/*This query calculates the total revenue, number of unique subscriptions, and average revenue per subscription for each subscription type. 
It joins the fct_payments table with the fct_subscriptions table on the subscription_id column, groups the results by subscription type, and 
computes the required metrics, ordering the results in descending order based on total revenue.

Revenue per subscription aligns exactly with plan pricing, suggesting single-payment subscriptions. The monetization differences are driven by 
pricing tiers rather than retention or repeated billing.*/

SELECT
    s.subscription_type,
    ROUND(SUM(p.amount), 2) AS revenue,
    ROUND(SUM(p.amount) / SUM(SUM(p.amount)) OVER() * 100, 2) AS revenue_share_percent
FROM sub_metrics.fct_payments p
JOIN sub_metrics.fct_subscriptions s
    ON s.subscription_id = p.subscription_id
GROUP BY s.subscription_type
ORDER BY revenue DESC;
/*This query calculates the total revenue and revenue share percentage for each subscription type. It joins the fct_payments table with 
the fct_subscriptions table on the subscription_id column, groups the results by subscription type, and computes the required metrics, 
ordering the results in descending order based on total revenue.

Family generates a disproportionate share of revenue relative to its subscription count, indicating higher pricing or more frequent
billing. Student, while having the highest subscription count, contributes a smaller revenue share, reflecting its discounted pricing. 
Premium's revenue share is lower than Family's despite its likely higher price point, suggesting fewer users or shorter subscription 
durations.*/

SELECT
    COUNT(DISTINCT subscription_id) AS unique_subscriptions,
    ROUND(SUM(amount), 2) AS total_revenue
FROM sub_metrics.fct_payments;
/*This query calculates the total number of unique subscriptions and the total revenue generated from all payments by counting distinct
subscription IDs and summing up the amount column in the fct_payments table.

Almost every subscription pays exactly once. Number of payments ≈ number of subscriptions so, total revenue ≈ price × subscriptions which 
confirms that there are no “whales" or "heavy spenders”, no repeat billing and no upsells, each subscription generates one payment.

Revenue is not concentrated in a small elite of users. Revenue is spread almost uniformly with pricing tier determining value and not 
behavior which matches everything so far.

This is a simple, single-payment subscription model without complex monetization dynamics.*/

SELECT
    subscription_id,
    ROUND(SUM(amount), 2) AS subscription_revenue
FROM sub_metrics.fct_payments
GROUP BY subscription_id
ORDER BY subscription_revenue DESC
LIMIT 10;
/*This query identifies the top 10 subscriptions that have generated the highest revenue. It groups the payments by subscription_id, 
sums the amount for each subscription, and orders the results in descending order based on the total revenue generated by each subscription.

This confirms the previous finding: No subscriptions generate significantly more revenue than others.

Conclusion: Revenue is evenly distributed at the subscription level, with no high-spending outliers. Monetization differences are entirely 
explained by fixed pricing tiers, with Family plans contributing the largest share of total revenue (~43%).*/

SELECT *
FROM sub_metrics.engagement_per_user
ORDER BY total_listens DESC
LIMIT 10;

SELECT
  MIN(total_listens) AS min_listens,
  MAX(total_listens) AS max_listens,
  AVG(total_listens)::numeric(12,2) AS avg_listens
FROM sub_metrics.engagement_per_user;
/*This query calculates the minimum, maximum, and average number of listening events per user from the 
engagement_per_user view. The average is cast to a numeric type with two decimal places for better 
readability.

Engagement is very light overall. Most users interact with the product minimally.
There are no extreme outliers, engagement is tightly bounded which matches the monetization model of
one payment per subscription.

High churn, light engagement indicates internal consistency with everything analysed so far.*/

SELECT
    s.subscription_type,
    COUNT(DISTINCT e.user_id) AS users_with_listens,
    ROUND(AVG(e.total_listens), 2) AS avg_listens_per_user,
    MAX(e.total_listens) AS max_listens
FROM sub_metrics.engagement_per_user e
JOIN sub_metrics.dim_users u
    ON e.user_id = u.user_id
JOIN sub_metrics.fct_subscriptions s
    ON s.user_id = u.user_id
GROUP BY s.subscription_type
ORDER BY avg_listens_per_user DESC;
/*This query analyzes user engagement by subscription type. It joins the engagement_per_user view with the
dim_users and fct_subscriptions tables to associate user engagement data with their subscription types. 
It then counts the number of users with listening events, calculates the average number of listens per user, 
and finds the maximum listens for each subscription type. The results are grouped by subscription type 
and ordered by average listens per user in descending order.

Engagement is very similar across plans, which means that paying more does not lead to meaningfully 
higher engagement.

Premium is not the most engaged group. Premium pricing is not driven by usage and may be about perceived 
value or access, not consumption.

Engagement is capped by product design, not plan.

Student has the widest engagement spread and highest number of engaged users.

Earlier we found that "Family" generates most revenue, "Premium"  generates less revenue than "Family", and
"Student" generates similar revenue to "Premium".

Now we see that engagement does not explain revenue differences therefore revenue is driven by pricing 
tiers and not user behavior.

In conclusion: Higher-priced plans do not correspond to higher engagement, suggesting monetization is 
decoupled from usage. Revenue is driven by pricing structure rather than behavioral intensity, likely 
reflecting product constraints rather than user preference.*/

SELECT
    CASE
        WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE 
            THEN 'Active'
        ELSE 'Churned'
    END AS subscription_status,
    COUNT(DISTINCT e.user_id) AS users,
    ROUND(AVG(e.total_listens), 2) AS avg_listens,
    MAX(e.total_listens) AS max_listens
FROM sub_metrics.engagement_per_user e
JOIN sub_metrics.fct_subscriptions s
    ON e.user_id = s.user_id
GROUP BY subscription_status
/*This query compares user engagement between active and churned subscriptions. It joins the 
engagement_per_user view with the fct_subscriptions table to determine the subscription status of each user. 
It then counts the number of users, calculates the average number of listens per user, and finds the 
maximum listens for both active and churned subscriptions. The results are grouped by subscription status.

Engagement does not protect against churn because the averages are essentially identical.
That means that users who churned were not less engaged than users who stayed. So in this dataset engagement 
is not a predictor of retention and churn is independent of listening behavior.

Churned users include the most engaged users, so even the most engaged users can churn. This strongly 
suggests that churn is driven by external or structural factors, not by dissatisfaction due to lack of 
usage.

Engagement is uniformly low and capped which reinforces earlier conclusions that engagement range is narrow 
and product usage is constrained.

There is no behavioral gradient to exploit for retention strategies since engagement is similar across
all users regardless of churn status.

Listening engagement is low and tightly bounded across all users. Engagement does not differ meaningfully 
by subscription type and shows no relationship with churn or revenue. Monetization and retention appear 
decoupled from user behavior in this dataset.
*/

/*With payment timestamps and recurring billing data, this analysis could be extended to MRR, cohort-based 
retention, and lifetime value modeling. However, given the single-payment subscription model observed, these
metrics may offer limited additional insights beyond the current findings. The existing analysis sufficiently
captures the key dynamics of churn, monetization, and engagement for this product.*/ 

