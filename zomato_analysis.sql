============================================================
-- ZOMATO SQL ANALYTICS
-- Customer, Product & Gold Membership Analysis
-- ============================================================


-- ============================================================
-- Q1. What is the total amount spent by each customer?
-- ============================================================

SELECT
    s.userid,
    SUM(p.price) AS total_expenditure
FROM sale AS s
JOIN product AS p
    ON s.product_id = p.product_id
GROUP BY s.userid
ORDER BY s.userid;


-- ============================================================
-- Q2. How many days has each customer visited Zomato?
-- ============================================================

SELECT
    userid,
    COUNT(DISTINCT created_date) AS days_visited
FROM sale
GROUP BY userid
ORDER BY userid;


-- ============================================================
-- Q3. What was the first product purchased by each customer
--     after signing up?
-- ============================================================

WITH ranked_purchases AS (
    SELECT
        s.userid,
        s.created_date,
        s.product_id,
        RANK() OVER (
            PARTITION BY s.userid
            ORDER BY s.created_date
        ) AS purchase_rank
    FROM sale AS s
    JOIN users AS u
        ON s.userid = u.userid
    WHERE s.created_date > u.signup_date
)

SELECT
    r.userid,
    r.created_date,
    p.product_name
FROM ranked_purchases AS r
JOIN product AS p
    ON r.product_id = p.product_id
WHERE r.purchase_rank = 1
ORDER BY r.userid;


-- ============================================================
-- Q4. What is the most purchased item on the menu and how
--     many times was it purchased by each customer?
-- ============================================================

WITH product_sales AS (
    SELECT
        product_id,
        COUNT(*) AS purchase_count
    FROM sale
    GROUP BY product_id
),
most_purchased AS (
    SELECT product_id
    FROM product_sales
    WHERE purchase_count = (
        SELECT MAX(purchase_count)
        FROM product_sales
    )
)

SELECT
    s.userid,
    s.product_id,
    COUNT(*) AS times_purchased
FROM sale AS s
JOIN most_purchased AS m
    ON s.product_id = m.product_id
GROUP BY
    s.userid,
    s.product_id
ORDER BY s.userid;


-- ============================================================
-- Q5. Which item is the favourite for each customer?
-- ============================================================

WITH customer_product_count AS (
    SELECT
        userid,
        product_id,
        COUNT(*) AS purchase_count
    FROM sale
    GROUP BY userid, product_id
),
ranked_products AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY userid
            ORDER BY purchase_count DESC
        ) AS product_rank
    FROM customer_product_count
)

SELECT
    userid,
    product_id,
    purchase_count
FROM ranked_products
WHERE product_rank = 1
ORDER BY userid;


-- ============================================================
-- Q6. Which item was first purchased by a customer after
--     becoming a Gold member?
-- ============================================================

WITH gold_purchases AS (
    SELECT
        s.userid,
        s.created_date,
        s.product_id,
        RANK() OVER (
            PARTITION BY s.userid
            ORDER BY s.created_date
        ) AS purchase_rank
    FROM sale AS s
    JOIN goldusers_signup AS g
        ON s.userid = g.userid
    WHERE s.created_date >= g.gold_signup_date
)

SELECT
    gp.userid,
    gp.created_date,
    p.product_name
FROM gold_purchases AS gp
JOIN product AS p
    ON gp.product_id = p.product_id
WHERE gp.purchase_rank = 1
ORDER BY gp.userid;


-- ============================================================
-- Q7. Which item was purchased immediately before becoming
--     a Gold member?
-- ============================================================

WITH pre_gold_purchases AS (
    SELECT
        s.userid,
        s.created_date,
        s.product_id,
        RANK() OVER (
            PARTITION BY s.userid
            ORDER BY s.created_date DESC
        ) AS purchase_rank
    FROM sale AS s
    JOIN goldusers_signup AS g
        ON s.userid = g.userid
    WHERE s.created_date < g.gold_signup_date
)

SELECT
    pg.userid,
    pg.created_date,
    p.product_name
FROM pre_gold_purchases AS pg
JOIN product AS p
    ON pg.product_id = p.product_id
WHERE pg.purchase_rank = 1
ORDER BY pg.userid;


-- ============================================================
-- Q8. What were the total transactions and amount spent by
--     each customer before becoming a Gold member?
-- ============================================================

SELECT
    s.userid,
    COUNT(*) AS total_transactions,
    SUM(p.price) AS total_food_expenditure
FROM sale AS s
JOIN goldusers_signup AS g
    ON s.userid = g.userid
JOIN product AS p
    ON s.product_id = p.product_id
WHERE s.created_date < g.gold_signup_date
GROUP BY s.userid
ORDER BY s.userid;


-- ============================================================
-- Q9. Calculate points collected by each customer and identify
--     the product generating the most points.
--
--     Zomato points rule used:
--     5 points for every Rs. 10 spent.
-- ============================================================

WITH customer_product_points AS (
    SELECT
        s.userid,
        s.product_id,
        SUM(p.price) AS total_spend,
        FLOOR(SUM(p.price) / 10) * 5 AS points_earned
    FROM sale AS s
    JOIN product AS p
        ON s.product_id = p.product_id
    GROUP BY
        s.userid,
        s.product_id
),
ranked_points AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY userid
            ORDER BY points_earned DESC
        ) AS point_rank
    FROM customer_product_points
)

SELECT
    userid,
    product_id,
    total_spend,
    points_earned
FROM ranked_points
WHERE point_rank = 1
ORDER BY userid;


-- ============================================================
-- Q10. During the first year after becoming a Gold member,
--      customers earn 5 points for every Rs. 10 spent.
--      Calculate the points earned by each customer.
-- ============================================================

SELECT
    s.userid,
    SUM(FLOOR(p.price / 10) * 5) AS first_year_points
FROM sale AS s
JOIN goldusers_signup AS g
    ON s.userid = g.userid
JOIN product AS p
    ON s.product_id = p.product_id
WHERE s.created_date >= g.gold_signup_date
  AND s.created_date <= DATE_ADD(
        g.gold_signup_date,
        INTERVAL 1 YEAR
      )
GROUP BY s.userid
ORDER BY first_year_points DESC;


-- ============================================================
-- Q11. Rank all transactions for each customer chronologically.
-- ============================================================

SELECT
    userid,
    created_date,
    product_id,
    RANK() OVER (
        PARTITION BY userid
        ORDER BY created_date
    ) AS transaction_rank
FROM sale
ORDER BY userid, created_date;